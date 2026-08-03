"""Rate limiting (app/rate_limit.py, config.py's MUNSHI_RATE_LIMIT_* settings).

conftest.py's autouse fixture resets the shared in-memory limiter before and
after every test in this file, so these don't interfere with each other or
with the rest of the suite.
"""
from __future__ import annotations

import inspect

from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app

client = TestClient(app)


def test_rate_limited_routes_accept_response_param_for_header_injection():
    """Regression test for a real bug: slowapi's `Limiter.limit()` decorator
    needs a `response: Response` parameter on any decorated endpoint that
    doesn't itself return a `starlette.responses.Response` (i.e. returns a
    plain dict, as every route below does) — otherwise its header-injection
    step (`_inject_headers`) throws `Exception: parameter response must be
    an instance of starlette.responses.Response`.

    This only fires on the *success* path — every existing rate-limit test
    above used wrong credentials, which raise HTTPException before slowapi's
    wrapper ever reaches that code, so the bug shipped to production
    undetected. Checking the signature directly (rather than re-running
    every route's success path, which would need live Supabase credentials
    for signup/login) catches this for any route that's rate-limited today
    or in the future.
    """
    from app.routers import auth, me

    rate_limited_endpoints = [auth.signup, auth.resend_confirm, auth.login, me.delete_account]
    for endpoint in rate_limited_endpoints:
        sig = inspect.signature(endpoint)
        assert "response" in sig.parameters, (
            f"{endpoint.__name__} is decorated with @limiter.limit(...) and returns a plain "
            "dict, but has no `response: Response` parameter — slowapi will throw on its "
            "success path (see test_login_succeeds_with_rate_limiting_enabled)."
        )


def test_login_rate_limited_per_ip(monkeypatch):
    monkeypatch.setenv("MUNSHI_RATE_LIMIT_LOGIN", "2/minute")
    get_settings.cache_clear()
    try:
        body = {"email": "nobody@example.com", "password": "wrong-password"}
        r1 = client.post("/api/login", json=body)
        r2 = client.post("/api/login", json=body)
        r3 = client.post("/api/login", json=body)
        assert r1.status_code != 429
        assert r2.status_code != 429
        assert r3.status_code == 429
        assert "retry-after" in {h.lower() for h in r3.headers.keys()}
        assert r3.json()["detail"]  # consistent {"detail": ...} envelope, not slowapi's default shape
    finally:
        get_settings.cache_clear()


def test_rate_limit_is_per_ip_not_global(monkeypatch):
    """Two different X-Forwarded-For clients must not share one budget."""
    monkeypatch.setenv("MUNSHI_RATE_LIMIT_LOGIN", "1/minute")
    get_settings.cache_clear()
    try:
        body = {"email": "nobody@example.com", "password": "wrong-password"}
        r1 = client.post("/api/login", json=body, headers={"X-Forwarded-For": "203.0.113.1"})
        r2 = client.post("/api/login", json=body, headers={"X-Forwarded-For": "203.0.113.1"})
        r3 = client.post("/api/login", json=body, headers={"X-Forwarded-For": "203.0.113.2"})
        assert r1.status_code != 429
        assert r2.status_code == 429  # same forwarded IP, budget already spent
        assert r3.status_code != 429  # different forwarded IP, fresh budget
    finally:
        get_settings.cache_clear()


def test_delete_account_rate_limited_per_account(monkeypatch):
    monkeypatch.setenv("MUNSHI_RATE_LIMIT_DELETE_ACCOUNT", "1/hour")
    get_settings.cache_clear()
    try:
        r = client.post("/api/auth/demo", json={})
        token = r.json()["token"]
        headers = {"Authorization": f"Bearer {token}"}
        r1 = client.delete("/api/me", headers=headers)
        r2 = client.delete("/api/me", headers=headers)
        assert r1.status_code == 403  # demo account — rejected for a different reason, but still counts a hit
        assert r2.status_code == 429
    finally:
        get_settings.cache_clear()


def test_login_succeeds_with_rate_limiting_enabled(monkeypatch):
    """Concrete regression test for the same bug as the signature check
    above: a *successful* login (not just a rejected one) must not 500 when
    rate limiting is enabled. Uses the demo credentials so this needs no
    live Supabase account, while still going through the real
    @limiter.limit(...)-decorated `login()` route and its plain-dict return.
    """
    monkeypatch.setenv("MUNSHI_DEMO", "1")
    get_settings.cache_clear()
    try:
        r = client.post("/api/login", json={"email": "demo@localhost", "password": "demo-password-change-me"})
        assert r.status_code == 200
        assert r.json()["ok"] is True
    finally:
        get_settings.cache_clear()


def test_rate_limiting_disabled_via_settings(monkeypatch):
    """MUNSHI_RATE_LIMIT_ENABLED=0 must actually flip the shared limiter off
    through create_app()'s own wiring — not just something the code claims
    to do."""
    from app.factory import create_app
    from app.rate_limit import limiter

    monkeypatch.setenv("MUNSHI_RATE_LIMIT_ENABLED", "0")
    get_settings.cache_clear()
    create_app()
    try:
        assert limiter.enabled is False
    finally:
        # Restore via the same factory path — this is a shared, module-level
        # singleton, so leaving it disabled would silently affect every
        # other test in the suite.
        monkeypatch.setenv("MUNSHI_RATE_LIMIT_ENABLED", "1")
        get_settings.cache_clear()
        create_app()
        assert limiter.enabled is True
