"""End-to-end API smoke tests (vault mode + court lookup)."""
from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_healthz():
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.json()["ok"] is True


def test_bootstrap_disabled():
    r = client.get("/api/bootstrap")
    assert r.status_code == 404


def test_demo_auth_and_courts():
    r = client.post("/api/auth/demo", json={})
    assert r.status_code == 200
    token = r.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    courts = client.get("/api/courts", headers=headers)
    assert courts.status_code == 200
    assert len(courts.json()["courts"]) >= 7

    sync = client.post(
        "/api/courts/sync-hearings",
        headers=headers,
        json={"cases": [{"client_case_id": "local-1", "court_id": 2, "case_no": "ST 88/2023"}]},
    )
    assert sync.status_code == 200
    assert sync.json()["ok"] is True

    lookup = client.post(
        "/api/courts/lookup",
        headers=headers,
        json={"court_id": 2, "case_no": "ST 88/2023"},
    )
    assert lookup.status_code == 200
    body = lookup.json()
    assert body["ok"] is True
    assert body["found"] is False
    assert "reason" in body or "warning" in body


def test_login_requires_body():
    r = client.post("/api/login", json={})
    assert r.status_code == 422
