"""Every JSON response should carry a consistent {"ok": ...} success flag —
previously GET /api/me, /api/courts, /api/config, /api/cron/causelist-status,
and POST /api/auth/refresh all omitted it, and /api/me/subscription was a
byte-identical decoy of /api/me rather than its own narrower shape.
"""
from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def _demo_headers():
    r = client.post("/api/auth/demo", json={})
    token = r.json()["token"]
    return {"Authorization": f"Bearer {token}"}


def test_me_has_ok_key():
    r = client.get("/api/me", headers=_demo_headers())
    assert r.status_code == 200
    assert r.json()["ok"] is True


def test_me_subscription_is_narrower_than_me_not_a_decoy():
    full = client.get("/api/me", headers=_demo_headers()).json()
    sub = client.get("/api/me/subscription", headers=_demo_headers()).json()
    assert sub["ok"] is True
    assert set(sub.keys()) == {"ok", "plan", "demo", "read_only"}
    assert sub["plan"] == full["plan"]
    assert set(sub.keys()) != set(full.keys())  # no longer an identical decoy


def test_courts_has_ok_key():
    r = client.get("/api/courts", headers=_demo_headers())
    assert r.json()["ok"] is True


def test_config_has_ok_key():
    r = client.get("/api/config")
    assert r.json()["ok"] is True


def test_cron_causelist_status_has_ok_key(monkeypatch):
    monkeypatch.setenv("MUNSHI_CRON_SECRET", "test-secret")
    from app.config import get_settings

    get_settings.cache_clear()
    r = client.get("/api/cron/causelist-status", headers={"X-Cron-Secret": "test-secret"})
    assert r.json()["ok"] is True
    get_settings.cache_clear()


def test_refresh_has_ok_key():
    r = client.post("/api/auth/refresh", json={"refresh_token": "demo-local-vault"})
    assert r.json()["ok"] is True
