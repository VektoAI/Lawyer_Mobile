"""Structured logging — one consistent strategy across the whole backend.

Emits one JSON object per log line: timestamp, level, logger name, message,
a request id (see `request_id_var` — set by factory.py's middleware for the
life of one request, so every log line emitted while handling it can be
correlated), plus any extra structured fields passed via
`logger.info(..., extra={...})`.

Replaces the ad-hoc `print()` calls in routers/auth.py and the
previously-configured-but-barely-used `logging.getLogger("munshi.access")`
logger in factory.py — both now go through this same formatter.

Never log: passwords, encryption keys, access/refresh tokens, or decrypted
vault data (vault contents never reach this backend at all — see
CLAUDE.md's zero-knowledge invariant). Email addresses are masked with
`mask_email()` before they reach a log call.
"""
from __future__ import annotations

import json
import logging
import sys
import time
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar("request_id", default="-")

# Attribute names every stdlib LogRecord already has — anything else found on
# a record (i.e. passed via `extra={...}`) is a caller-supplied structured
# field and gets folded into the JSON output.
_STANDARD_RECORD_KEYS = set(logging.LogRecord("", 0, "", 0, "", None, None).__dict__.keys()) | {"message"}


class _RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_var.get()
        return True


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(record.created)) + f".{int(record.msecs):03d}Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": getattr(record, "request_id", "-"),
        }
        for key, value in record.__dict__.items():
            if key not in _STANDARD_RECORD_KEYS and key not in payload:
                payload[key] = value
        if record.exc_info:
            payload["exc_info"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def configure_logging(level: str = "INFO") -> None:
    """Idempotent — safe to call more than once (`create_app()` can run
    multiple times within one process, e.g. in tests)."""
    root = logging.getLogger()
    if getattr(root, "_munshi_configured", False):
        return
    root.setLevel(level)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    handler.addFilter(_RequestIdFilter())
    root.handlers = [handler]
    root._munshi_configured = True  # type: ignore[attr-defined]


def mask_email(email: str) -> str:
    """`jdoe@example.com` -> `j***@example.com` — enough to correlate
    repeated log lines to the same account without writing the full
    address."""
    if not email or "@" not in email:
        return "***"
    local, _, domain = email.partition("@")
    if not local:
        return f"***@{domain}"
    return f"{local[0]}***@{domain}"
