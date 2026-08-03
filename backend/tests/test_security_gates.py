"""Regression tests for the P0 security fixes:

- MUNSHI_DEMO=0 actually disables /api/auth/demo, the login demo shortcut,
  the DEMO_TOKEN bearer path, and the demo refresh shortcut.
- /api/dev/purge-auth-users requires a valid X-Admin-Token, in addition to
  MUNSHI_DEMO=1.
- The Stripe webhook fails closed (503) rather than accepting unsigned
  payloads when STRIPE_WEBHOOK_SECRET is not configured.
- DRT lookup honestly distinguishes "could not verify" from "checked, not
  on the cause list" (invariant 4 — never silently convert a failed source
  into a false negative).
"""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.config import get_settings
from app.deps import current_user as current_user_dep
from app.main import app
from app.services import court_lookup

client = TestClient(app)


@pytest.fixture
def env(monkeypatch):
    """Set/clear env vars for one test and always rebuild the cached Settings."""

    def _set(**kw):
        for k, v in kw.items():
            if v is None:
                monkeypatch.delenv(k, raising=False)
            else:
                monkeypatch.setenv(k, v)
        get_settings.cache_clear()

    get_settings.cache_clear()
    yield _set
    get_settings.cache_clear()


# ---------------------------------------------------------------------------
# Demo gate — MUNSHI_DEMO=0 must actually disable every demo path
# ---------------------------------------------------------------------------

def test_demo_still_works_by_default(env):
    env(MUNSHI_DEMO="1")
    r = client.post("/api/auth/demo", json={})
    assert r.status_code == 200
    assert r.json()["token"] == "demo-local-vault"


def test_demo_auth_disabled_when_munshi_demo_off(env):
    env(MUNSHI_DEMO="0")
    r = client.post("/api/auth/demo", json={})
    assert r.status_code == 403


def test_demo_login_shortcut_disabled_when_munshi_demo_off(env, monkeypatch):
    env(MUNSHI_DEMO="0")

    def _boom():
        raise RuntimeError("no network in test")

    monkeypatch.setattr("app.routers.auth.supabase_client", _boom)
    r = client.post(
        "/api/login",
        json={"email": "demo@localhost", "password": "demo-password-change-me"},
    )
    # If the shortcut had fired we'd get 200 with a demo session; instead control
    # falls through to the (deliberately broken) real Supabase path.
    assert r.status_code == 503


def test_demo_token_rejected_when_munshi_demo_off(env, monkeypatch):
    env(MUNSHI_DEMO="0")

    # Simulate total auth-backend failure on *both* the local-verification
    # and remote-fallback paths (see deps.py's current_user) — the demo
    # token must still fail closed rather than falling through to anything
    # that grants access.
    class _FakeAuth:
        def get_claims(self, token):
            raise RuntimeError("no network in test")

        def get_user(self, token):
            raise RuntimeError("no network in test")

    class _FakeClient:
        auth = _FakeAuth()

    monkeypatch.setattr("app.deps.auth_verification_client", lambda: _FakeClient())
    r = client.get("/api/me", headers={"Authorization": "Bearer demo-local-vault"})
    assert r.status_code == 401


def test_demo_refresh_disabled_when_munshi_demo_off(env, monkeypatch):
    env(MUNSHI_DEMO="0")

    class _FakeAuth:
        def refresh_session(self, token):
            raise RuntimeError("no network in test")

    class _FakeClient:
        auth = _FakeAuth()

    monkeypatch.setattr("app.routers.auth.supabase_client", lambda *a, **kw: _FakeClient())
    r = client.post("/api/auth/refresh", json={"refresh_token": "demo-local-vault"})
    assert r.status_code == 401


# ---------------------------------------------------------------------------
# /api/dev/purge-auth-users — admin-token dependency
# ---------------------------------------------------------------------------

def test_purge_blocked_when_demo_closed_even_with_correct_token(env):
    env(MUNSHI_DEMO="0", MUNSHI_ADMIN_TOKEN="secret123")
    r = client.post("/api/dev/purge-auth-users", headers={"X-Admin-Token": "secret123"})
    assert r.status_code == 403


def test_purge_requires_admin_token_configured(env):
    env(MUNSHI_DEMO="1", MUNSHI_ADMIN_TOKEN=None)
    r = client.post("/api/dev/purge-auth-users")
    assert r.status_code == 503


def test_purge_rejects_missing_token(env):
    env(MUNSHI_DEMO="1", MUNSHI_ADMIN_TOKEN="secret123")
    r = client.post("/api/dev/purge-auth-users")
    assert r.status_code == 401


def test_purge_rejects_wrong_token(env):
    env(MUNSHI_DEMO="1", MUNSHI_ADMIN_TOKEN="secret123")
    r = client.post("/api/dev/purge-auth-users", headers={"X-Admin-Token": "wrong"})
    assert r.status_code == 401


def test_purge_accepts_correct_token_then_fails_on_next_precondition(env):
    env(MUNSHI_DEMO="1", MUNSHI_ADMIN_TOKEN="secret123", SUPABASE_SERVICE_ROLE_KEY=None)
    r = client.post("/api/dev/purge-auth-users", headers={"X-Admin-Token": "secret123"})
    # Auth dependency is satisfied — the 503 below comes from the *next* check
    # (no service-role key), proving the token itself was accepted.
    assert r.status_code == 503
    assert "SERVICE_ROLE_KEY" in r.json()["detail"]


# ---------------------------------------------------------------------------
# Stripe webhook — fail closed without a configured signing secret
# ---------------------------------------------------------------------------

def test_stripe_webhook_fails_closed_without_secret(env):
    env(STRIPE_WEBHOOK_SECRET=None)
    r = client.post(
        "/api/stripe/webhook",
        json={"type": "customer.subscription.updated", "data": {"object": {}}},
    )
    assert r.status_code == 503


# ---------------------------------------------------------------------------
# DRT lookup honesty — "could not verify" vs "not on cause list"
# ---------------------------------------------------------------------------

def test_drt_lookup_reports_could_not_verify_when_every_fetch_fails(monkeypatch):
    def _boom(city_key, iso):
        raise RuntimeError("network unreachable")

    monkeypatch.setattr(court_lookup, "drt_fetch_causelist", _boom)
    result = court_lookup.lookup_case_in_drt(
        "Dehradun", "ST 88/2023", ["2026-08-01", "2026-08-02"]
    )
    assert result["found"] is False
    assert result["verified"] is False
    assert "could not verify" in result["reason"]


def test_drt_lookup_reports_genuinely_not_listed(monkeypatch):
    def _empty(city_key, iso):
        return b"{}", []

    monkeypatch.setattr(court_lookup, "drt_fetch_causelist", _empty)
    result = court_lookup.lookup_case_in_drt("Dehradun", "ST 88/2023", ["2026-08-01"])
    assert result["found"] is False
    assert result["verified"] is True
    assert result["reason"] == "not on cause list for checked dates"


def test_drt_lookup_partial_failure_is_flagged_but_not_falsely_conclusive(monkeypatch):
    calls = {"n": 0}

    def _one_fails_one_empty(city_key, iso):
        calls["n"] += 1
        if calls["n"] == 1:
            raise RuntimeError("timeout")
        return b"{}", []

    monkeypatch.setattr(court_lookup, "drt_fetch_causelist", _one_fails_one_empty)
    result = court_lookup.lookup_case_in_drt(
        "Dehradun", "ST 88/2023", ["2026-08-01", "2026-08-02"]
    )
    assert result["found"] is False
    assert result["verified"] is True
    assert "some dates could not be checked" in result["reason"]
    assert result["errors"]


# ---------------------------------------------------------------------------
# DELETE /api/me — self-service account deletion
# ---------------------------------------------------------------------------

def test_delete_account_rejects_demo():
    r = client.post("/api/auth/demo", json={})
    token = r.json()["token"]
    r = client.delete("/api/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 403


def test_delete_account_requires_service_role_key(env):
    env(SUPABASE_SERVICE_ROLE_KEY=None)
    app.dependency_overrides[current_user_dep] = lambda: {
        "id": "test-user-id",
        "email": "test@example.com",
        "demo": False,
    }
    try:
        r = client.delete("/api/me", headers={"Authorization": "Bearer fake"})
        assert r.status_code == 503
    finally:
        app.dependency_overrides.pop(current_user_dep, None)
