"""Dev-mode SQLite store for the mobile sync relay.

This is a stand-in for the Phase C target (Supabase Postgres + RLS, see
../supabase_migration.sql and ARCHITECTURE.md §12) — not a new architectural
decision. It lets the sync API run and be tested (curl + the two-run
idempotence test, CLAUDE.md invariant 14) without cloud credentials.

Design mirrors backend/db.py: raw sqlite3, a module-level lock, a SCHEMA
string of CREATE TABLE IF NOT EXISTS statements.

The relay never sees plaintext case data (CLAUDE.md invariant 9): `enc_payload`
is an opaque ciphertext blob produced client-side (see
mobile/app/lib/crypto/vault_crypto.dart) — this server only stores and orders
bytes it cannot read, keyed by chamber_id, with dedup_key enforcing
at-least-once + idempotent delivery (invariant 2).
"""
from __future__ import annotations

import sqlite3
import threading
from pathlib import Path
from typing import Any

from app.config import get_settings

_lock = threading.Lock()
_conn: sqlite3.Connection | None = None

SCHEMA = """
CREATE TABLE IF NOT EXISTS sync_events (
  seq INTEGER PRIMARY KEY AUTOINCREMENT,
  chamber_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  dedup_key TEXT NOT NULL UNIQUE,
  device_id TEXT NOT NULL,
  enc_payload TEXT NOT NULL,
  client_created_at TEXT,
  received_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_sync_events_chamber_seq ON sync_events(chamber_id, seq);
"""


def get_conn() -> sqlite3.Connection:
    global _conn
    if _conn is None:
        db_path: Path = get_settings().db_path
        db_path.parent.mkdir(parents=True, exist_ok=True)
        _conn = sqlite3.connect(db_path, check_same_thread=False)
        _conn.row_factory = sqlite3.Row
        with _lock:
            _conn.executescript(SCHEMA)
            _conn.commit()
    return _conn


def push_events(chamber_id: str, device_id: str, events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Insert each event idempotently on dedup_key. Safe to call twice with
    the same events — the second call is a no-op per event (invariant 2)."""
    conn = get_conn()
    results: list[dict[str, Any]] = []
    with _lock:
        for event in events:
            cur = conn.execute(
                """
                INSERT OR IGNORE INTO sync_events
                    (chamber_id, event_id, dedup_key, device_id, enc_payload, client_created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    chamber_id,
                    event["event_id"],
                    event["dedup_key"],
                    device_id,
                    event["enc_payload"],
                    event.get("created_at"),
                ),
            )
            if cur.rowcount == 1:
                results.append({"event_id": event["event_id"], "seq": cur.lastrowid, "status": "inserted"})
            else:
                row = conn.execute(
                    "SELECT seq FROM sync_events WHERE dedup_key = ?", (event["dedup_key"],)
                ).fetchone()
                results.append({"event_id": event["event_id"], "seq": row["seq"], "status": "duplicate"})
        conn.commit()
    return results


def pull_events(chamber_id: str, since_seq: int) -> tuple[list[sqlite3.Row], int]:
    conn = get_conn()
    rows = conn.execute(
        """
        SELECT seq, event_id, device_id, enc_payload, client_created_at, received_at
        FROM sync_events
        WHERE chamber_id = ? AND seq > ?
        ORDER BY seq ASC
        """,
        (chamber_id, since_seq),
    ).fetchall()
    latest = conn.execute(
        "SELECT COALESCE(MAX(seq), 0) AS latest FROM sync_events WHERE chamber_id = ?",
        (chamber_id,),
    ).fetchone()["latest"]
    return rows, latest
