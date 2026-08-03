"""Supabase client helpers — auth/billing profiles only."""
from __future__ import annotations

from functools import lru_cache
from typing import Any, Optional

import httpx
from fastapi import HTTPException

from app.config import Settings, get_settings


def require_supabase(settings: Optional[Settings] = None) -> Settings:
    settings = settings or get_settings()
    if not settings.supabase_configured:
        raise HTTPException(
            503,
            "Supabase is not configured — set SUPABASE_URL and SUPABASE_ANON_KEY in backend/.env",
        )
    return settings


def supabase_client(*, service: bool = False, settings: Optional[Settings] = None):
    settings = require_supabase(settings)
    from supabase import create_client

    if service:
        if not settings.supabase_service_role_key:
            raise HTTPException(503, "SUPABASE_SERVICE_ROLE_KEY required for this operation")
        key = settings.supabase_service_role_key
    else:
        key = settings.supabase_anon_key
    return create_client(settings.supabase_url, key)


@lru_cache
def _cached_anon_client(supabase_url: str, anon_key: str):
    from supabase import create_client

    return create_client(supabase_url, anon_key)


def auth_verification_client(settings: Optional[Settings] = None):
    """A long-lived anon-key client reserved for JWT verification.

    `supabase_client()` above deliberately builds a fresh client per call —
    fine when every call round-trips to Supabase anyway, but local JWT
    verification (`GoTrueClient.get_claims`, see deps.py's `current_user`)
    keeps its JWKS cache on the client instance itself. A fresh instance per
    request would silently defeat that cache and re-fetch the JWKS every
    time. Cached by (url, key) — same lru_cache pattern as
    `config.get_settings` — so it stays a real singleton per deployment but
    still picks up a changed key in tests that swap settings.
    """
    settings = require_supabase(settings)
    return _cached_anon_client(settings.supabase_url, settings.supabase_anon_key)


def fetch_profile(user_id: str, access_token: str, settings: Optional[Settings] = None) -> Optional[dict]:
    settings = require_supabase(settings)
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_anon_key)
        sb.postgrest.auth(access_token)
        row = sb.table("profiles").select("*").eq("id", user_id).limit(1).execute()
        if row.data:
            return row.data[0]
    except Exception:
        pass
    return None


def ensure_profile(
    user_id: str,
    email: str,
    salt: str,
    access_token: Optional[str] = None,
    settings: Optional[Settings] = None,
    *,
    display_name: Optional[str] = None,
    enrolment: Optional[str] = None,
    bar_council: Optional[str] = None,
    chamber: Optional[str] = None,
    phone: Optional[str] = None,
) -> None:
    settings = settings or get_settings()
    payload = {"id": user_id, "email": email, "salt": salt, "plan": "free"}
    if display_name is not None:
        payload["display_name"] = display_name
    if enrolment is not None:
        payload["enrolment"] = enrolment
    if bar_council is not None:
        payload["bar_council"] = bar_council
    if chamber is not None:
        payload["chamber"] = chamber
    if phone is not None:
        payload["phone"] = phone
    try:
        if access_token and settings.supabase_configured:
            from supabase import create_client
            sb = create_client(settings.supabase_url, settings.supabase_anon_key)
            sb.postgrest.auth(access_token)
            sb.table("profiles").upsert(payload).execute()
            return
    except Exception:
        pass
    if settings.supabase_service_role_key:
        try:
            supabase_client(service=True, settings=settings).table("profiles").upsert(payload).execute()
        except Exception:
            pass


def _auth_update_user_metadata(access_token: str, meta: dict[str, Any], settings: Settings) -> dict[str, Any]:
    """Store chamber fields on auth user_metadata (works without profiles columns)."""
    url = settings.supabase_url.rstrip("/") + "/auth/v1/user"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "apikey": settings.supabase_anon_key,
        "Content-Type": "application/json",
    }
    with httpx.Client(timeout=20.0) as client:
        res = client.put(url, headers=headers, json={"data": meta})
        if res.status_code >= 400:
            raise RuntimeError(f"auth metadata update failed ({res.status_code}): {res.text[:300]}")
        body = res.json()
        return body.get("user_metadata") or body.get("user", {}).get("user_metadata") or meta


def update_profile_fields(
    user_id: str,
    fields: dict,
    access_token: str,
    *,
    email: str = "",
    salt: str = "",
    settings: Optional[Settings] = None,
) -> dict:
    """
    Persist chamber identity for the account.
    Prefer auth user_metadata (always available), then best-effort upsert into profiles.
    """
    settings = require_supabase(settings)
    allowed = {
        k: v
        for k, v in fields.items()
        if k in ("display_name", "enrolment", "bar_council", "chamber", "phone")
    }
    if not allowed:
        raise RuntimeError("no profile fields to update")

    # 1) Auth metadata first — this is what makes GET /me show the name
    meta_err: Optional[str] = None
    try:
        meta = _auth_update_user_metadata(access_token, allowed, settings)
    except Exception as exc:
        meta = dict(allowed)
        meta_err = str(exc)

    # 2) Best-effort profiles table (needs columns from profiles_schema.sql)
    row: Optional[dict] = None
    try:
        from supabase import create_client
        sb = create_client(settings.supabase_url, settings.supabase_anon_key)
        sb.postgrest.auth(access_token)

        existing = None
        try:
            got = sb.table("profiles").select("*").eq("id", user_id).limit(1).execute()
            if got.data:
                existing = got.data[0]
        except Exception:
            existing = None

        if existing is not None:
            # Update only known chamber fields; ignore unknown-column errors
            try:
                res = sb.table("profiles").update(allowed).eq("id", user_id).execute()
                if res.data:
                    row = res.data[0]
            except Exception:
                # Columns may not exist yet — ignore
                pass

        if row is None:
            upsert_row = {
                "id": user_id,
                "email": email or (existing or {}).get("email") or "",
                "salt": salt or (existing or {}).get("salt") or "pending",
                "plan": (existing or {}).get("plan") or "free",
            }
            # Try with chamber columns; if PostgREST rejects, try core columns only
            try:
                res = sb.table("profiles").upsert({**upsert_row, **allowed}).execute()
                if res.data:
                    row = res.data[0]
            except Exception:
                try:
                    sb.table("profiles").upsert(upsert_row).execute()
                except Exception:
                    pass
    except Exception:
        pass

    out = {
        "id": user_id,
        "email": email,
        "salt": salt,
        "plan": (row or {}).get("plan") or "free",
        "display_name": (row or {}).get("display_name") or meta.get("display_name", allowed.get("display_name", "")),
        "enrolment": (row or {}).get("enrolment") or meta.get("enrolment", allowed.get("enrolment", "")),
        "bar_council": (row or {}).get("bar_council") or meta.get("bar_council", allowed.get("bar_council", "")),
        "chamber": (row or {}).get("chamber") or meta.get("chamber", allowed.get("chamber", "")),
        "phone": (row or {}).get("phone") or meta.get("phone", allowed.get("phone", "")),
    }
    if meta_err and not any(out.get(k) for k in ("display_name", "enrolment", "bar_council", "chamber", "phone")):
        raise RuntimeError(
            "Could not save profile to account. "
            "Check SUPABASE_ANON_KEY, or run backend/profiles_schema.sql. "
            f"Detail: {meta_err}"
        )
    return out
