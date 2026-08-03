"""Startup configuration diagnostics (factory.py's create_app)."""
from __future__ import annotations

import logging

from app.config import get_settings
from app.factory import create_app


def test_warns_loudly_when_demo_off_and_supabase_unconfigured(monkeypatch, caplog):
    monkeypatch.setenv("MUNSHI_DEMO", "0")
    monkeypatch.setenv("SUPABASE_URL", "")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "")
    get_settings.cache_clear()
    try:
        with caplog.at_level(logging.ERROR, logger="munshi.startup"):
            create_app()
        assert any("every real authenticated request will fail" in r.message for r in caplog.records)
    finally:
        get_settings.cache_clear()


def test_no_error_logged_when_demo_open_without_supabase(monkeypatch, caplog):
    monkeypatch.setenv("MUNSHI_DEMO", "1")
    monkeypatch.setenv("SUPABASE_URL", "")
    monkeypatch.setenv("SUPABASE_ANON_KEY", "")
    get_settings.cache_clear()
    try:
        with caplog.at_level(logging.ERROR, logger="munshi.startup"):
            create_app()
        assert not any(r.levelno >= logging.ERROR for r in caplog.records)
    finally:
        get_settings.cache_clear()
