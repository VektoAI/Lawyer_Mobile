"""FastAPI dependencies — Bearer JWT → account (never case data)."""
from __future__ import annotations

from typing import Any, Optional

from fastapi import Header, HTTPException

from app.config import get_settings
from app.supabase_client import fetch_profile, supabase_client

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


def current_user(authorization: Optional[str] = Header(None)) -> dict[str, Any]:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(401, "missing token")
    token = authorization[7:].strip()

    # Showcase demo token — accepted only while MUNSHI_DEMO=1 (mutations blocked in the PWA).
    if token == DEMO_TOKEN and get_settings().demo_open:
        return demo_user(token)

    sb = supabase_client()
    try:
        res = sb.auth.get_user(token)
    except Exception as exc:
        raise HTTPException(401, f"invalid token: {exc}") from exc
    user = res.user
    if not user:
        raise HTTPException(401, "invalid token")
    profile = fetch_profile(user.id, token)
    meta = user.user_metadata or {}
    return {
        "id": user.id,
        "email": user.email or "",
        "plan": (profile or {}).get("plan") or (user.app_metadata or {}).get("plan") or "free",
        "salt": (profile or {}).get("salt") or meta.get("salt"),
        "demo": False,
        "read_only": False,
        "created_at": user.created_at,
        "access_token": token,
        "display_name": (profile or {}).get("display_name") or meta.get("display_name") or "",
        "enrolment": (profile or {}).get("enrolment") or meta.get("enrolment") or "",
        "bar_council": (profile or {}).get("bar_council") or meta.get("bar_council") or "",
        "chamber": (profile or {}).get("chamber") or meta.get("chamber") or "",
        "phone": (profile or {}).get("phone") or meta.get("phone") or "",
    }
