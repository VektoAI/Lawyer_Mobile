-- Phase C target schema (docs/Munshi_Scale_Up_Architecture.html §05/§06).
-- NOT applied automatically — this is a design artifact for the founder to run
-- in the Supabase SQL editor when Phase C actually starts, same convention as
-- backend/profiles_schema.sql. Nothing in this file has been executed against
-- any live project.
--
-- Mirrors mobile/backend/app/db.py's sqlite dev schema 1:1 so the swap from
-- SQLite to Supabase Postgres is additive, not a rewrite (ROADMAP.md 3.1
-- precedent: "schema ports 1:1").
--
-- `enc_payload` is bytea ciphertext — Postgres/Supabase never holds a key that
-- can decrypt it (CLAUDE.md invariant 9). RLS isolates each chamber's rows;
-- exactly which auth claim maps to chamber_id depends on how chambers/lawyers
-- get modeled in Supabase, which is a Phase C design decision, not made here.

create table if not exists sync_events (
  seq          bigint generated always as identity primary key,
  chamber_id   uuid not null,
  event_id     uuid not null,
  dedup_key    text not null unique,
  device_id    text not null,
  enc_payload  bytea not null,
  client_created_at timestamptz,
  received_at  timestamptz not null default now()
);

create index if not exists idx_sync_events_chamber_seq on sync_events (chamber_id, seq);

alter table sync_events enable row level security;

-- Placeholder policy — tighten once chamber membership has a concrete
-- Supabase-side representation (e.g. a chamber_members table keyed by auth.uid()).
-- create policy sync_events_chamber_isolation on sync_events
--   using (chamber_id = current_setting('request.jwt.claims.chamber_id')::uuid);
