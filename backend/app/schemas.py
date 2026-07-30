"""Pydantic request bodies for auth."""
from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


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
