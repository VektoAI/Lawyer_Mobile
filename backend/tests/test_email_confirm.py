"""Regression tests for the browser-facing email confirmation page.

GET /api/auth/confirm is what the confirmation email link now points to (see
_confirm_redirect_url in app/routers/auth.py) — an https URL that verifies the
one-time Supabase token_hash exactly once, server-side, then hands off a
ready-to-use session to the app via a casevault:// deep link fragment. The app
already parses access_token/refresh_token out of that fragment
(AuthService.sessionFromAuthCallbackUri) with no changes needed on that side.
"""
from __future__ import annotations

import re

from fastapi.testclient import TestClient

import app.routers.auth as auth_mod
from app.main import app

client = TestClient(app)


class _FakeSession:
    access_token = "AT.abc123"
    refresh_token = "RT.xyz789"


class _FakeUser:
    id = "user-uuid-1"
    email = "lawyer@example.com"
    user_metadata = {"salt": "c29tZXNhbHQ="}


class _FakeVerifyResult:
    user = _FakeUser()
    session = _FakeSession()


def test_confirm_page_missing_token_hash_serves_fragment_fallback():
    """No token_hash query param is the *normal* case on Supabase's free tier —
    it verifies server-side and puts the session in the URL fragment instead,
    which this response can't see server-side. The page itself must still
    load (200) with client-side JS that reads the fragment; it is not an
    error until that JS also finds nothing."""
    r = client.get("/api/auth/confirm")
    assert r.status_code == 200
    assert r.headers["cache-control"] == "no-store"
    assert "location.hash" in r.text
    assert "access_token" in r.text


def test_confirm_page_expired_token_shows_error(monkeypatch):
    class _FakeAuth:
        def verify_otp(self, payload):
            raise RuntimeError("Token has expired or is invalid")

    class _FakeClient:
        auth = _FakeAuth()

    monkeypatch.setattr(auth_mod, "supabase_client", lambda *a, **kw: _FakeClient())
    r = client.get("/api/auth/confirm", params={"token_hash": "bad", "type": "signup"})
    assert r.status_code == 400
    assert "expired" in r.text.lower() or "already used" in r.text.lower()


def test_confirm_page_success_hands_off_session_via_fragment(monkeypatch):
    class _FakeAuth:
        def verify_otp(self, payload):
            assert payload == {"token_hash": "good-token", "type": "signup"}
            return _FakeVerifyResult()

    class _FakeClient:
        auth = _FakeAuth()

    monkeypatch.setattr(auth_mod, "supabase_client", lambda *a, **kw: _FakeClient())
    monkeypatch.setattr(auth_mod, "ensure_profile", lambda *a, **kw: None)

    r = client.get("/api/auth/confirm", params={"token_hash": "good-token", "type": "signup"})
    assert r.status_code == 200
    assert r.headers["cache-control"] == "no-store"

    # Tokens must reach the app only via the URL fragment (never a query string —
    # fragments are never sent over the wire or logged server-side).
    assert "?access_token" not in r.text
    m = re.search(r"casevault://auth/confirm#([^\"'\s<]+)", r.text)
    assert m, "expected a casevault://auth/confirm#... deep link in the page"
    frag = m.group(1)
    assert "access_token=AT.abc123" in frag
    assert "refresh_token=RT.xyz789" in frag

    # The auto-redirect script must carry the identical, unescaped fragment
    # (valid JS string) — while the visible fallback button link is
    # HTML-attribute-escaped (&amp;). Both must point at the same URL.
    script = re.search(r"<script>(.*?)</script>", r.text).group(1)
    assert "access_token=AT.abc123&refresh_token=RT.xyz789" in script


def test_confirm_redirect_url_is_self_hosted_not_legacy_web_app():
    """Signup's email_redirect_to must point at this API's own confirm page —
    not the legacy munshi-ui web app, and not a header-sniffed guess."""
    from starlette.requests import Request

    scope = {
        "type": "http",
        "method": "GET",
        "path": "/",
        "headers": [],
        "scheme": "https",
        "server": ("munshi-api.onrender.com", 443),
    }
    req = Request(scope)
    url = auth_mod._confirm_redirect_url(req)
    assert url == "https://munshi-api.onrender.com/api/auth/confirm"
