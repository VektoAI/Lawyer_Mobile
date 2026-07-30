"""Match case numbers against filesystem causelist cache (public list rows)."""
from __future__ import annotations

import re
from typing import Any

from app.services.court_ref import norm_ref
from app.services.causelist_inbox import load_entries_for_dates

_CNR_RE = re.compile(r"\b([A-Z]{2}[A-Z0-9]{14})\b", re.I)


def lookup_case_in_cache(
    court_id: int,
    case_no: str,
    list_dates: list[str],
) -> dict[str, Any]:
    target = norm_ref(case_no)
    cnr_m = _CNR_RE.search(case_no or "")
    target_cnr = cnr_m.group(1).upper() if cnr_m else ""
    checked: list[str] = []
    for iso, entries in load_entries_for_dates(court_id, list_dates):
        checked.append(iso)
        for e in entries:
            ref = norm_ref(e.get("case_ref") or "")
            raw_ref = (e.get("case_ref") or "").upper()
            hit = (
                ref == target
                or (target and target in ref)
                or (target_cnr and target_cnr in raw_ref)
            )
            if not hit:
                continue
            detail = f"{e.get('bench', 'Court')} · Item {e.get('item_no', '?')}"
            if e.get("stage"):
                detail += f" · {e['stage']}"
            return {
                "found": True,
                "source": "causelist_cache",
                "list_date": iso,
                "case_no": e.get("case_ref") or case_no,
                "parties": e.get("parties") or "",
                "stage": e.get("stage") or "Listed",
                "next_date": iso,
                "next_detail": detail,
            }
    return {
        "found": False,
        "source": "causelist_cache",
        "reason": "not on cached cause lists — drop file in data/inbox or wait for cron",
        "checked_dates": checked or list_dates,
    }
