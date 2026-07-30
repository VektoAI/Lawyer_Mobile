"""Parse cause lists lawyers download from eCourts / district portals (HTML or text).

We do not scrape captcha-gated CNR search here — clerks export or "Save as"
cause-list HTML; this parser turns that file into the same entry shape as DRT.
"""
from __future__ import annotations

import re
from typing import Any

from app.services.court_lookup import advocate_matches
from app.services.court_ref import norm_ref

_CNR_RE = re.compile(r"\b([A-Z]{2}[A-Z0-9]{14})\b", re.I)


def _strip_html(html: str) -> str:
    text = re.sub(r"(?i)<br\s*/?>", "\n", html)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"&nbsp;?", " ", text)
    return re.sub(r"[ \t]+", " ", text)


def _parse_html_table(html: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    bench = "Court"
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S | re.I):
        cells = [
            re.sub(r"\s+", " ", re.sub(r"<[^>]+>|&nbsp;?", " ", c)).strip()
            for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.S | re.I)
        ]
        if not cells:
            continue
        joined = " | ".join(cells).upper()
        if "CAUSE LIST" in joined or "COURT NO" in joined:
            continue
        item_no = ""
        case_ref = ""
        parties = ""
        advocate = ""
        if cells[0].isdigit() and len(cells) >= 2:
            item_no = cells[0]
            case_ref = cells[1]
            parties = cells[2] if len(cells) > 2 else ""
            advocate = cells[3] if len(cells) > 3 else ""
        else:
            for c in cells:
                m = _CNR_RE.search(c)
                if m and not case_ref:
                    case_ref = m.group(1).upper()
                elif re.search(r"\d+/\d{4}", c) and not case_ref:
                    case_ref = c.strip()
            if not case_ref:
                continue
            parties = cells[-2] if len(cells) >= 2 else ""
            advocate = cells[-1] if len(cells) >= 3 else ""
        case_ref = case_ref.split(" IN ")[0].strip()
        if not case_ref:
            continue
        entries.append(
            {
                "case_ref": case_ref,
                "item_no": item_no or "?",
                "bench": bench,
                "stage": "",
                "parties": parties,
                "advocate": advocate,
            }
        )
    return entries


def _parse_plaintext(text: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for line in text.splitlines():
        line = line.strip()
        if len(line) < 8:
            continue
        cnr = _CNR_RE.search(line)
        case_ref = cnr.group(1).upper() if cnr else ""
        if not case_ref:
            m = re.search(r"([A-Z]{2,}\s*\d+\s*/\s*\d{4})", line, re.I)
            if m:
                case_ref = m.group(1).upper()
        if not case_ref:
            continue
        entries.append(
            {
                "case_ref": case_ref,
                "item_no": "?",
                "bench": "Court",
                "stage": "",
                "parties": line[:200],
                "advocate": "",
            }
        )
    return entries


def parse_causelist_file(raw: bytes, filename: str = "") -> tuple[list[dict[str, Any]], str]:
    text = raw.decode("utf-8", errors="replace")
    if "<table" in text.lower() or "<tr" in text.lower():
        entries = _parse_html_table(text)
        return entries, "ecourts_html"
    name = (filename or "").lower()
    if name.endswith(".html") or name.endswith(".htm"):
        entries = _parse_html_table(text)
        if entries:
            return entries, "ecourts_html"
    entries = _parse_plaintext(_strip_html(text) if "<" in text else text)
    return entries, "causelist_text"


def match_cases_on_entries(
    entries: list[dict[str, Any]],
    cases: list[dict[str, Any]],
    list_date_iso: str,
    advocate_hint: str | None = None,
) -> dict[str, Any]:
    updates: list[dict[str, Any]] = []
    for item in cases:
        court_id = int(item["court_id"])
        case_no = str(item["case_no"]).strip()
        client_case_id = str(item["client_case_id"])
        target = norm_ref(case_no)
        row: dict[str, Any] = {
            "client_case_id": client_case_id,
            "court_id": court_id,
            "case_no": case_no,
            "found": False,
            "source": "uploaded_causelist",
        }
        for e in entries:
            ref = norm_ref(e["case_ref"])
            cnr = _CNR_RE.search(case_no)
            target_cnr = cnr.group(1).upper() if cnr else ""
            hit = ref == target or (target and target in ref) or (target_cnr and target_cnr in e["case_ref"].upper())
            if not hit:
                continue
            detail = f"{e.get('bench', 'Court')} · Item {e.get('item_no', '?')}"
            if e.get("stage"):
                detail += f" · {e['stage']}"
            row.update(
                {
                    "found": True,
                    "list_date": list_date_iso,
                    "parties": e.get("parties") or "",
                    "stage": e.get("stage") or "Listed",
                    "next_date": list_date_iso,
                    "next_detail": detail,
                }
            )
            break
        updates.append(row)

    discovered: list[dict[str, Any]] = []
    if advocate_hint:
        seen: set[str] = set()
        for e in entries:
            if not advocate_matches(e.get("advocate") or e.get("parties") or "", advocate_hint):
                continue
            ref = norm_ref(e["case_ref"])
            if ref in seen:
                continue
            seen.add(ref)
            discovered.append(
                {
                    "case_no": e["case_ref"],
                    "parties": e.get("parties") or "",
                    "next_date": list_date_iso,
                    "next_detail": f"{e.get('bench', 'Court')} · Item {e.get('item_no', '?')}",
                }
            )

    return {
        "ok": True,
        "updates": updates,
        "discovered": discovered,
        "entry_count": len(entries),
        "source": "uploaded_causelist",
    }
