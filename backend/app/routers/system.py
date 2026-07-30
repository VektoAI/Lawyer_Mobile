"""Health and public config."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException

from app.config import get_settings

router = APIRouter(tags=["system"])


@router.get("/healthz")
def healthz():
    settings = get_settings()
    return {
        "ok": True,
        "mode": "api-only" if not settings.serve_ui else "api-and-legacy-pwa",
        "serve_ui": settings.serve_ui,
        "supabase": settings.supabase_configured,
        "demo": settings.demo_open,
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }


@router.get("/api/config")
def public_config():
    settings = get_settings()
    return {
        "ok": True,
        "supabase_url": settings.supabase_url or None,
        "frontend_url": settings.frontend_url,
        "vault_mode": True,
        "demo": settings.demo_open,
        "single_device": True,
        "same_origin": settings.serve_ui,
    }


@router.api_route("/api/bootstrap", methods=["GET", "POST", "PUT"])
def bootstrap_cases_disabled():
    """Vault mode: case rows live on device only (munshi-ui verify expects non-200)."""
    raise HTTPException(
        status_code=404,
        detail="vault mode — no server-side case bootstrap; cases are encrypted on the client",
    )
