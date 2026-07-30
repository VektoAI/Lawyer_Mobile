"""Munshi stage-0 ingestion pipeline (ARCHITECTURE.md §6).

Bronze -> silver -> gold, every stage idempotent:
  1. fetch: adapter produces raw cause-list bytes  -> raw_snapshots (+ file on disk)
  2. parse: snapshot -> causelist_entries
  3. diff/match: entries -> case_events (dedup_key = no double bubbles)
  4. notify: events -> notification_outbox (idempotency_key = no double sends)

Adapters: 'demo' simulates each court publishing tomorrow's list for the cases
we already track (deterministic, offline). A real adapter (e.g. DRT via
drt_causelist.sh) drops into fetch_causelist() without touching stages 2-4 —
that isolation is the whole point of the design.
"""
import json
import os
import re
import hashlib
from datetime import date, datetime, timedelta

import requests

from db import get_conn, dedup, RAW_DIR

DOW = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
MON = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def fmt(d: date) -> str:
    return f"{DOW[d.weekday()]}, {d.day} {MON[d.month - 1]}"


def norm_ref(ref: str) -> str:
    """'SA/230/2026' and 'SA 230/2026' both -> 'SA 230 2026' — court portals
    are inconsistent about separators; matching must not be."""
    return re.sub(r"[^A-Z0-9]+", " ", (ref or "").upper()).strip()


# ------------------------------------------------------------- live DRT adapter
# Port of drt_causelist.sh: drt.gov.in/drtapi, no captcha, multipart form posts.
DRT_API = "https://drt.gov.in/drtapi"
_drt_scheme_cache: dict = {}


def _form(**kw):
    return {k: (None, str(v)) for k, v in kw.items()}


def _ddmmyyyy(iso: str) -> str:
    y, m, d = iso.split("-")
    return f"{d}/{m}/{y}"


def _parse_drt_html(html: str, bench: str):
    """Cause-list HTML -> entries. Rows look like
    [Sl.No, Case No., Applicant Vs Defendant, Advocate, Remark]; stage section
    headers (FRESH MATTERS, ARGUMENTS, ...) are rows with only the 3rd cell."""
    entries, section = [], ""
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S):
        cells = [re.sub(r"<[^>]+>|&nbsp;?", " ", c) for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.S)]
        cells = [re.sub(r"\s+", " ", c).strip() for c in cells]
        if len(cells) >= 3 and not cells[0] and not cells[1] and cells[2]:
            head = cells[2]
            if head.isupper() and "TRIBUNAL" not in head and "HON" not in head and len(head) < 60:
                section = head.title()
        if len(cells) >= 3 and cells[0].isdigit() and cells[1]:
            entries.append({
                "case_ref": cells[1].split(" IN ")[0].strip(),
                "item_no": cells[0],
                "bench": bench,
                "stage": section,
                "parties": cells[2],
                "advocate": (cells[3] if len(cells) > 3 else "").strip(" -"),
            })
    return entries


def drt_fetch(city_key: str, list_date_iso: str):
    ddmm = _ddmmyyyy(list_date_iso)
    if city_key not in _drt_scheme_cache:
        r = requests.post(f"{DRT_API}/getDrtDratScheamName", json={}, timeout=20)
        for it in r.json():
            if city_key.lower() in it.get("SchemaName", "").lower():
                _drt_scheme_cache[city_key] = it["schemeNameDrtId"]
                break
        else:
            raise RuntimeError(f"no DRT location matches '{city_key}'")
    sid = _drt_scheme_cache[city_key]

    courts = requests.post(f"{DRT_API}/getCourtName",
                           files=_form(schemeNameDrtId=sid, listingDate=ddmm), timeout=20).json()
    raw_courts, entries = [], []
    for c in courts if isinstance(courts, list) else []:
        cid, judge = c.get("courtNameId"), c.get("judgeName", "")
        if not cid:
            continue
        r = requests.post(f"{DRT_API}/getDrtDratCourtNo",
                          files=_form(schemeNameDrtId=sid, listingDate=ddmm, courtNameId=cid), timeout=20)
        m = re.search(r'courtNo":"([^"]+)"', r.text)
        cno = m.group(1) if m else "1"
        r = requests.post(f"{DRT_API}/getDrtCauselistReport",
                          files=_form(schemeNameDrtId=sid, causeListDate=ddmm, courtNameId=cid, courtNo=cno),
                          timeout=20)
        m = re.search(r'dailyCauseListLink":"([^"]+)"', r.text)
        if not m:
            continue
        html = requests.get(m.group(1), timeout=30).text
        raw_courts.append({"judge": judge, "courtNo": cno, "link": m.group(1), "html": html})
        entries.extend(_parse_drt_html(html, f"Court {cno} · {judge}"))
    raw = json.dumps({"source": "drt.gov.in", "city": city_key, "date": list_date_iso,
                      "courts": raw_courts}, ensure_ascii=False).encode()
    return raw, entries


def fetch_causelist(court, list_date: str):
    """Adapter dispatch. Returns (raw_bytes, entries) — entries are dicts of
    {case_ref, item_no, bench, stage?, parties?, advocate?}.

    'demo'          — simulates the court publishing a list for tracked cases
                      whose next_date == list_date (deterministic, offline).
    'drt:<city>'    — LIVE drt.gov.in pull for that DRT bench (port of
                      drt_causelist.sh). New sources = new branches here;
                      stages 2-4 of the pipeline never change."""
    conn = get_conn()
    adapter = court["adapter"]
    if adapter == "demo":
        rows = conn.execute(
            "SELECT id, case_no, next_detail FROM cases WHERE court_id=? AND status='active' AND next_date=?",
            (court["id"], list_date),
        ).fetchall()
        entries = [
            {"case_ref": r["case_no"], "item_no": str(14 + i), "bench": (r["next_detail"] or "").split("·")[0].strip() or "Court 1"}
            for i, r in enumerate(rows)
        ]
        raw = json.dumps({"court": court["name"], "date": list_date, "list": entries}, indent=1).encode()
        return raw, entries
    if adapter.startswith("drt"):
        city = adapter.split(":", 1)[1] if ":" in adapter else court["name"]
        return drt_fetch(city, list_date)
    raise ValueError(f"unknown adapter {adapter}")


def run_nightly(target_date: str = None) -> dict:
    """One full ingestion cycle for a cause-list date (default: tomorrow).
    Safe to re-run — every stage dedupes. Digests go to EVERY chamber that
    watches a listed case."""
    conn = get_conn()
    today = date.today()
    tomorrow = date.fromisoformat(target_date) if target_date else today + timedelta(days=1)
    t_iso = tomorrow.isoformat()
    summary = {"date": t_iso, "courts": 0, "entries": 0, "events": 0, "outbox": 0, "skipped_dupes": 0}

    listed = []  # (case dict, entry, court name) for the digests

    for court in conn.execute("SELECT * FROM courts").fetchall():
        court = dict(court)
        try:
            raw, entries = fetch_causelist(court, t_iso)
        except Exception as exc:  # honest degradation: record, never silently omit
            with conn:
                conn.execute(
                    "INSERT OR REPLACE INTO source_health(court_id,run_date,fetched_ok,parsed_ok,entries,error) VALUES (?,?,0,0,0,?)",
                    (court["id"], t_iso, str(exc)),
                )
            continue

        summary["courts"] += 1
        content_hash = hashlib.sha256(raw).hexdigest()
        path = os.path.join(RAW_DIR, f"court{court['id']}_{t_iso}_{content_hash[:8]}.json")
        with conn:
            cur = conn.execute(
                "INSERT OR IGNORE INTO raw_snapshots(court_id,fetched_at,content_hash,path) VALUES (?,?,?,?)",
                (court["id"], datetime.now().isoformat(timespec="seconds"), content_hash, path),
            )
            if cur.rowcount:  # bronze: keep the raw data (only once per identical publish)
                with open(path, "wb") as f:
                    f.write(raw)
            snap_id = conn.execute(
                "SELECT id FROM raw_snapshots WHERE court_id=? AND content_hash=?", (court["id"], content_hash)
            ).fetchone()[0]

            # match against tracked cases with normalized refs (portals are
            # inconsistent about '/' vs ' ' — see norm_ref)
            case_map = {
                norm_ref(r["case_no"]): dict(r)
                for r in conn.execute("SELECT * FROM cases WHERE court_id=?", (court["id"],))
            }
            for e in entries:  # silver
                case = case_map.get(norm_ref(e["case_ref"]))
                conn.execute(
                    "INSERT INTO causelist_entries(snapshot_id,court_id,list_date,item_no,case_ref,case_id,bench) VALUES (?,?,?,?,?,?,?)",
                    (snap_id, court["id"], t_iso, e["item_no"], e["case_ref"], case["id"] if case else None, e["bench"]),
                )
                if not case:
                    continue
                summary["entries"] += 1

                # the court's published state wins: sync next date + details
                detail = f"{e['bench']} · Item {e['item_no']}"
                if case["next_date"] != t_iso:
                    conn.execute("UPDATE cases SET next_date=?, next_detail=? WHERE id=?", (t_iso, detail, case["id"]))
                if case["parties"].startswith("New matter") and e.get("parties"):
                    case["parties"] = e["parties"].title().replace(" Vs ", " vs ")
                    conn.execute("UPDATE cases SET parties=? WHERE id=?", (case["parties"], case["id"]))
                if e.get("stage") and (case["stage"] or "").startswith("Synced"):
                    conn.execute("UPDATE cases SET stage=? WHERE id=?", (e["stage"], case["id"]))
                conn.execute("INSERT OR IGNORE INTO hearings(case_id,date,purpose) VALUES (?,?,?)",
                             (case["id"], t_iso, e.get("stage") or case["stage"] or "Listed"))

                # gold: diff -> event, idempotent on (case, date, kind).
                # Honesty rule: only a LIVE adapter may claim "listed" (cause-list
                # verified); demo/diary dates are reminders, clearly labelled.
                is_live = court["adapter"] != "demo"
                when = "tomorrow — " if t_iso == (today + timedelta(days=1)).isoformat() else "on "
                if is_live:
                    text = f"Listed {when}{fmt(tomorrow)}"
                    sub = f"{court['name']} · {detail} · {e.get('stage') or case['stage'] or ''}".rstrip(" ·")
                else:
                    text = f"Hearing {when}{fmt(tomorrow)}"
                    sub = f"{court['name']} · as per your case diary — verify cause list"
                key = dedup("causelist", case["id"], t_iso)
                cur = conn.execute(
                    """INSERT OR IGNORE INTO case_events
                       (case_id,chamber_id,kind,side,text,sub,shareable,event_date,time_label,dedup_key)
                       VALUES (?,NULL,'causelist','right',?,?,1,?,?,?)""",
                    (case["id"], text, sub, today.isoformat(), datetime.now().strftime("%-I:%M %p"), key),
                )
                if cur.rowcount:
                    summary["events"] += 1
                    conn.execute("UPDATE case_watches SET unread=unread+1 WHERE case_id=?", (case["id"],))
                else:
                    summary["skipped_dupes"] += 1
                listed.append((dict(case), dict(e), court["name"]))

            conn.execute(
                "INSERT OR REPLACE INTO source_health(court_id,run_date,fetched_ok,parsed_ok,entries,error) VALUES (?,?,1,1,?,NULL)",
                (court["id"], t_iso, len(entries)),
            )

    # digests -> outbox, one per chamber that watches a listed case
    # (idempotent per chamber+date)
    if listed:
        by_chamber: dict = {}
        for case, e, court_name in listed:
            for w in conn.execute("SELECT chamber_id FROM case_watches WHERE case_id=?", (case["id"],)):
                by_chamber.setdefault(w["chamber_id"], []).append((case, e, court_name))
        with conn:
            for chamber_id, items in by_chamber.items():
                lawyer = conn.execute(
                    "SELECT * FROM lawyers WHERE chamber_id=? AND role='owner'", (chamber_id,)
                ).fetchone()
                if not lawyer:
                    continue
                lines = [f"⚖️ Cause list for {fmt(tomorrow)} — {len(items)} hearing(s):"]
                for i, (case, e, court_name) in enumerate(items, 1):
                    lines.append(f"{i}. {case['parties']} ({case['case_no']}) — {court_name}, {e['bench']}, Item {e['item_no']}")
                lines.append("— Munshi, your robot clerk. Reply with any case number for status.")
                cur = conn.execute(
                    """INSERT OR IGNORE INTO notification_outbox(channel,recipient,template,payload,idempotency_key)
                       VALUES ('wa',?,?,?,?)""",
                    (lawyer["phone"], "daily_digest", "\n".join(lines), dedup("digest", chamber_id, t_iso)),
                )
                summary["outbox"] += cur.rowcount
    return summary
