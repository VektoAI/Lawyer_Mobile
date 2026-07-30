"""Application settings — loaded from backend/.env."""
from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent  # backend/
REPO_ROOT = BASE_DIR.parent
UI_DIR = REPO_ROOT / "web" / "munshi-ui"

try:
    from dotenv import load_dotenv
    load_dotenv(BASE_DIR / ".env")
except ImportError:
    pass


DEFAULT_CORS = (
    "http://127.0.0.1:4173,"
    "http://localhost:4173,"
    "http://127.0.0.1:8080,"
    "http://localhost:8080"
)


@lru_cache
def get_settings() -> "Settings":
    return Settings()


class Settings:
    def __init__(self) -> None:
        self.supabase_url = (os.environ.get("SUPABASE_URL") or "").rstrip("/")
        self.supabase_anon_key = (
            os.environ.get("SUPABASE_ANON_KEY")
            or os.environ.get("SUPABASE_KEY")
            or ""
        )
        self.supabase_service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or ""
        self.stripe_webhook_secret = os.environ.get("STRIPE_WEBHOOK_SECRET") or ""
        self.demo_open = os.environ.get("MUNSHI_DEMO", "1") == "1"
        # API-only (mobile) vs API + legacy PWA (web/munshi-ui).
        self.serve_ui = os.environ.get("MUNSHI_SERVE_UI", "0") == "1"
        self.openapi_enabled = os.environ.get("MUNSHI_OPENAPI", "1" if self.demo_open else "0") == "1"
        self.frontend_url = (os.environ.get("MUNSHI_FRONTEND_URL") or "http://127.0.0.1:4173").rstrip("/")
        self.ui_dir = Path(os.environ.get("MUNSHI_UI_DIR", str(UI_DIR)))
        raw = os.environ.get("MUNSHI_CORS_ORIGINS") or DEFAULT_CORS
        self.cors_origins = [o.strip() for o in raw.split(",") if o.strip()]
        if self.frontend_url not in self.cors_origins:
            self.cors_origins.append(self.frontend_url)
        self.data_dir = Path(os.environ.get("MUNSHI_DATA_DIR", str(BASE_DIR / "data")))
        self.inbox_dir = self.data_dir / "inbox"
        self.causelist_cache_dir = self.data_dir / "causelist_cache"
        self.admin_token = os.environ.get("MUNSHI_ADMIN_TOKEN") or ""
        self.cron_secret = (
            os.environ.get("MUNSHI_CRON_SECRET")
            or self.admin_token
            or ""
        )
        # Deep link for mobile email confirm (Supabase redirect allow-list).
        self.mobile_auth_redirect = (
            os.environ.get("MUNSHI_MOBILE_AUTH_REDIRECT") or "casevault://auth/confirm"
        ).strip()

    @property
    def supabase_configured(self) -> bool:
        return bool(self.supabase_url and self.supabase_anon_key)
