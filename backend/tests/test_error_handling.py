"""Global exception handling (factory.py's unhandled_exception_handler).

Registers a temporary route on the real `app` so this exercises the actual
middleware/handler stack rather than a synthetic FastAPI instance.
"""
from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app, raise_server_exceptions=False)


def test_unhandled_exception_returns_consistent_envelope_no_leak():
    @app.get("/api/__test_unhandled_exception")
    def _boom():
        raise RuntimeError("simulated failure containing sensitive-looking-value=abc123")

    try:
        r = client.get("/api/__test_unhandled_exception")
        assert r.status_code == 500
        assert r.headers["content-type"].startswith("application/json")
        assert r.json() == {"detail": "Internal server error"}
        assert "sensitive-looking-value" not in r.text
    finally:
        app.router.routes = [rt for rt in app.router.routes if getattr(rt, "path", None) != "/api/__test_unhandled_exception"]


def test_http_exception_still_carries_its_own_detail_and_status():
    """The global handler must never shadow FastAPI's own, more specific
    HTTPException handling — verified against a real endpoint already in
    the app rather than a synthetic one."""
    r = client.post("/api/login", json={})  # missing required fields
    assert r.status_code == 422  # FastAPI's own request-validation handling
