"""FastAPI dependencies — Bearer JWT → account (never case data)."""
from __future__ import annotations

import logging
from typing import Any, Optional

from fastapi import Header, HTTPException
from supabase_auth.errors import AuthInvalidJwtError

from app.config import get_settings
from app.supabase_client import auth_verification_client, fetch_profile

log = logging.getLogger("munshi.auth")

DEMO_TOKEN = "demo-local-vault"
DEMO_SALT = "ZGVtbw1zYWx0LW11bnNoaS12YXVsdC0wMQ=="


def demo_user(token: str = DEMO_TOKEN) -> dict[str, Any]:
    """Public showcase identity — always valid for DEMO_TOKEN. Cases stay local & view-only."""
    return {
        "id": "demo-local",
        "email": "demo@localhost",
        "plan": "pilot",
        "salt": DEMO_SALT,
        "demo": True,
        "read_only": True,
        "access_token": token,
        "display_name": "Adv. Priyanshu Jain",
        "enrolment": "UK/1234/2015",
        "bar_council": "Bar Council of Uttarakhand",
        "chamber": "Chamber 14, District Court Complex, Dehradun",
    }


def demo_session_payload() -> dict[str, Any]:
    return {
        "ok": True,
        "token": DEMO_TOKEN,
        "user_id": "demo-local",
        "email": "demo@localhost",
        "salt": DEMO_SALT,
        "plan": "pilot",
        "demo": True,
        "read_only": True,
        "demo_password": "demo-password-change-me",
    }


def _user_from_claims(sub: str, email: str, user_metadata: dict, app_metadata: dict, token: str, profile: Optional[dict]) -> dict[str, Any]:
    """Shape shared by the local-verification and remote-fallback paths below.

    `created_at` isn't a JWT claim, so it comes from the `profiles` row here
    — NOT from a caller-side fallback. `me.py`'s `_profile_full` calls
    `_profile_public(user)` with no second argument for real (non-demo)
    users, so if this dict didn't carry `created_at` itself, GET /me would
    have no way to recover it at all.
    """
    meta = user_metadata or {}
    app_meta = app_metadata or {}
    return {
        "id": sub,
        "email": email or "",
        "plan": (profile or {}).get("plan") or app_meta.get("plan") or "free",
        "salt": (profile or {}).get("salt") or meta.get("salt"),
        "demo": False,
        "read_only": False,
        "created_at": (profile or {}).get("created_at"),
        "access_token": token,
        "display_name": (profile or {}).get("display_name") or meta.get("display_name") or "",
        "enrolment": (profile or {}).get("enrolment") or meta.get("enrolment") or "",
        "bar_council": (profile or {}).get("bar_council") or meta.get("bar_council") or "",
        "chamber": (profile or {}).get("chamber") or meta.get("chamber") or "",
        "phone": (profile or {}).get("phone") or meta.get("phone") or "",
    }


def _current_user_via_remote_check(sb, token: str) -> dict[str, Any]:
    """Original path: ask Supabase Auth directly. Used only as a fallback
    when local verification itself couldn't be performed (e.g. the JWKS
    endpoint is unreachable) — never for a token that failed verification."""
    try:
        res = sb.auth.get_user(token)
    except Exception as exc:
        raise HTTPException(401, f"invalid token: {exc}") from exc
    user = res.user
    if not user:
        raise HTTPException(401, "invalid token")
    profile = fetch_profile(user.id, token)
    out = _user_from_claims(user.id, user.email, user.user_metadata or {}, user.app_metadata or {}, token, profile)
    # supabase_auth's User.created_at is a datetime, not a string — normalize
    # it here so this stays consistent with the other two paths (JWT claims
    # and the profiles-table row), both of which are always a plain string
    # or None, matching ProfileResponse's declared shape.
    out["created_at"] = user.created_at.isoformat() if user.created_at else None
    return out


def current_user(authorization: Optional[str] = Header(None)) -> dict[str, Any]:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(401, "missing token")
    token = authorization[7:].strip()

    # Showcase demo token — accepted only while MUNSHI_DEMO=1 (mutations blocked in the PWA).
    if token == DEMO_TOKEN and get_settings().demo_open:
        return demo_user(token)

    sb = auth_verification_client()

    try:
        claims_response = sb.auth.get_claims(token)
    except AuthInvalidJwtError as exc:
        # A genuine verification failure (bad signature, expired, malformed,
        # unknown signing key) — this is never valid regardless of who checks
        # it, so reject immediately rather than spending a Supabase round
        # trip confirming what local verification already proved.
        raise HTTPException(401, f"invalid token: {exc}") from exc
    except Exception as exc:
        # Anything else (JWKS endpoint unreachable, unexpected client error)
        # is an *infrastructure* problem, not proof the token is bad — fall
        # back to the original remote check so a transient JWKS/network
        # hiccup doesn't take down every authenticated endpoint.
        log.warning("local JWT verification unavailable, falling back to remote check: %s", exc)
        return _current_user_via_remote_check(sb, token)

    if claims_response is None:
        raise HTTPException(401, "invalid token")

    payload = claims_response["claims"]
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(401, "invalid token")

    profile = fetch_profile(user_id, token)
    return _user_from_claims(user_id, payload.get("email") or "", payload.get("user_metadata") or {}, payload.get("app_metadata") or {}, token, profile)
