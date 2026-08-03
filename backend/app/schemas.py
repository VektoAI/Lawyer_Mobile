"""Pydantic request/response models."""
from __future__ import annotations

from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field


class SignupBody(BaseModel):
    email: str
    password: str = Field(min_length=8)
    salt: str = Field(min_length=16, description="Client-generated base64 PBKDF2 salt")
    display_name: Optional[str] = None
    phone: Optional[str] = Field(default=None, max_length=20)
    email_redirect_to: Optional[str] = Field(
        default=None,
        description="Where Supabase redirects after the user clicks the confirm email link",
    )


class LoginBody(BaseModel):
    email: str
    password: str


class ResendBody(BaseModel):
    email: str
    email_redirect_to: Optional[str] = None


class RefreshBody(BaseModel):
    refresh_token: str


class ConfirmBody(BaseModel):
    token_hash: str
    type: str = "signup"


class ProfileUpdateBody(BaseModel):
    display_name: Optional[str] = None
    enrolment: Optional[str] = None
    bar_council: Optional[str] = None
    chamber: Optional[str] = None
    phone: Optional[str] = Field(default=None, max_length=20)


class CaseRefreshItem(BaseModel):
    client_case_id: str = Field(min_length=1, max_length=80)
    court_id: int = Field(ge=1)
    case_no: str = Field(min_length=2, max_length=80)


class SyncHearingsBody(BaseModel):
    """Client sends case refs only — server returns hearing hints; vault stays on device."""

    cases: list[CaseRefreshItem] = Field(default_factory=list, max_length=40)
    advocate_name: Optional[str] = Field(default=None, max_length=120)
    scan_court_ids: Optional[list[int]] = Field(default=None, max_length=5)


class CaseLookupBody(BaseModel):
    court_id: int = Field(ge=1)
    case_no: str = Field(min_length=2, max_length=80)
    list_date: Optional[str] = Field(default=None, description="ISO YYYY-MM-DD hearing date hint")


# ---------------------------------------------------------------------------
# Response models
#
# These document and validate what each route actually returns today —
# field names/values are unchanged from before; this only adds a declared
# shape. A few endpoints (court lookup/sync, causelist parsing, cron) build
# their payload dynamically several layers down in the service code, with
# genuinely different optional fields per branch — those use `extra="allow"`
# so the *known* fields are documented without risking silently dropping
# anything FastAPI's response_model filtering doesn't know about yet.
# ---------------------------------------------------------------------------


class OkResponse(BaseModel):
    ok: bool = True


class HealthResponse(BaseModel):
    ok: bool
    mode: str
    serve_ui: bool
    supabase: bool
    demo: bool
    ts: str
    uptime_seconds: float


class PublicConfigResponse(BaseModel):
    ok: bool
    supabase_url: Optional[str] = None
    frontend_url: str
    vault_mode: bool
    demo: bool
    single_device: bool
    same_origin: bool


class AuthSessionResponse(BaseModel):
    """Shared shape for every route that hands back a session or
    session-adjacent status (signup, login, demo, confirm, refresh). These
    routes return meaningfully different subsets of these fields depending
    on which branch executes (e.g. signup with no immediate session vs.
    with one) — every field beyond `ok` is optional rather than forcing
    five near-identical models for what's really one concept."""

    ok: bool
    token: Optional[str] = None
    refresh_token: Optional[str] = None
    user_id: Optional[str] = None
    email: Optional[str] = None
    salt: Optional[str] = None
    plan: Optional[str] = None
    demo: Optional[bool] = None
    read_only: Optional[bool] = None
    demo_password: Optional[str] = None
    display_name: Optional[str] = None
    enrolment: Optional[str] = None
    bar_council: Optional[str] = None
    chamber: Optional[str] = None
    needs_email_confirm: Optional[bool] = None
    email_redirect_to: Optional[str] = None
    confirmed: Optional[bool] = None
    message: Optional[str] = None


class ResendConfirmResponse(BaseModel):
    ok: bool
    email: str
    email_redirect_to: str
    message: str


class PurgeUsersResponse(BaseModel):
    ok: bool
    deleted: list[str]
    errors: list[str]
    kept: list[str]
    note: str


class ProfileResponse(BaseModel):
    """GET /me and PATCH /me/profile share this shape (_profile_public)."""

    ok: bool
    id: str
    email: str
    plan: str
    salt: Optional[str] = None
    created_at: Optional[str] = None
    demo: bool
    read_only: bool
    display_name: str
    enrolment: str
    bar_council: str
    chamber: str
    phone: str


class SubscriptionResponse(BaseModel):
    ok: bool
    plan: str
    demo: bool
    read_only: bool


class DeleteAccountResponse(BaseModel):
    ok: bool
    deleted: bool


class CourtOption(BaseModel):
    id: int
    name: str
    type: str
    adapter: str
    live: bool
    ingest: Optional[str] = None


class CourtsListResponse(BaseModel):
    ok: bool
    courts: list[CourtOption]


class DynamicResponse(BaseModel):
    """Permissive envelope for endpoints whose payload genuinely varies by
    code path several layers down in the service/adapter layer — see the
    module docstring above."""

    model_config = ConfigDict(extra="allow")
    ok: bool


class StripeWebhookResponse(BaseModel):
    ok: bool
    received: bool
    type: Optional[str] = None
    updated: bool


class CronCauseListSyncResponse(BaseModel):
    model_config = ConfigDict(extra="allow")
    ok: bool
    mode: str
    inbox: dict[str, Any]
    drt: list[dict[str, Any]]
    note: str


class CronProcessInboxResponse(BaseModel):
    ok: bool
    processed: list[dict[str, Any]]


class CronCauseListStatusResponse(BaseModel):
    ok: bool
    courts: list[dict[str, Any]]
