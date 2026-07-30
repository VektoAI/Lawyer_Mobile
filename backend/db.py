"""Munshi stage-0 database: SQLite implementing the ARCHITECTURE.md schema.

Design notes (see ARCHITECTURE.md §2, §5):
- case_events is APPEND-ONLY: never UPDATE or DELETE a row. The chat UI is a
  rendering of this log; dedup_key makes every pipeline stage idempotent.
- Client PII lives only in the `clients` table (stage-0 stand-in for the PII
  vault; erasure = delete row, events reference case_id not client fields).
- consent_ledger is append-only consent artifacts (DPDP + WhatsApp opt-in proof).
"""
import os
import sqlite3
import secrets
import hashlib
import threading
from datetime import date, timedelta

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
DB_PATH = os.path.join(DATA_DIR, "munshi.db")
RAW_DIR = os.path.join(DATA_DIR, "raw")

_lock = threading.Lock()
_conn = None

SCHEMA = """
CREATE TABLE IF NOT EXISTS chambers (
  id INTEGER PRIMARY KEY, name TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS lawyers (
  id INTEGER PRIMARY KEY, chamber_id INTEGER NOT NULL REFERENCES chambers(id),
  phone TEXT UNIQUE NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'owner',
  bar_enrolment TEXT
);
CREATE TABLE IF NOT EXISTS auth_tokens (
  token TEXT PRIMARY KEY, lawyer_id INTEGER NOT NULL REFERENCES lawyers(id),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS otp_requests (
  phone TEXT PRIMARY KEY, otp TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS consent_ledger (
  id INTEGER PRIMARY KEY, lawyer_id INTEGER REFERENCES lawyers(id),
  phone TEXT, purpose TEXT NOT NULL, artifact TEXT,
  granted_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS courts (
  id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL, adapter TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS cases (
  id INTEGER PRIMARY KEY, court_id INTEGER NOT NULL REFERENCES courts(id),
  case_no TEXT NOT NULL, parties TEXT NOT NULL, stage TEXT,
  status TEXT NOT NULL DEFAULT 'active',          -- active | disposed
  next_date TEXT, next_detail TEXT,
  UNIQUE(court_id, case_no)
);
CREATE TABLE IF NOT EXISTS case_watches (
  chamber_id INTEGER NOT NULL REFERENCES chambers(id),
  case_id INTEGER NOT NULL REFERENCES cases(id),
  pinned INTEGER NOT NULL DEFAULT 0, urgent INTEGER NOT NULL DEFAULT 0,
  unread INTEGER NOT NULL DEFAULT 0,
  added_via TEXT NOT NULL DEFAULT 'manual',
  PRIMARY KEY (chamber_id, case_id)
);
CREATE TABLE IF NOT EXISTS clients (              -- stage-0 PII vault stand-in
  id INTEGER PRIMARY KEY, chamber_id INTEGER NOT NULL, case_id INTEGER NOT NULL,
  name TEXT NOT NULL, phone TEXT
);
CREATE TABLE IF NOT EXISTS fees (
  chamber_id INTEGER NOT NULL, case_id INTEGER NOT NULL, agreed INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (chamber_id, case_id)
);
CREATE TABLE IF NOT EXISTS hearings (
  id INTEGER PRIMARY KEY, case_id INTEGER NOT NULL REFERENCES cases(id),
  date TEXT NOT NULL, purpose TEXT, outcome TEXT,
  UNIQUE(case_id, date)
);
CREATE TABLE IF NOT EXISTS case_events (          -- APPEND-ONLY. The product.
  id INTEGER PRIMARY KEY, case_id INTEGER NOT NULL REFERENCES cases(id),
  chamber_id INTEGER,                             -- NULL = court-derived (shared)
  kind TEXT NOT NULL,                             -- causelist|hearing|order|payment|note|task|doc|client|system
  side TEXT NOT NULL,                             -- left = lawyer action, right = notification
  text TEXT NOT NULL, sub TEXT,
  doc_name TEXT, doc_size TEXT,
  shareable INTEGER NOT NULL DEFAULT 0,
  event_date TEXT NOT NULL, time_label TEXT NOT NULL,
  dedup_key TEXT UNIQUE,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS documents (
  id INTEGER PRIMARY KEY, case_id INTEGER NOT NULL, chamber_id INTEGER NOT NULL,
  name TEXT NOT NULL, size_label TEXT, date_label TEXT, is_pdf INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY, case_id INTEGER NOT NULL, chamber_id INTEGER NOT NULL,
  amount INTEGER NOT NULL, mode TEXT, note TEXT, date_label TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS raw_snapshots (
  id INTEGER PRIMARY KEY, court_id INTEGER NOT NULL, fetched_at TEXT NOT NULL,
  content_hash TEXT NOT NULL, path TEXT NOT NULL,
  UNIQUE(court_id, content_hash)
);
CREATE TABLE IF NOT EXISTS causelist_entries (
  id INTEGER PRIMARY KEY, snapshot_id INTEGER NOT NULL REFERENCES raw_snapshots(id),
  court_id INTEGER NOT NULL, list_date TEXT NOT NULL, item_no TEXT,
  case_ref TEXT NOT NULL, case_id INTEGER, bench TEXT
);
CREATE TABLE IF NOT EXISTS notification_outbox (
  id INTEGER PRIMARY KEY, channel TEXT NOT NULL,   -- wa | otp
  recipient TEXT NOT NULL, template TEXT NOT NULL, payload TEXT NOT NULL,
  idempotency_key TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending',          -- pending | sent
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  sent_at TEXT
);
CREATE TABLE IF NOT EXISTS source_health (
  court_id INTEGER NOT NULL, run_date TEXT NOT NULL,
  fetched_ok INTEGER, parsed_ok INTEGER, entries INTEGER, error TEXT,
  PRIMARY KEY (court_id, run_date)
);
"""


def get_conn():
    global _conn
    if _conn is None:
        os.makedirs(DATA_DIR, exist_ok=True)
        os.makedirs(RAW_DIR, exist_ok=True)
        _conn = sqlite3.connect(DB_PATH, check_same_thread=False)
        _conn.row_factory = sqlite3.Row
        _conn.executescript(SCHEMA)
        _conn.execute("PRAGMA journal_mode=WAL")
    return _conn


def lock():
    return _lock


def dedup(*parts) -> str:
    return hashlib.sha256("|".join(str(p) for p in parts).encode()).hexdigest()


def new_token() -> str:
    return secrets.token_urlsafe(24)


# ---------------------------------------------------------------- seed data
def iso(d: date) -> str:
    return d.isoformat()


def ensure_live_courts():
    """Idempotent: registers courts with LIVE adapters (run on every startup so
    existing databases pick up new sources without a migration)."""
    conn = get_conn()
    with conn:
        conn.execute(
            "INSERT OR IGNORE INTO courts(id,name,type,adapter) VALUES (7,'DRT Dehradun','drt','drt:dehradun')"
        )


def seed_if_empty():
    conn = get_conn()
    if conn.execute("SELECT COUNT(*) FROM chambers").fetchone()[0]:
        return
    T = date.today()

    def day(offset):
        return iso(T + timedelta(days=offset))

    with conn:
        conn.execute("INSERT INTO chambers(id,name) VALUES (1,'Chamber 14, District Court Complex, Dehradun')")
        conn.execute("""INSERT INTO lawyers(id,chamber_id,phone,name,role,bar_enrolment)
                        VALUES (1,1,'+919999900001','Adv. Priyanshu Jain','owner','UK/1234/2015')""")
        conn.execute("INSERT INTO consent_ledger(lawyer_id,phone,purpose,artifact) VALUES (1,'+919999900001','pilot_signup','seeded pilot chamber')")

        courts = [
            (1, "DRT Allahabad", "drt", "demo"),
            (2, "District & Sessions Court, Dehradun", "district", "demo"),
            (3, "Family Court, Dehradun", "district", "demo"),
            (4, "High Court of Uttarakhand, Nainital", "hc", "demo"),
            (5, "Civil Judge (SD), Dehradun", "district", "demo"),
            (6, "MACT, Dehradun", "tribunal", "demo"),
        ]
        conn.executemany("INSERT INTO courts(id,name,type,adapter) VALUES (?,?,?,?)", courts)

        # (id, court, case_no, parties, stage, next_date, next_detail, status)
        cases = [
            (1, 1, "OA 412/2024", "Rajesh Kumar vs Punjab National Bank", "Evidence", day(1), "Court 2 · Item 14 · 10:30 AM", "active"),
            (2, 2, "ST 88/2023", "State vs Vinod Chauhan", "Prosecution evidence", day(1), "Court 5 · PW-4 examination", "active"),
            (3, 3, "HMA 214/2025", "Meera Devi vs Sanjay Kumar", "Mediation", day(6), "Mediation Centre · 11:00 AM", "active"),
            (4, 1, "SA 67/2025", "M/s Doon Motors vs HDFC Bank", "Arguments on interim relief", day(35), "Court 1 · Arguments", "active"),
            (5, 4, "WPCRL 45/2026", "Om Prakash vs State of Uttarakhand", "Fresh admission", day(3), "Court 1 · Fresh matters", "active"),
            (6, 5, "CS 132/2022", "Sharma Constructions vs MDDA", "Written statement", day(18), "WS filing by defendant", "active"),
            (7, 6, "MACP 89/2021", "Kamla Devi vs Oriental Insurance", "Disposed — award passed", None, None, "disposed"),
        ]
        conn.executemany("INSERT INTO cases(id,court_id,case_no,parties,stage,next_date,next_detail,status) VALUES (?,?,?,?,?,?,?,?)", cases)

        watches = [  # (case, pinned, urgent, unread, via)
            (1, 1, 1, 2, "cnr"), (2, 0, 0, 1, "cnr"), (3, 0, 0, 0, "manual"),
            (4, 0, 0, 0, "cnr"), (5, 0, 1, 1, "cnr"), (6, 0, 0, 0, "manual"), (7, 0, 0, 0, "manual"),
        ]
        conn.executemany("INSERT INTO case_watches(chamber_id,case_id,pinned,urgent,unread,added_via) VALUES (1,?,?,?,?,?)", watches)

        clients = [
            (1, "Rajesh Kumar", "+919817000001"), (2, "Suresh Chauhan (brother)", "+919412000002"),
            (3, "Meera Devi", "+919760000003"), (4, "Harpreet Singh (Prop.)", "+919897000004"),
            (5, "Om Prakash", "+919456600005"), (6, "Anil Sharma", "+919812300006"),
            (7, "Kamla Devi", "+918979000007"),
        ]
        conn.executemany("INSERT INTO clients(chamber_id,case_id,name,phone) VALUES (1,?,?,?)", clients)

        fees = [(1, 80000), (2, 150000), (3, 60000), (4, 120000), (5, 40000), (6, 50000), (7, 45000)]
        conn.executemany("INSERT INTO fees(chamber_id,case_id,agreed) VALUES (1,?,?)", fees)

        hearings = [
            (1, day(-123), "First hearing", "Notice issued to respondent bank"),
            (1, day(-80), "Reply filing", "Bank sought time; adjourned"),
            (1, day(-38), "Reply filed", "Rejoinder to be filed within 4 weeks"),
            (1, day(1), "Rejoinder + evidence", None),
            (2, day(-55), "PW-2 examination", "PW-2 examined & discharged"),
            (2, day(-12), "PW-3 examination", "PW-3 examined; PW-4 (IO) summoned"),
            (2, day(1), "PW-4 (IO) examination", None),
            (3, day(-51), "First motion", "Referred to mediation"),
            (3, day(6), "Mediation session 2", None),
            (4, day(-35), "Stay application", "Interim stay on possession granted"),
            (4, day(0), "Stay extension", "Stay extended till next date"),
            (4, day(35), "Arguments", None),
            (5, day(3), "Admission", None),
            (6, day(-22), "Summons served", "MDDA appeared; time for WS"),
            (6, day(18), "Written statement", None),
            (7, day(-10), "Award", "Award: ₹8.4L with 7.5% interest"),
        ]
        conn.executemany("INSERT INTO hearings(case_id,date,purpose,outcome) VALUES (?,?,?,?)", hearings)

        docs = [
            (1, "OA_Petition_412-2024.pdf", "2.4 MB", "1 Mar", 1), (1, "Bank_Reply.pdf", "1.1 MB", "2 Jun", 1),
            (1, "Rejoinder_Final.pdf", "840 KB", day(-2), 1), (1, "Loan_Statement_2019-24.xlsx", "220 KB", "1 Mar", 0),
            (2, "Chargesheet_ST88.pdf", "6.2 MB", "12 Jan", 1), (2, "PW3_Deposition.pdf", "480 KB", day(-12), 1),
            (3, "HMA_Petition.pdf", "1.3 MB", "2 Apr", 1),
            (4, "SA_67_Appeal.pdf", "3.8 MB", "28 May", 1), (4, "Stay_Order_1.pdf", "310 KB", day(-35), 1),
            (4, "Stay_Order_2.pdf", "295 KB", day(0), 1),
            (5, "WPCRL_45_Petition.pdf", "2.1 MB", day(-2), 1),
            (6, "Plaint_CS132.pdf", "1.9 MB", "11 Nov 22", 1),
            (7, "Award_MACP89.pdf", "1.2 MB", day(-10), 1),
        ]
        conn.executemany("INSERT INTO documents(case_id,chamber_id,name,size_label,date_label,is_pdf) VALUES (?,1,?,?,?,?)", docs)

        payments = [
            (1, 25000, "Cash", "Retainer", "1 Mar"), (1, 15000, "UPI", "Drafting fee", "15 Jun"),
            (1, 15000, "UPI", "Hearing fee", day(-1)),
            (2, 70000, "Cash", "Retainer", "20 Jan"), (2, 20000, "UPI", "Instalment", day(-7)),
            (3, 30000, "UPI", "Retainer", "2 Apr"),
            (4, 60000, "Bank transfer", "Retainer", "28 May"), (4, 60000, "Bank transfer", "Final instalment", "20 Jun"),
            (5, 25000, "UPI", "Filing + appearance", day(-3)),
            (6, 20000, "Cash", "Retainer", "11 Nov 22"),
            (7, 45000, "Cash", "Full & final", day(-10)),
        ]
        conn.executemany("INSERT INTO payments(case_id,chamber_id,amount,mode,note,date_label) VALUES (?,1,?,?,?,?)", payments)

        # (case, chamber?, kind, side, text, sub, doc_name, doc_size, share, date, time)
        events = [
            (1, None, "hearing", "right", "Hearing outcome: Bank's reply taken on record.", "Rejoinder to be filed within 4 weeks", None, None, 0, day(-38), "2:15 PM"),
            (1, 1, "client", "left", "Client meeting done. Rajesh will arrange the 2019 loan sanction letter by Wednesday.", None, None, None, 0, day(-4), "11:20 AM"),
            (1, 1, "doc", "left", "Rejoinder_Final.pdf", "Uploaded to case file", "Rejoinder_Final.pdf", "840 KB · PDF", 0, day(-2), "4:45 PM"),
            (1, 1, "task", "left", "File evidence affidavit", "Due in 10 days · assigned to self", None, None, 0, day(-2), "4:50 PM"),
            (1, None, "payment", "right", "₹15,000 received from client", "UPI · Hearing fee · Balance due ₹25,000", None, None, 0, day(-1), "10:05 AM"),
            (2, None, "hearing", "right", "PW-3 examined and discharged. PW-4 (IO) summoned for next date.", "Next hearing tomorrow", None, None, 1, day(-12), "4:30 PM"),
            (2, 1, "note", "left", "Prepare cross of IO — focus on the seizure memo timing contradiction (PW-2 said 6 PM, memo says 4 PM).", None, None, None, 0, day(-3), "6:10 PM"),
            (3, None, "hearing", "right", "Mediation session 1 — no settlement. Next session fixed.", "Mediation Centre, Family Court", None, None, 0, day(-8), "1:05 PM"),
            (3, 1, "client", "left", "Spoke to Meera — not willing to settle below ₹12L permanent alimony + Dehradun flat.", None, None, None, 0, day(-8), "5:40 PM"),
            (4, None, "hearing", "right", "Hearing done today: interim stay on possession EXTENDED till next date.", "Arguments on next date", None, None, 1, day(0), "12:40 PM"),
            (4, None, "order", "right", "Order uploaded on DRT portal", "Auto-fetched & saved to case docs", "Stay_Order_2.pdf", "295 KB · PDF", 1, day(0), "5:55 PM"),
            (5, 1, "doc", "left", "WPCRL_45_Petition.pdf", "Filed via e-filing, diary no. 8821/2026", "WPCRL_45_Petition.pdf", "2.1 MB · PDF", 0, day(-2), "12:30 PM"),
            (6, None, "hearing", "right", "MDDA appeared through counsel. Time granted for written statement.", None, None, None, 0, day(-22), "3:20 PM"),
            (7, None, "order", "right", "AWARD PASSED: ₹8,40,000 compensation with 7.5% interest from filing date.", "Case disposed 🎉", None, None, 1, day(-10), "4:50 PM"),
            (7, 1, "task", "left", "Apply for certified copy of award", "Done ✓ · copying agency receipt #4412", None, None, 0, day(-9), "10:00 AM"),
        ]
        for i, e in enumerate(events):
            conn.execute(
                """INSERT INTO case_events(case_id,chamber_id,kind,side,text,sub,doc_name,doc_size,shareable,event_date,time_label,dedup_key)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?)""",
                (*e, dedup("seed", i)),
            )
