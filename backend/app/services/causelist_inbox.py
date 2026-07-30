"""Filesystem cause-list inbox + cache — public court data only (no lawyer vault).

Layout (under backend/data/, gitignored):
  inbox/           drop HTML here: {court_id}_{YYYY-MM-DD}.html
  inbox/done/      processed files moved here
  causelist_cache/ {court_id}/{list_date}.json parsed rows for sync-hearings

No S3 required. On Render, attach a persistent disk mounted at MUNSHI_DATA_DIR.
"""
from __future__ import annotations

import hashlib
import json
import re
import shutil
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from app.config import get_settings
from app.services.court_lookup import PUBLIC_COURTS, court_by_id, drt_fetch_causelist, ist_today
from app.services.ecourts_parse import parse_causelist_file

_INBOX_NAME = re.compile(r"^(\d+)_(20\d{2}-\d{2}-\d{2})\.(html|htm|txt)$", re.I)


def _ensure_dirs() -> tuple[Path, Path, Path]:
    s = get_settings()
    s.inbox_dir.mkdir(parents=True, exist_ok=True)
    (s.inbox_dir / "done").mkdir(parents=True, exist_ok=True)
    s.causelist_cache_dir.mkdir(parents=True, exist_ok=True)
    return s.inbox_dir, s.inbox_dir / "done", s.causelist_cache_dir


def cache_path(court_id: int, list_date: str) -> Path:
    s = get_settings()
    d = s.causelist_cache_dir / str(court_id)
    d.mkdir(parents=True, exist_ok=True)
    return d / f"{list_date}.json"


def raw_snapshot_path(court_id: int, list_date: str) -> Path:
    s = get_settings()
    d = s.causelist_cache_dir / str(court_id) / "raw"
    d.mkdir(parents=True, exist_ok=True)
    return d / f"{list_date}.json"


def save_raw_snapshot(court_id: int, list_date: str, raw: bytes) -> dict[str, Any]:
    """Persist the raw source bytes *before* parsing (invariant 3).

    Parsers never guess silently: if an adapter's markup changes and parsing
    starts returning zero/garbage rows, this snapshot is the forensic trail
    of exactly what was actually fetched that day, not just what we managed
    to parse out of it. The content hash also becomes the dedup key threaded
    into write_cache() below.
    """
    content_hash = hashlib.sha256(raw).hexdigest()
    path = raw_snapshot_path(court_id, list_date)
    path.write_bytes(raw)
    return {"path": str(path), "dedup_key": content_hash, "bytes": len(raw)}


def write_cache(
    court_id: int,
    list_date: str,
    entries: list[dict[str, Any]],
    *,
    source: str,
    raw_hint: str = "",
    dedup_key: str | None = None,
) -> dict[str, Any]:
    """Overwrite the parsed cache for (court_id, list_date) — idempotent.

    If the newly parsed entries hash identically to what's already cached,
    nothing is written: re-running the same fetch/parse must create nothing
    new (two-run test, invariant 2). Cause lists can legitimately change
    within a day, so this only skips a no-op write; it never skips a fetch.
    """
    content_hash = hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()
    path = cache_path(court_id, list_date)

    existing: dict[str, Any] | None = None
    if path.is_file():
        try:
            existing = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            existing = None
    if existing is not None and existing.get("content_hash") == content_hash:
        return {**existing, "unchanged": True}

    payload = {
        "court_id": court_id,
        "list_date": list_date,
        "source": source,
        "content_hash": content_hash,
        "dedup_key": dedup_key,
        "entry_count": len(entries),
        "entries": entries,
        "cached_at": datetime.now(timezone.utc).isoformat(),
        "raw_hint": raw_hint,
        "unchanged": False,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=0), encoding="utf-8")
    return payload


def load_cache(court_id: int, list_date: str) -> list[dict[str, Any]] | None:
    path = cache_path(court_id, list_date)
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data.get("entries") or []
    except Exception:
        return None


def load_entries_for_dates(court_id: int, dates: list[str]) -> list[tuple[str, list[dict[str, Any]]]]:
    out: list[tuple[str, list[dict[str, Any]]]] = []
    for iso in dates:
        entries = load_cache(court_id, iso)
        if entries:
            out.append((iso, entries))
    return out


def process_inbox_file(path: Path) -> dict[str, Any] | None:
    m = _INBOX_NAME.match(path.name)
    if not m:
        return None
    court_id = int(m.group(1))
    list_date = m.group(2)
    if not court_by_id(court_id):
        return {"ok": False, "file": path.name, "error": f"unknown court_id {court_id}"}
    raw = path.read_bytes()
    entries, src = parse_causelist_file(raw, path.name)
    if not entries:
        return {"ok": False, "file": path.name, "error": "no rows parsed"}
    dedup_key = hashlib.sha256(raw).hexdigest()
    write_cache(
        court_id, list_date, entries,
        source=f"inbox:{src}", raw_hint=path.name, dedup_key=dedup_key,
    )
    inbox, done, _ = _ensure_dirs()
    dest = done / f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S')}_{path.name}"
    shutil.move(str(path), str(dest))
    return {
        "ok": True,
        "file": path.name,
        "court_id": court_id,
        "list_date": list_date,
        "entries": len(entries),
        "moved_to": str(dest.relative_to(inbox.parent)),
    }


def process_inbox() -> dict[str, Any]:
    inbox, _, _ = _ensure_dirs()
    results: list[dict[str, Any]] = []
    for path in sorted(inbox.iterdir()):
        if not path.is_file():
            continue
        if path.name.startswith("."):
            continue
        row = process_inbox_file(path)
        if row:
            results.append(row)
        else:
            results.append({"ok": False, "file": path.name, "error": "name must be {court_id}_{YYYY-MM-DD}.html"})
    return {"ok": True, "processed": results}


def refresh_drt_caches(list_dates: list[str] | None = None) -> list[dict[str, Any]]:
    dates = list_dates or _default_cron_dates()
    out: list[dict[str, Any]] = []
    for court in PUBLIC_COURTS:
        adapter = court.get("adapter") or ""
        if not adapter.startswith("drt:"):
            continue
        city = adapter.split(":", 1)[1]
        for iso in dates:
            try:
                raw, entries = drt_fetch_causelist(city, iso)
                snapshot = save_raw_snapshot(int(court["id"]), iso, raw)
                if not entries:
                    # Empty parse on the one adapter nothing else double-checks —
                    # flag it rather than silently caching an empty cause list
                    # indistinguishable from a genuinely empty one (invariant 4).
                    out.append({
                        "ok": True,
                        "court_id": court["id"],
                        "list_date": iso,
                        "entries": 0,
                        "warning": "parsed zero rows — DRT markup may have changed; raw snapshot saved for inspection",
                        "dedup_key": snapshot["dedup_key"],
                    })
                    continue
                cached = write_cache(
                    int(court["id"]), iso, entries,
                    source="drt.gov.in", raw_hint=city, dedup_key=snapshot["dedup_key"],
                )
                out.append({
                    "ok": True,
                    "court_id": court["id"],
                    "list_date": iso,
                    "entries": len(entries),
                    "dedup_key": snapshot["dedup_key"],
                    "unchanged": cached.get("unchanged", False),
                })
            except Exception as exc:
                out.append({"ok": False, "court_id": court["id"], "list_date": iso, "error": str(exc)})
    return out


def _default_cron_dates() -> list[str]:
    today = ist_today()
    tomorrow = today + timedelta(days=1)
    return [tomorrow.isoformat(), today.isoformat()]


def run_causelist_cron(list_dates: list[str] | None = None) -> dict[str, Any]:
    """Cron entry: inbox HTML → cache; live DRT → cache. No lawyer case rows."""
    inbox_result = process_inbox()
    drt_result = refresh_drt_caches(list_dates)
    return {
        "ok": True,
        "mode": "vault_causelist_cache_only",
        "inbox": inbox_result,
        "drt": drt_result,
        "note": "Caches public cause lists only — client vault unchanged",
    }


def cache_status() -> dict[str, Any]:
    _, _, cache_root = _ensure_dirs()
    courts: list[dict[str, Any]] = []
    for court in PUBLIC_COURTS:
        cid = int(court["id"])
        dates: list[str] = []
        cdir = cache_root / str(cid)
        if cdir.is_dir():
            for f in sorted(cdir.glob("*.json")):
                dates.append(f.stem)
        courts.append({"court_id": cid, "name": court["name"], "cached_dates": dates})
    return {"ok": True, "courts": courts}
