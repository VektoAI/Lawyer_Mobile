"""Health check."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter

router = APIRouter(tags=["system"])


@router.get("/health")
def health():
    return {
        "ok": True,
        "service": "munshi-mobile-sync",
        "mode": "sqlite-dev",
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
