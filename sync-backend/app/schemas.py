"""Pydantic models for the ciphertext event envelope.

`enc_payload` is treated as an opaque base64 string end to end — this service
never parses, validates, or logs its contents. Encryption/decryption happens
only on the Flutter device (mobile/app/lib/crypto/vault_crypto.dart), mirroring
munshi-ui/vault.js's AES-GCM scheme.
"""
from __future__ import annotations

from pydantic import BaseModel, Field


class SyncEventIn(BaseModel):
    event_id: str = Field(..., description="Client-generated UUID for this event")
    dedup_key: str = Field(..., description="Unique key — retrying the same push is a no-op")
    enc_payload: str = Field(..., description="Opaque ciphertext blob (base64), server cannot read it")
    created_at: str | None = Field(None, description="Client-side timestamp, informational only")


class SyncPushRequest(BaseModel):
    chamber_id: str
    device_id: str
    events: list[SyncEventIn]


class SyncEventResult(BaseModel):
    event_id: str
    seq: int
    status: str  # "inserted" | "duplicate"


class SyncPushResponse(BaseModel):
    accepted: int
    duplicates: int
    results: list[SyncEventResult]


class SyncEventOut(BaseModel):
    seq: int
    event_id: str
    device_id: str
    enc_payload: str
    created_at: str | None
    received_at: str


class SyncPullResponse(BaseModel):
    events: list[SyncEventOut]
    latest_seq: int
