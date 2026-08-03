"""Cron routes — cause-list inbox + DRT cache refresh (no lawyer vault)."""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from app.config import get_settings
from app.schemas import CronCauseListStatusResponse, CronCauseListSyncResponse, CronProcessInboxResponse
from app.services.causelist_inbox import cache_status, process_inbox, run_causelist_cron

router = APIRouter(tags=["cron"])


def require_cron_secret(x_cron_secret: str | None = Header(default=None, alias="X-Cron-Secret")):
    settings = get_settings()
    secret = settings.cron_secret
    if not secret:
        raise HTTPException(
            503,
            "Set MUNSHI_CRON_SECRET or MUNSHI_ADMIN_TOKEN on the server to enable cron",
        )
    if not x_cron_secret or x_cron_secret != secret:
        raise HTTPException(401, "invalid cron secret")


class CronBody(BaseModel):
    list_dates: Optional[list[str]] = Field(default=None, max_length=14)


@router.post("/cron/causelist-sync", response_model=CronCauseListSyncResponse)
def cron_causelist_sync(body: CronBody | None = None, _auth=Depends(require_cron_secret)):
    """Process data/inbox HTML + refresh live DRT caches. Safe to run on a schedule."""
    dates = body.list_dates if body else None
    return run_causelist_cron(dates)


@router.post("/cron/process-inbox", response_model=CronProcessInboxResponse)
def cron_process_inbox_only(_auth=Depends(require_cron_secret)):
    """Only parse files dropped in data/inbox/ (ops / clerk workflow)."""
    return process_inbox()


@router.get("/cron/causelist-status", response_model=CronCauseListStatusResponse)
def cron_causelist_status(_auth=Depends(require_cron_secret)):
    return cache_status()
