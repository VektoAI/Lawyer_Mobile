"""Courts catalog + case number lookup (no server-side case storage)."""
from __future__ import annotations

import json

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from app.deps import current_user
from app.schemas import CaseLookupBody, SyncHearingsBody
from app.services.court_lookup import PUBLIC_COURTS, lookup_case, sync_hearings
from app.services.ecourts_parse import match_cases_on_entries, parse_causelist_file

router = APIRouter(tags=["courts"])


@router.get("/courts")
def list_courts(_user=Depends(current_user)):
    """Court pickers for PWA / mobile — same ids as munshi-ui/vault.js COURTS."""
    return {"ok": True, "courts": PUBLIC_COURTS}


@router.post("/courts/lookup")
def case_lookup(body: CaseLookupBody, user=Depends(current_user)):
    """Match a case number on a live cause list when adapter supports it.

    Returns metadata only; the client saves encrypted payload locally.
    """
    if user.get("read_only") or user.get("demo"):
        # Demo may preview lookup but cannot add cases in UI anyway.
        pass
    try:
        result = lookup_case(body.court_id, body.case_no.strip(), body.list_date)
    except Exception as exc:
        raise HTTPException(502, f"could not verify court source: {exc}") from exc
    result["ok"] = True
    if not result.get("found"):
        result["warning"] = result.get("reason") or "not found on checked lists"
    return result


@router.post("/courts/sync-hearings")
def sync_case_hearings(body: SyncHearingsBody, _user=Depends(current_user)):
    """Refresh next-hearing hints for tracked cases (+ optional advocate causelist scan).

    Returns metadata only; clients merge into the encrypted vault locally.
    """
    payload = [
        {"client_case_id": c.client_case_id, "court_id": c.court_id, "case_no": c.case_no}
        for c in body.cases
    ]
    try:
        return sync_hearings(payload, advocate_name=body.advocate_name, scan_court_ids=body.scan_court_ids)
    except Exception as exc:
        raise HTTPException(502, f"could not verify court sources: {exc}") from exc


@router.post("/courts/parse-causelist")
async def parse_uploaded_causelist(
    file: UploadFile = File(...),
    court_id: int = Form(...),
    list_date: str = Form(..., description="ISO YYYY-MM-DD — date this cause list is for"),
    cases_json: str = Form(default="[]", description="JSON array of {client_case_id, court_id, case_no}"),
    advocate_name: str | None = Form(default=None),
    _user=Depends(current_user),
):
    """Parse a cause-list file the lawyer downloaded from eCourts / district site.

    File is not stored — parsed in memory, matched to client-supplied case refs, discarded.
    Use for District / Family / HC when live scrape is blocked by captcha.
    """
    if not list_date or len(list_date) != 10:
        raise HTTPException(400, "list_date must be ISO YYYY-MM-DD")
    try:
        cases = json.loads(cases_json or "[]")
        if not isinstance(cases, list):
            raise ValueError("cases_json must be a JSON array")
    except Exception as exc:
        raise HTTPException(400, f"invalid cases_json: {exc}") from exc

    raw = await file.read()
    if len(raw) > 8 * 1024 * 1024:
        raise HTTPException(413, "file too large (max 8MB)")
    if not raw:
        raise HTTPException(400, "empty file")

    entries, source = parse_causelist_file(raw, file.filename or "")
    if not entries:
        raise HTTPException(
            422,
            "could not parse any case rows — save the cause list as HTML from eCourts "
            "(right-click → Save as) or export PDF and try again when PDF parsing ships",
        )

    result = match_cases_on_entries(entries, cases, list_date, advocate_name)
    result["parse_source"] = source
    result["court_id"] = court_id
    court = next((c for c in PUBLIC_COURTS if c["id"] == court_id), None)
    if court:
        result["court"] = court["name"]
    if not result.get("warnings") and not any(u.get("found") for u in result.get("updates", [])):
        result["warning"] = (
            "No matches — check case number/CNR matches the list, and list_date is the hearing date"
        )
    return result
