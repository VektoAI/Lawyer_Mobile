"""Account / subscription / chamber profile — no case columns."""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException

from app.deps import current_user
from app.schemas import ProfileUpdateBody
from app.supabase_client import fetch_profile, update_profile_fields

router = APIRouter(tags=["account"])


def _normalize_phone(raw: str) -> str:
    digits = "".join(ch for ch in (raw or "") if ch.isdigit())
    if len(digits) == 10:
        return "+91" + digits
    if len(digits) == 12 and digits.startswith("91"):
        return "+" + digits
    if len(digits) >= 10:
        return "+" + digits[-12:] if len(digits) > 12 else "+" + digits
    return raw.strip()


def _profile_public(user: dict[str, Any], profile: dict | None = None) -> dict[str, Any]:
    p = profile or {}
    return {
        "id": user["id"],
        "email": user["email"],
        "plan": user.get("plan") or p.get("plan") or "free",
        "salt": user.get("salt") or p.get("salt"),
        "created_at": user.get("created_at") or p.get("created_at"),
        "demo": bool(user.get("demo")),
        "read_only": bool(user.get("read_only") or user.get("demo")),
        "display_name": p.get("display_name") or user.get("display_name") or "",
        "enrolment": p.get("enrolment") or user.get("enrolment") or "",
        "bar_council": p.get("bar_council") or user.get("bar_council") or "",
        "chamber": p.get("chamber") or user.get("chamber") or "",
        "phone": p.get("phone") or user.get("phone") or "",
    }


def _profile_full(user: dict[str, Any]) -> dict[str, Any]:
    if user.get("demo"):
        return _profile_public(user, {
            "display_name": "Adv. Priyanshu Jain",
            "enrolment": "UK/1234/2015",
            "bar_council": "Bar Council of Uttarakhand",
            "chamber": "Chamber 14, District Court Complex, Dehradun",
            "plan": "pilot",
        })
    return _profile_public(user)


@router.get("/me")
def me(user: dict[str, Any] = Depends(current_user)):
    return {"ok": True, **_profile_full(user)}


@router.get("/me/subscription")
def me_subscription(user: dict[str, Any] = Depends(current_user)):
    """Narrower than /me — just the fields a billing UI needs, not the full profile."""
    profile = _profile_full(user)
    return {
        "ok": True,
        "plan": profile["plan"],
        "demo": profile["demo"],
        "read_only": profile["read_only"],
    }


@router.patch("/me/profile")
def patch_profile(body: ProfileUpdateBody, user: dict[str, Any] = Depends(current_user)):
    """Save chamber identity to Supabase profiles (not case data)."""
    if user.get("demo"):
        raise HTTPException(403, "Demo is view-only — create an account to edit profile")

    token = user.get("access_token")
    if not token:
        raise HTTPException(401, "missing token")

    fields = {}
    if body.display_name is not None:
        fields["display_name"] = body.display_name.strip()
    if body.enrolment is not None:
        fields["enrolment"] = body.enrolment.strip()
    if body.bar_council is not None:
        fields["bar_council"] = body.bar_council.strip()
    if body.chamber is not None:
        fields["chamber"] = body.chamber.strip()
    if body.phone is not None:
        fields["phone"] = _normalize_phone(body.phone)
    if not fields:
        raise HTTPException(400, "no profile fields to update")

    try:
        row = update_profile_fields(
            user["id"],
            fields,
            token,
            email=user.get("email") or "",
            salt=user.get("salt") or "",
        )
    except RuntimeError as exc:
        raise HTTPException(500, str(exc)) from exc
    return {"ok": True, **_profile_public({**user, **fields}, row)}
