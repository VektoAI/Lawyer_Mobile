"""Ciphertext event sync relay.

Push/pull only — this router never decrypts, inspects, or branches on event
contents. That's the whole point: the mobile app stays zero-knowledge to the
server (CLAUDE.md invariant 9) exactly like munshi-ui/vault.js is zero-knowledge
today, just with a server in the loop for durability + multi-device instead of
none at all.
"""
from __future__ import annotations

from fastapi import APIRouter, Query

from app.db import pull_events, push_events
from app.schemas import SyncPullResponse, SyncPushRequest, SyncPushResponse

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushResponse)
def push(body: SyncPushRequest):
    results = push_events(body.chamber_id, body.device_id, [e.model_dump() for e in body.events])
    accepted = sum(1 for r in results if r["status"] == "inserted")
    duplicates = sum(1 for r in results if r["status"] == "duplicate")
    return SyncPushResponse(accepted=accepted, duplicates=duplicates, results=results)


@router.get("/pull", response_model=SyncPullResponse)
def pull(chamber_id: str = Query(...), since: int = Query(0, ge=0)):
    rows, latest_seq = pull_events(chamber_id, since)
    events = [
        {
            "seq": row["seq"],
            "event_id": row["event_id"],
            "device_id": row["device_id"],
            "enc_payload": row["enc_payload"],
            "created_at": row["client_created_at"],
            "received_at": row["received_at"],
        }
        for row in rows
    ]
    return SyncPullResponse(events=events, latest_seq=latest_seq)
