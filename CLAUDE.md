# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Case Vault (internal codename "Munshi") — a Flutter mobile app for Indian lawyers, backed by a
FastAPI service. **Case/fee/document/client data is encrypted on the device and never touches the
server.** The backend only handles auth, chamber profile, billing status, and public court
metadata (cause lists, case lookups). This split is the single most important architectural fact
about the repo — when in doubt about whether something belongs client-side or server-side, it's
client-side unless it's auth, billing, or public court data.

```
casevault/
├── app/              Flutter client (Android/iOS/web) — THE product
├── backend/          FastAPI — auth, chamber profile, billing, court metadata, cron
├── sync-backend/      Standalone prototype for a future encrypted multi-device sync relay — NOT wired into app/ yet (see below)
├── Dockerfile.api    → Render service `munshi-api` (backend)
├── Dockerfile.web    → Render service `casevault-web` (Flutter web build, via docker/build-web.sh + nginx)
├── render.yaml       Render Blueprint (backend only; web service is separate/manual)
└── scripts/          build-apk.ps1, build-web.ps1
```

Root `README.md`, `BUILD.md`, `DEPLOY.md` cover day-to-day build/deploy mechanics; this file is
about the architecture and invariants that live only in code comments today. Note: `backend/README.md`
and `app/README.md` are partly stale — they reference paths (`mobile/app`, `mobile/backend`,
`REPO_LAYOUT.md`, `ROADMAP.md`, `app.main_web`, `docs/Munshi_Scale_Up_Architecture.html`,
`ARCHITECTURE.md`) that don't exist in this repo. Treat those as leftover text from a larger
monorepo this was extracted from — trust the actual code over those docs when they conflict.

## Commands

### Backend (`backend/`)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 4173 --reload
```

- Swagger: `http://127.0.0.1:4173/api/docs` (needs `MUNSHI_OPENAPI=1`, default when `MUNSHI_DEMO=1`)
- Health: `http://127.0.0.1:4173/healthz`
- Config lives in `backend/.env` (copy from `backend/.env.example`); loaded via `app/config.py`'s `get_settings()` (`lru_cache`d — tests must call `get_settings.cache_clear()` after mutating env vars, see the `env` fixture in `test_security_gates.py`).

Run tests (from `backend/`):

```powershell
python -m pytest -q                          # everything
python -m pytest tests/test_security_gates.py -q      # one file
python -m pytest tests/test_api_e2e.py -q -k demo_auth # one test by keyword
```

Tests hit the real `app.main:app` via `TestClient` — no separate server needed, no mocking of
Supabase for the demo-mode paths (`MUNSHI_DEMO=1`).

### Flutter app (`app/`)

```powershell
cd app
flutter pub get
flutter run --dart-define=MUNSHI_API_BASE=http://127.0.0.1:4173          # local API
flutter run --dart-define=MUNSHI_API_BASE=http://10.0.2.2:4173           # Android emulator → local API
flutter test                                                              # app/test/*.dart
```

Build APK / web (from repo root, via `scripts/`):

```powershell
.\scripts\build-apk.ps1 -ApiBase https://munshi-api.onrender.com -Mode debug
.\scripts\build-web.ps1 -ApiBase https://munshi-api.onrender.com
```

`MUNSHI_API_BASE` is baked in at build time (`app/lib/config/api_config.dart`) — there is no
runtime config endpoint the app calls to discover its own backend.

## Backend architecture (`backend/app/`)

`app/factory.py` builds the FastAPI app (`create_app()`); `app/main.py` is the production
entrypoint (`app = create_app()`), `backend/main.py` is a thin uvicorn shim for `uvicorn main:app
--app-dir backend`. There is no separate `main_web.py` — `MUNSHI_SERVE_UI=1` (serving a static UI
dir from `web/munshi-ui/`, which doesn't exist in this repo) is handled inside the same factory.
Every deployment in this repo runs with `MUNSHI_SERVE_UI=0` (API-only, for the mobile/web Flutter
clients).

Routers (`app/routers/`), all mounted under `/api` except `system`:
- **`auth.py`** — signup/login/refresh/demo, and the email-confirmation landing page. This is the
  most subtle part of the backend: Supabase's free tier won't let you customize the confirmation
  email template, so `GET /api/auth/confirm` has to handle *two* different delivery mechanisms
  depending on whether `token_hash` shows up as a query param (custom template, paid/custom-SMTP
  only) or not (free tier — Supabase already verified server-side and redirects here with the
  session in the URL **fragment**, which the server can never read; a client-side `<script>`
  fallback page reads `location.hash` instead). Read the docstrings on `confirm_email_page` and
  `_verify_otp_and_confirm` before touching this — tokens must never end up in a query string or
  server log.
- **`courts.py`** — case lookup / hearing sync / cause-list parsing. Always returns metadata only;
  never persists anything server-side.
- **`cron.py`** — cause-list cache refresh, gated by `X-Cron-Secret` (`MUNSHI_CRON_SECRET`, falls
  back to `MUNSHI_ADMIN_TOKEN`). Safe to call repeatedly (see idempotency note below).
- **`me.py`** — chamber profile (`display_name`, `enrolment`, `bar_council`, `chamber`, `phone`)
  and subscription plan. Demo users get a canned profile and a 403 on writes.
- **`billing.py`** — Stripe webhook, updates `profiles.plan` only. Fails closed (503) if
  `STRIPE_WEBHOOK_SECRET` isn't set — never processes an unsigned body.
- **`system.py`** — `/healthz`, `/api/config`, and `/api/bootstrap` (always 404 — a deliberate
  vault-mode signal, not a bug, that legacy PWA clients test against).

**Demo mode** (`MUNSHI_DEMO=1`, local dev default): `demo@localhost` / `demo-password-change-me`
logs in without touching Supabase (`app/deps.py`'s `demo_user`/`DEMO_TOKEN`), seeded with a fixed
identity ("Adv. Priyanshu Jain") and `read_only=True`. Every demo code path is gated on
`get_settings().demo_open`, and `test_security_gates.py` specifically regression-tests that
`MUNSHI_DEMO=0` actually closes all of them (auth/demo, the login shortcut, the bearer-token
shortcut, and the refresh shortcut) — if you touch any of those paths, re-run that file.

**Court data** (`app/services/court_lookup.py`, `court_ref.py`, `ecourts_parse.py`,
`causelist_cache_lookup.py`, `causelist_inbox.py`): DRT Dehradun/Allahabad are scraped live; other
courts (District/Family/HC) rely on HTML files ops drops in `backend/data/inbox/` as
`{court_id}_{YYYY-MM-DD}.html`, parsed by cron into `backend/data/causelist_cache/`. Two invariants
enforced by tests here:
- **Idempotency** — inbox processing and cache writes must be safe to run twice in a row with the
  same input (`test_causelist_inbox.py`'s `*_two_run_is_idempotent` tests are the pattern to
  follow for any new ingestion-style code).
- **Honest failure** — a source that couldn't be checked must never be reported the same way as
  "checked, and the case isn't on the list" (`lookup_case`'s `found`/`reason` shape,
  `test_security_gates.py`).

Dates for court data always use `ist_today()` (Asia/Kolkata), never the host clock — Render runs
UTC, and a naive `date.today()` is a day behind IST for ~5.5 hours after UTC midnight, exactly when
a lawyer's morning digest is built.

Admin/dev routes (`POST /api/dev/purge-auth-users`) require **all** of: `MUNSHI_DEMO=1`, a valid
`X-Admin-Token` header, and `SUPABASE_SERVICE_ROLE_KEY` configured — defense in depth, deliberately
not usable in production even with a leaked token.

## Flutter app architecture (`app/lib/`)

State/routing: Riverpod (`providers/app_providers.dart`) + `go_router` with a
`StatefulShellRoute.indexedStack` for the five main tabs (cases/calendar/fees/docs/profile) plus
modal routes for case detail and archived cases. `main.dart`'s router `redirect` gates everything
on `vaultStoreProvider.isUnlocked` — there's no separate auth-guard layer.

**The live encrypted-vault path** (what actually runs today):
`data/vault_store.dart` (a `ChangeNotifier`) is the source of truth for cases. It keeps the vault's
data key in memory via `crypto/vault_session.dart`, persists an unlock shortcut in
`flutter_secure_storage`, and reads/writes a single `crypto/encrypted_vault_file.dart` on disk.
`crypto/vault_crypto.dart` deliberately mirrors a prior web app's (`munshi-ui/vault.js`, not present
in this repo) exact scheme — PBKDF2-SHA256 250,000 iterations → AES-GCM-256 wrapping key, envelope-
encrypted data key, `{iv, data}` JSON packets — because changing the KDF would break the
`munshi-vault-backup-v1` backup/restore format (`crypto/backup_import.dart`). Don't "improve" the
crypto parameters without checking backward compatibility with existing exported backups.

**Scaffolding that is *not* wired in** — don't assume these are live just because they exist:
- `db/app_database.dart` (+ generated `app_database.g.dart`) is a drift/SQLCipher event-log schema
  for a planned future architecture. It's excluded from `flutter analyze` (see
  `analysis_options.yaml`) and nothing in `providers/` or `screens/` references `AppDatabase`.
- `services/sync_service.dart` talks to `sync-backend/`'s ciphertext relay (`POST /sync/push`,
  `GET /sync/pull`), a **separate FastAPI process** from `backend/`. Neither the service nor the
  relay is referenced by the running app (`AuthService`/`ApiClient` only talk to `backend/`'s
  `/api/*` routes). Treat `sync-backend/` as a standalone prototype, not a dependency of `app/`.

If a task involves multi-device sync or a local relational query layer, these two are the intended
landing spots — but verify current wiring before building on them, since "not yet wired in" is a
snapshot, not a permanent property.

`services/auth_service.dart` / `config/api_config.dart` are the real HTTP boundary to `backend/`:
bearer token + refresh token in secure storage, `MUNSHI_API_BASE` baked in at build time. Email
confirmation deep-links (`casevault://auth/confirm`) are parsed by
`sessionFromAuthCallbackUri` — must stay in sync with what `backend/app/routers/auth.py`'s
`confirm_email_page` actually emits (query param vs. fragment, see backend section above).

`theme.dart` / `MunshiColors` defines the WhatsApp-style chat mental model used across case detail
screens: right/ink-green bubbles = court-derived events, left/white bubbles = the lawyer's own
actions; brass gold (`MunshiColors.brassGold`) is reserved for urgency/attention accents only,
never as a bubble color. Keep new UI consistent with this rather than introducing a second visual
language.

## Cross-cutting invariants

Code comments across both `app/` and `backend/` cite specific numbered invariants (e.g. "invariant
6", "invariant 9") from a prior project-wide CLAUDE.md that isn't part of this repo's history — the
numbering is kept below exactly as referenced in code, so a comment pointing at "invariant N" still
resolves. Some numbers aren't reconstructable from what's here; don't invent content for them.

- **1 — Append-only event log.** `CaseEvents` in `app_database.dart` (planned schema) is
  insert-only; corrections are new rows, never `UPDATE`/`DELETE`. The UI is a rendering of the log,
  not the other way around.
- **2 — Idempotent sync/ingestion.** Every retry of a push or cron ingestion with the same
  `dedup_key`/`event_id` must be a no-op. Applies both to `sync_service.dart`'s `PendingEvent` and
  to `backend`'s cause-list cron (`test_causelist_inbox.py`'s two-run tests are the reference
  pattern).
- **4 — Honest court-sync errors.** Never let "could not verify a source" collapse into "checked,
  not found" — surface the distinction (`app/services/court_lookup.py`, `test_security_gates.py`).
- **6 — Integer rupees only.** No `REAL`/float column or field for money, anywhere — mobile
  (`app_database.dart`, `utils/rupee.dart`) or backend.
- **9 — Zero-knowledge server.** The server (both `backend/` and the `sync-backend/` prototype)
  only ever stores/relays ciphertext it cannot decrypt; case/fee/document/client data must never
  appear in a request body sent to a server. `SyncService`'s `encPayload` and everything under
  `backend/app/routers/courts.py` respect this — new endpoints must too.
- **12 — "Munshi" is an internal codename only.** A live competitor product uses that name in this
  exact market; it must never ship in a public-facing display name, bundle ID, or app store
  listing. Package/internal identifiers (`munshi_mobile`, `MUNSHI_*` env vars) are fine as-is; user
  -visible strings are not.
- **13 — One visual language.** Design tokens (`app/lib/theme.dart`) and the chat bubble
  convention described above are canonical; don't fork a second style system.

Also stated plainly in root `README.md`: **no server-side case vault**, ever — this is the
umbrella invariant the numbered ones above all serve.
