"""Stripe billing webhook — updates profiles.plan only."""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException, Request

from app.config import get_settings
from app.schemas import StripeWebhookResponse
from app.supabase_client import supabase_client

router = APIRouter(tags=["billing"])


@router.post("/stripe/webhook", response_model=StripeWebhookResponse)
async def stripe_webhook(request: Request):
    """Stripe → update profiles.plan only. No case fields exist to touch."""
    settings = get_settings()
    payload = await request.body()
    sig = request.headers.get("stripe-signature", "")

    if not settings.stripe_webhook_secret:
        # Never process an unsigned webhook body — a forged event could flip anyone's
        # plan to paid. Fail closed until STRIPE_WEBHOOK_SECRET is configured.
        raise HTTPException(503, "STRIPE_WEBHOOK_SECRET is not configured on this server")

    try:
        import stripe
        event: dict[str, Any] = stripe.Webhook.construct_event(payload, sig, settings.stripe_webhook_secret)
    except Exception as exc:
        raise HTTPException(400, f"webhook signature failed: {exc}") from exc

    etype = event.get("type") if isinstance(event, dict) else getattr(event, "type", None)
    data_obj = event.get("data", {}).get("object", {}) if isinstance(event, dict) else {}

    plan = None
    user_id = None
    if etype in ("customer.subscription.updated", "customer.subscription.created"):
        status = data_obj.get("status")
        meta = data_obj.get("metadata") or {}
        user_id = meta.get("supabase_user_id") or meta.get("user_id")
        plan = "active" if status in ("active", "trialing") else "free"
    elif etype == "customer.subscription.deleted":
        meta = data_obj.get("metadata") or {}
        user_id = meta.get("supabase_user_id") or meta.get("user_id")
        plan = "free"

    if user_id and plan and settings.supabase_service_role_key:
        try:
            supabase_client(service=True).table("profiles").update({"plan": plan}).eq("id", user_id).execute()
        except Exception as exc:
            raise HTTPException(500, f"plan update failed: {exc}") from exc

    return {"ok": True, "received": True, "type": etype, "updated": bool(user_id and plan)}
