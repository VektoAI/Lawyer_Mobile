# Munshi mobile sync relay

Standalone FastAPI service — **not** the same process as `../../backend/app/main.py`
(which keeps serving the PWA + auth/billing). This one exists only to push/pull
ciphertext events for the Flutter app. See `../README.md` and
[ARCHITECTURE.md §12](../../ARCHITECTURE.md) for why it's separate and what it's
a first slice of.

**What it stores:** opaque ciphertext (`enc_payload`) keyed by `chamber_id`,
`event_id`, and a unique `dedup_key`. It never decrypts, parses, or logs
payload contents — that's the zero-knowledge property carried over from
`munshi-ui/vault.js` (CLAUDE.md invariant 9).

**What it's built on today:** local SQLite (`app/db.py`) — a stand-in for the
Phase C target of Supabase Postgres + RLS (`supabase_migration.sql`, not
applied anywhere). Swapping the storage backend later is additive; the schema
already matches 1:1.

## Run

```powershell
cd mobile/backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8090 --reload
```

| URL | What |
|---|---|
| http://127.0.0.1:8090/health | Health |
| http://127.0.0.1:8090/api/docs | Swagger |

## Verify (curl)

```powershell
curl http://127.0.0.1:8090/health

curl -X POST http://127.0.0.1:8090/sync/push -H "Content-Type: application/json" -d '{
  "chamber_id": "demo-chamber",
  "device_id": "demo-device-1",
  "events": [{"event_id": "11111111-1111-1111-1111-111111111111", "dedup_key": "demo-dedup-1", "enc_payload": "base64ciphertexthere"}]
}'
```

Run the exact same `POST /sync/push` a second time — the response should show
`"status": "duplicate"` for that event and `accepted: 0` (CLAUDE.md invariant 2:
every ingestion-style stage must pass the two-run test).

```powershell
curl "http://127.0.0.1:8090/sync/pull?chamber_id=demo-chamber&since=0"
```

Should return exactly one event, regardless of how many times `/sync/push` was
retried with the same `dedup_key`.

## Not done here (by design — see ../../.claude/plans or ARCHITECTURE.md §12)

- No auth — `chamber_id`/`device_id` are trusted as given. Phase C needs real
  Supabase-authenticated chamber scoping before this touches real data.
- No Supabase wiring — `supabase_migration.sql` is a target schema, not applied.
- No Realtime push to other devices — pull is poll-based (`since=<seq>`) today.
