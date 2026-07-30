"""Live court adapters — shared with legacy ingest.py (stage-0 pipeline).

Case lookup for add-case flow: pull cause list, match case number, return
metadata only (never stored on server — vault mode invariant 9).
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

import requests

from app.services.court_ref import norm_ref

DRT_API = "https://drt.gov.in/drtapi"
IST = ZoneInfo("Asia/Kolkata")
_drt_scheme_cache: dict[str, str] = {}


def ist_today():
    """Today's date in IST — never the host's local/UTC clock.

    Court cause lists are published on IST calendar days; a naive
    date.today() on a UTC-clocked host (typical on Render) is a full day
    behind IST for the ~05:30 hours after UTC midnight, which is exactly
    when a lawyer's morning digest gets built.
    """
    return datetime.now(IST).date()


def _form(**kw: Any) -> dict:
    return {k: (None, str(v)) for k, v in kw.items()}


def _ddmmyyyy(iso: str) -> str:
    y, m, d = iso.split("-")
    return f"{d}/{m}/{y}"


def _parse_drt_html(html: str, bench: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    section = ""
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S):
        cells = [re.sub(r"<[^>]+>|&nbsp;?", " ", c) for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.S)]
        cells = [re.sub(r"\s+", " ", c).strip() for c in cells]
        if len(cells) >= 3 and not cells[0] and not cells[1] and cells[2]:
            head = cells[2]
            if head.isupper() and "TRIBUNAL" not in head and "HON" not in head and len(head) < 60:
                section = head.title()
        if len(cells) >= 3 and cells[0].isdigit() and cells[1]:
            entries.append(
                {
                    "case_ref": cells[1].split(" IN ")[0].strip(),
                    "item_no": cells[0],
                    "bench": bench,
                    "stage": section,
                    "parties": cells[2],
                    "advocate": (cells[3] if len(cells) > 3 else "").strip(" -"),
                }
            )
    return entries


def drt_fetch_causelist(city_key: str, list_date_iso: str) -> tuple[bytes, list[dict[str, Any]]]:
    """Port of backend/ingest.py drt_fetch."""
    ddmm = _ddmmyyyy(list_date_iso)
    if city_key not in _drt_scheme_cache:
        r = requests.post(f"{DRT_API}/getDrtDratScheamName", json={}, timeout=20)
        r.raise_for_status()
        for it in r.json():
            if city_key.lower() in it.get("SchemaName", "").lower():
                _drt_scheme_cache[city_key] = it["schemeNameDrtId"]
                break
        else:
            raise RuntimeError(f"no DRT location matches '{city_key}'")
    sid = _drt_scheme_cache[city_key]

    courts = requests.post(
        f"{DRT_API}/getCourtName",
        files=_form(schemeNameDrtId=sid, listingDate=ddmm),
        timeout=20,
    ).json()
    raw_courts: list[dict] = []
    entries: list[dict[str, Any]] = []
    for c in courts if isinstance(courts, list) else []:
        cid, judge = c.get("courtNameId"), c.get("judgeName", "")
        if not cid:
            continue
        r = requests.post(
            f"{DRT_API}/getDrtDratCourtNo",
            files=_form(schemeNameDrtId=sid, listingDate=ddmm, courtNameId=cid),
            timeout=20,
        )
        m = re.search(r'courtNo":"([^"]+)"', r.text)
        cno = m.group(1) if m else "1"
        r = requests.post(
            f"{DRT_API}/getDrtCauselistReport",
            files=_form(schemeNameDrtId=sid, causeListDate=ddmm, courtNameId=cid, courtNo=cno),
            timeout=20,
        )
        m = re.search(r'dailyCauseListLink":"([^"]+)"', r.text)
        if not m:
            continue
        html = requests.get(m.group(1), timeout=30).text
        raw_courts.append({"judge": judge, "courtNo": cno, "link": m.group(1), "html": html[:500]})
        entries.extend(_parse_drt_html(html, f"Court {cno} · {judge}"))
    raw = json.dumps(
        {"source": "drt.gov.in", "city": city_key, "date": list_date_iso, "courts": raw_courts},
        ensure_ascii=False,
    ).encode()
    return raw, entries


def _unverified_or_not_found(list_dates: list[str], errors: list[str]) -> dict[str, Any]:
    """Build the 'no match' result honestly — never say "not listed" when we couldn't check.

    If every date lookup errored out, we never actually saw a real cause list, so the
    only honest answer is "could not verify" — not "not on cause list" (invariant 4:
    a digest/status must never silently convert a failed source into a false negative).
    """
    if errors and len(errors) >= len(list_dates):
        return {
            "found": False,
            "verified": False,
            "source": "drt.gov.in",
            "reason": "could not verify — drt.gov.in did not respond for any checked date",
            "checked_dates": list_dates,
            "errors": errors,
        }
    reason = "not on cause list for checked dates"
    if errors:
        reason += " (some dates could not be checked — see errors)"
    return {
        "found": False,
        "verified": True,
        "source": "drt.gov.in",
        "reason": reason,
        "checked_dates": list_dates,
        "errors": errors or None,
    }


def lookup_case_in_drt(city_key: str, case_no: str, list_dates: list[str]) -> dict[str, Any]:
    """Search DRT cause lists for case_no on given ISO dates (first hit wins)."""
    target = norm_ref(case_no)
    if not target:
        return {"found": False, "reason": "empty case number"}

    errors: list[str] = []
    for iso in list_dates:
        try:
            _, entries = drt_fetch_causelist(city_key, iso)
        except Exception as exc:
            errors.append(f"{iso}: {exc}")
            continue
        for e in entries:
            if norm_ref(e["case_ref"]) == target or target in norm_ref(e["case_ref"]):
                detail = f"{e.get('bench', 'Court')} · Item {e.get('item_no', '?')}"
                if e.get("stage"):
                    detail += f" · {e['stage']}"
                return {
                    "found": True,
                    "verified": True,
                    "source": "drt.gov.in",
                    "list_date": iso,
                    "case_no": e["case_ref"],
                    "parties": e.get("parties") or "",
                    "stage": e.get("stage") or "Listed",
                    "next_date": iso,
                    "next_detail": detail,
                    "court_type": "drt",
                }
    return _unverified_or_not_found(list_dates, errors)


# Mirrors munshi-ui/vault.js COURTS + ingest adapters.
PUBLIC_COURTS: list[dict[str, Any]] = [
    {"id": 1, "name": "DRT Allahabad", "type": "drt", "adapter": "drt:Allahabad", "live": True},
    {"id": 2, "name": "District & Sessions Court, Dehradun", "type": "district", "adapter": "ecourts_manual:dehradun_district", "live": False, "ingest": "upload_or_scrape"},
    {"id": 3, "name": "Family Court, Dehradun", "type": "district", "adapter": "ecourts_manual:dehradun_family", "live": False, "ingest": "upload_or_scrape"},
    {"id": 4, "name": "High Court of Uttarakhand, Nainital", "type": "hc", "adapter": "hc_manual:ukhc", "live": False, "ingest": "upload_pdf"},
    {"id": 5, "name": "Civil Judge (SD), Dehradun", "type": "district", "adapter": "ecourts_manual:dehradun_civil", "live": False, "ingest": "upload_or_scrape"},
    {"id": 6, "name": "MACT, Dehradun", "type": "tribunal", "adapter": "ecourts_manual:dehradun_mact", "live": False, "ingest": "upload_or_scrape"},
    {"id": 7, "name": "DRT Dehradun", "type": "drt", "adapter": "drt:Dehradun", "live": True},
]


def court_by_id(court_id: int) -> dict[str, Any] | None:
    for c in PUBLIC_COURTS:
        if c["id"] == court_id:
            return c
    return None


def default_lookup_dates(preferred: str | None = None) -> list[str]:
    today = ist_today()
    candidates = []
    if preferred:
        candidates.append(preferred)
    candidates.append((today + timedelta(days=1)).isoformat())
    candidates.append(today.isoformat())
    out: list[str] = []
    for d in candidates:
        if d and d not in out:
            out.append(d)
    return out


def automation_lookup_dates() -> list[str]:
    """Next ~14 calendar days — used for automated hearing refresh (polite, bounded)."""
    today = ist_today()
    out: list[str] = []
    for i in range(0, 15):
        d = (today + timedelta(days=i)).isoformat()
        if d not in out:
            out.append(d)
    return out


def _advocate_tokens(name: str) -> list[str]:
    raw = re.sub(r"(?i)^adv\.?\s*", "", (name or "").strip())
    parts = [p for p in re.split(r"\s+", raw) if len(p) >= 3]
    return [p.upper() for p in parts[:4]]


def advocate_matches(advocate_field: str, advocate_hint: str) -> bool:
    tokens = _advocate_tokens(advocate_hint)
    if not tokens:
        return False
    hay = (advocate_field or "").upper()
    return sum(1 for t in tokens if t in hay) >= (1 if len(tokens) == 1 else min(2, len(tokens)))


def lookup_case_in_drt_cached(
    city_key: str,
    case_no: str,
    list_dates: list[str],
    cache: dict[tuple[str, str], list[dict[str, Any]]],
) -> dict[str, Any]:
    target = norm_ref(case_no)
    if not target:
        return {"found": False, "reason": "empty case number"}
    errors: list[str] = []
    for iso in list_dates:
        key = (city_key, iso)
        try:
            if key not in cache:
                _, entries = drt_fetch_causelist(city_key, iso)
                cache[key] = entries
            entries = cache[key]
        except Exception as exc:
            errors.append(f"{iso}: {exc}")
            continue
        for e in entries:
            if norm_ref(e["case_ref"]) == target or target in norm_ref(e["case_ref"]):
                detail = f"{e.get('bench', 'Court')} · Item {e.get('item_no', '?')}"
                if e.get("stage"):
                    detail += f" · {e['stage']}"
                return {
                    "found": True,
                    "verified": True,
                    "source": "drt.gov.in",
                    "list_date": iso,
                    "case_no": e["case_ref"],
                    "parties": e.get("parties") or "",
                    "stage": e.get("stage") or "Listed",
                    "next_date": iso,
                    "next_detail": detail,
                    "court_type": "drt",
                }
    return _unverified_or_not_found(list_dates, errors)


def scan_drt_for_advocate(
    city_key: str,
    advocate_hint: str,
    list_dates: list[str],
    cache: dict[tuple[str, str], list[dict[str, Any]]],
) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    seen: set[str] = set()
    for iso in list_dates:
        key = (city_key, iso)
        try:
            if key not in cache:
                _, entries = drt_fetch_causelist(city_key, iso)
                cache[key] = entries
            entries = cache[key]
        except Exception:
            continue
        for e in entries:
            if not advocate_matches(e.get("advocate") or "", advocate_hint):
                continue
            ref = norm_ref(e["case_ref"])
            if ref in seen:
                continue
            seen.add(ref)
            detail = f"{e.get('bench', 'Court')} · Item {e.get('item_no', '?')}"
            hits.append(
                {
                    "case_no": e["case_ref"],
                    "parties": e.get("parties") or "",
                    "list_date": iso,
                    "next_date": iso,
                    "next_detail": detail,
                    "stage": e.get("stage") or "Listed",
                    "advocate": e.get("advocate") or "",
                }
            )
    return hits


def sync_hearings(
    cases: list[dict[str, Any]],
    advocate_name: str | None = None,
    scan_court_ids: list[int] | None = None,
) -> dict[str, Any]:
    """Batch refresh + optional advocate causelist scan (metadata only)."""
    dates = automation_lookup_dates()
    cache: dict[tuple[str, str], list[dict[str, Any]]] = {}
    updates: list[dict[str, Any]] = []
    warnings: list[str] = []

    for item in cases:
        court_id = int(item["court_id"])
        case_no = str(item["case_no"]).strip()
        client_case_id = str(item["client_case_id"])
        court = court_by_id(court_id)
        row: dict[str, Any] = {
            "client_case_id": client_case_id,
            "court_id": court_id,
            "case_no": case_no,
            "found": False,
        }
        if not court:
            row["reason"] = "unknown court"
            updates.append(row)
            continue
        adapter = court.get("adapter") or "demo"
        if not adapter.startswith("drt:"):
            if adapter.startswith("ecourts_manual") or adapter.startswith("hc_manual"):
                from app.services.causelist_cache_lookup import lookup_case_in_cache

                hit = lookup_case_in_cache(court_id, case_no, dates)
                row.update(hit)
                row["court"] = court["name"]
                if not hit.get("found"):
                    row["warning"] = hit.get("reason")
            else:
                row["reason"] = court.get("name", "") + ": live auto-sync not wired yet"
                row["court"] = court["name"]
            updates.append(row)
            continue
        city = adapter.split(":", 1)[1]
        hit = lookup_case_in_drt_cached(city, case_no, dates, cache)
        row.update(hit)
        row["court"] = court["name"]
        if hit.get("errors"):
            warnings.append(f"{case_no}: " + "; ".join(hit["errors"][:2]))
        updates.append(row)

    discovered: list[dict[str, Any]] = []
    if advocate_name and advocate_name.strip():
        scan_ids = scan_court_ids or [c["id"] for c in PUBLIC_COURTS if c.get("live")]
        for cid in scan_ids[:5]:
            court = court_by_id(int(cid))
            if not court:
                continue
            adapter = court.get("adapter") or ""
            if not adapter.startswith("drt:"):
                continue
            city = adapter.split(":", 1)[1]
            for hit in scan_drt_for_advocate(city, advocate_name, dates[:7], cache):
                hit["court_id"] = court["id"]
                hit["court"] = court["name"]
                discovered.append(hit)

    return {
        "ok": True,
        "updates": updates,
        "discovered": discovered,
        "checked_dates": dates[:7],
        "warnings": warnings or None,
    }


def court_id_for_name(court_name: str) -> int | None:
    n = (court_name or "").strip().lower()
    for c in PUBLIC_COURTS:
        if c["name"].strip().lower() == n:
            return int(c["id"])
    return None


def lookup_case(court_id: int, case_no: str, list_date: str | None = None) -> dict[str, Any]:
    court = court_by_id(court_id)
    if not court:
        return {"found": False, "reason": "unknown court_id"}

    adapter = court.get("adapter") or "demo"
    dates = default_lookup_dates(list_date)

    if adapter.startswith("drt:"):
        city = adapter.split(":", 1)[1]
        result = lookup_case_in_drt(city, case_no, dates)
        result["court"] = court["name"]
        result["court_id"] = court_id
        return result

    if adapter.startswith("ecourts_manual") or adapter.startswith("hc_manual"):
        from app.services.causelist_cache_lookup import lookup_case_in_cache

        result = lookup_case_in_cache(court_id, case_no, dates)
        result["court"] = court["name"]
        result["court_id"] = court_id
        return result

    return {
        "found": False,
        "court": court["name"],
        "court_id": court_id,
        "reason": "live lookup not wired for this court yet — save manually; causelist adapters are ROADMAP 1.x",
        "checked_dates": dates,
    }
