"""Inbox + cache cron (no lawyer vault storage).

Covers the CLAUDE.md two-run idempotence test: run ingestion twice, the
second run must create nothing new. That property is checked directly here,
not just asserted by a test name — see test_write_cache_two_run_is_idempotent
and test_refresh_drt_caches_two_run_is_idempotent.
"""
from __future__ import annotations

import json
import time
from pathlib import Path

import pytest

from app.config import get_settings
from app.services import causelist_inbox as inbox_mod
from app.services.causelist_cache_lookup import lookup_case_in_cache
from app.services.causelist_inbox import (
    process_inbox,
    process_inbox_file,
    refresh_drt_caches,
    save_raw_snapshot,
    write_cache,
)


@pytest.fixture
def data_dirs(tmp_path, monkeypatch):
    monkeypatch.setenv("MUNSHI_DATA_DIR", str(tmp_path))
    get_settings.cache_clear()
    yield tmp_path
    get_settings.cache_clear()


def test_inbox_file_to_cache(data_dirs):
    inbox = get_settings().inbox_dir
    inbox.mkdir(parents=True, exist_ok=True)
    html = b"<html><table><tr><td>1</td><td>CS 9/2024</td><td>A vs B</td></tr></table></html>"
    f = inbox / "2_2026-08-01.html"
    f.write_bytes(html)
    result = process_inbox_file(f)
    assert result["ok"] is True
    assert result["entries"] == 1
    hit = lookup_case_in_cache(2, "CS 9/2024", ["2026-08-01"])
    assert hit["found"] is True
    assert hit["next_date"] == "2026-08-01"


def test_process_inbox_two_run_is_idempotent(data_dirs):
    """Run the same inbox drop through process_inbox() twice — the file is
    moved to done/ after the first run, so the second run must process
    nothing new (CLAUDE.md's two-run test, at the cron-entry level)."""
    inbox = get_settings().inbox_dir
    inbox.mkdir(parents=True, exist_ok=True)
    html = b"<html><table><tr><td>1</td><td>CS 9/2024</td><td>A vs B</td></tr></table></html>"
    (inbox / "2_2026-08-01.html").write_bytes(html)

    first = process_inbox()
    assert len(first["processed"]) == 1
    assert first["processed"][0]["ok"] is True

    second = process_inbox()
    assert second["processed"] == []  # nothing new — the file is already in done/


def test_write_cache_two_run_is_idempotent(data_dirs):
    entries = [{"case_ref": "OA 1/2020", "item_no": "1", "bench": "C1", "parties": "X vs Y"}]

    first = write_cache(7, "2026-08-02", entries, source="test", dedup_key="hash-1")
    assert first["unchanged"] is False
    path = get_settings().causelist_cache_dir / "7" / "2026-08-02.json"
    assert path.is_file()
    first_mtime = path.stat().st_mtime_ns

    time.sleep(0.01)
    second = write_cache(7, "2026-08-02", entries, source="test", dedup_key="hash-1")
    assert second["unchanged"] is True  # identical entries — nothing new written
    assert path.stat().st_mtime_ns == first_mtime  # file was not touched again

    data = json.loads(path.read_text())
    assert data["entry_count"] == 1
    assert data["dedup_key"] == "hash-1"


def test_save_raw_snapshot_dedup_key_is_stable(data_dirs):
    """Same raw bytes -> same dedup key, every time (invariant 3)."""
    raw = b'{"source":"drt.gov.in","city":"Dehradun","courts":[]}'
    first = save_raw_snapshot(7, "2026-08-03", raw)
    second = save_raw_snapshot(7, "2026-08-03", raw)
    assert first["dedup_key"] == second["dedup_key"]
    assert raw_snapshot_bytes(7, "2026-08-03") == raw


def raw_snapshot_bytes(court_id: int, list_date: str) -> bytes:
    return inbox_mod.raw_snapshot_path(court_id, list_date).read_bytes()


def test_refresh_drt_caches_two_run_is_idempotent(data_dirs, monkeypatch):
    """Re-fetching identical upstream DRT data twice must not duplicate or
    grow the cache — proves the dedup_key/unchanged mechanism end to end."""
    entries = [{"case_ref": "OA 1/2020", "item_no": "1", "bench": "C1", "parties": "X vs Y"}]
    raw = b'{"source":"drt.gov.in"}'
    monkeypatch.setattr(inbox_mod, "drt_fetch_causelist", lambda city, iso: (raw, entries))

    first = refresh_drt_caches(["2026-08-04"])
    drt_courts = [r for r in first if r["list_date"] == "2026-08-04"]
    assert all(r["ok"] for r in drt_courts)
    assert all(r.get("unchanged") is False for r in drt_courts)

    second = refresh_drt_caches(["2026-08-04"])
    drt_courts_2 = [r for r in second if r["list_date"] == "2026-08-04"]
    assert all(r["ok"] for r in drt_courts_2)
    assert all(r.get("unchanged") is True for r in drt_courts_2)
    # Same raw bytes in both runs -> same dedup key both times.
    assert {r["dedup_key"] for r in drt_courts} == {r["dedup_key"] for r in drt_courts_2}


def test_refresh_drt_caches_flags_empty_parse(data_dirs, monkeypatch):
    """An adapter that parses zero rows must say so, not cache a silent empty
    list indistinguishable from a genuinely empty cause list (invariant 4)."""
    monkeypatch.setattr(inbox_mod, "drt_fetch_causelist", lambda city, iso: (b"<html></html>", []))
    result = refresh_drt_caches(["2026-08-05"])
    assert result  # at least one live DRT court configured
    assert all(r["entries"] == 0 for r in result)
    assert all("warning" in r for r in result)
