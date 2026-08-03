"""Local JWT verification (deps.py's current_user via GoTrueClient.get_claims).

Both the malformed-token and expired-token cases are rejected by
supabase_auth's own decode_jwt()/validate_exp() before any network call is
attempted (verified by reading get_claims()'s source) — so these run fully
offline and deterministically, same as the rest of this suite. The two
fallback tests monkeypatch the client directly rather than requiring a real
JWKS outage.
"""
from __future__ import annotations

import time
from datetime import datetime, timezone

import jwt as pyjwt
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from supabase_auth.errors import AuthInvalidJwtError

from app.deps import _user_from_claims, current_user
from app.main import app

client = TestClient(app)


def test_user_from_claims_surfaces_created_at_from_profile_row():
    """GET /me's real-user branch calls _profile_public(user) with no second
    argument (see me.py's _profile_full), so created_at has to come from
    this dict directly — there's no other fallback available for it."""
    out = _user_from_claims(
        "user-id", "user@example.com", {}, {}, "token",
        {"created_at": "2024-05-01T00:00:00+00:00", "plan": "free"},
    )
    assert out["created_at"] == "2024-05-01T00:00:00+00:00"


def _fake_jwt(exp_offset_seconds: int) -> str:
    """A structurally valid JWT (three base64url parts) signed with a
    throwaway HS256 secret — not a real Supabase key, but good enough to
    exercise decode_jwt()/validate_exp(), which both run before any
    signature or JWKS check happens."""
    return pyjwt.encode(
        {"sub": "test-user", "exp": int(time.time()) + exp_offset_seconds},
        "test-secret-not-a-real-key-just-long-enough-for-hs256",
        algorithm="HS256",
        headers={"kid": "test-kid"},
    )


def test_malformed_bearer_token_rejected():
    r = client.get("/api/me", headers={"Authorization": "Bearer not-a-jwt-at-all"})
    assert r.status_code == 401


def test_expired_token_rejected_locally_without_network():
    expired = _fake_jwt(-3600)
    r = client.get("/api/me", headers={"Authorization": f"Bearer {expired}"})
    assert r.status_code == 401


def test_infra_failure_falls_back_to_remote_check(monkeypatch):
    """If local verification can't run at all (JWKS endpoint unreachable,
    unexpected client error, ...), the request should fall back to the
    original remote get_user() check rather than failing every authenticated
    endpoint."""

    class _FakeUser:
        id = "fallback-user-id"
        email = "fallback@example.com"
        user_metadata = {"salt": "c2FsdA=="}
        app_metadata = {}
        # Real supabase_auth.types.User.created_at is a datetime, not a str —
        # match that so this test actually exercises deps.py's normalization.
        created_at = datetime(2024, 1, 1, tzinfo=timezone.utc)

    class _FakeRes:
        user = _FakeUser()

    class _FakeAuth:
        def get_claims(self, token):
            raise ConnectionError("JWKS endpoint unreachable (simulated)")

        def get_user(self, token):
            return _FakeRes()

    class _FakeClient:
        auth = _FakeAuth()

    monkeypatch.setattr("app.deps.auth_verification_client", lambda: _FakeClient())
    monkeypatch.setattr("app.deps.fetch_profile", lambda user_id, token: None)

    result = current_user(authorization="Bearer whatever")
    assert result["id"] == "fallback-user-id"
    assert result["email"] == "fallback@example.com"
    # Must be a plain string (ProfileResponse declares Optional[str]) even
    # though the SDK's User.created_at is a datetime object.
    assert result["created_at"] == "2024-01-01T00:00:00+00:00"


def test_invalid_jwt_error_never_falls_back(monkeypatch):
    """A genuine verification failure must reject immediately — retrying
    remotely would defeat the point and could mask a real attack behind a
    slow, ultimately-still-401 response."""
    calls = {"get_user": 0}

    class _FakeAuth:
        def get_claims(self, token):
            raise AuthInvalidJwtError("bad signature (simulated)")

        def get_user(self, token):
            calls["get_user"] += 1
            raise AssertionError("must not fall back to a remote check for an invalid token")

    class _FakeClient:
        auth = _FakeAuth()

    monkeypatch.setattr("app.deps.auth_verification_client", lambda: _FakeClient())

    with pytest.raises(HTTPException) as exc_info:
        current_user(authorization="Bearer whatever")
    assert exc_info.value.status_code == 401
    assert calls["get_user"] == 0
