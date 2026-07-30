"""Application settings — loaded from mobile/backend/.env.

Mirrors backend/app/config.py's conventions (hand-rolled Settings over
os.environ, no pydantic-settings, memoized via lru_cache) so the two services
stay easy to read side by side.
"""
from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent  # mobile/backend/
DATA_DIR = BASE_DIR / "data"

try:
    from dotenv import load_dotenv
    load_dotenv(BASE_DIR / ".env")
except ImportError:
    pass


DEFAULT_CORS = (
    "http://127.0.0.1:4173,"
    "http://localhost:4173"
)


@lru_cache
def get_settings() -> "Settings":
    return Settings()


class Settings:
    def __init__(self) -> None:
        # Dev-mode backing store. Phase C target is Supabase Postgres — see
        # ../supabase_migration.sql and ARCHITECTURE.md §12. Not decided here.
        self.db_path = Path(os.environ.get("MUNSHI_MOBILE_DB_PATH") or (DATA_DIR / "sync.db"))
        raw = os.environ.get("MUNSHI_MOBILE_CORS_ORIGINS") or DEFAULT_CORS
        self.cors_origins = [o.strip() for o in raw.split(",") if o.strip()]
