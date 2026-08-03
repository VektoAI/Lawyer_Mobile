"""Structured logging (app/logging_config.py) and the request-id middleware
in factory.py."""
from __future__ import annotations

import json
import logging

from fastapi.testclient import TestClient

from app.logging_config import JsonFormatter, mask_email
from app.main import app

client = TestClient(app)


def test_mask_email_keeps_first_char_and_domain():
    assert mask_email("jdoe@example.com") == "j***@example.com"


def test_mask_email_handles_missing_or_malformed_input():
    assert mask_email("") == "***"
    assert mask_email("not-an-email") == "***"


def test_json_formatter_emits_parseable_structured_line():
    record = logging.LogRecord(
        name="munshi.test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="something happened",
        args=None,
        exc_info=None,
    )
    record.request_id = "test-request-id"
    record.duration_ms = 12.3
    line = JsonFormatter().format(record)
    payload = json.loads(line)  # must be valid JSON, not just formatted text
    assert payload["level"] == "INFO"
    assert payload["logger"] == "munshi.test"
    assert payload["message"] == "something happened"
    assert payload["request_id"] == "test-request-id"
    assert payload["duration_ms"] == 12.3
    assert "timestamp" in payload


def test_response_echoes_incoming_request_id():
    r = client.get("/healthz", headers={"X-Request-ID": "caller-supplied-id"})
    assert r.headers["x-request-id"] == "caller-supplied-id"


def test_response_generates_request_id_when_absent():
    r = client.get("/healthz")
    assert r.headers.get("x-request-id")  # present and non-empty
