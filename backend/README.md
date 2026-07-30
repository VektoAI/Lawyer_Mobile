# Case Vault API (`backend/`)

Shared FastAPI service for the **Flutter mobile app** (primary). Legacy PWA lives under **`web/munshi-ui/`** and is optional.

**Layout:** [../REPO_LAYOUT.md](../REPO_LAYOUT.md) · **Mobile build:** [../mobile/BUILD.md](../mobile/BUILD.md) · **Render:** [../DEPLOY.md](../DEPLOY.md)

## Run — API only (mobile dev, default)

```powershell
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 4173 --reload
```

| URL | What |
|---|---|
| http://127.0.0.1:4173/ | JSON stub (`mode: api-only`) |
| http://127.0.0.1:4173/api/docs | Swagger (unless `MUNSHI_OPENAPI=0`) |
| http://127.0.0.1:4173/healthz | Health |

## Run — API + legacy PWA

```powershell
cd backend
$env:MUNSHI_SERVE_UI = "1"
uvicorn app.main_web:app --host 0.0.0.0 --port 4173 --reload
```

Then http://127.0.0.1:4173/ serves `web/munshi-ui/index.html`.

## Email confirmation

The confirmation email link points at **this API's own page**, `GET /api/auth/confirm`
— not a raw `casevault://` deep link, and not the legacy web app. That page verifies
the one-time Supabase token server-side exactly once, shows a branded "Email
verified" page, then hands off a ready-to-use session to the app via
`casevault://auth/confirm#access_token=...&refresh_token=...` (fragment, never a
query string, so tokens never hit server logs). If the app doesn't auto-open
(different device, app not installed), the page still says the account is
verified and offers a manual "Open Case Vault" button — never a dead end.

**One-time Supabase dashboard setup** (project `yacyqfxaogynvdlohfeo`):
1. **Authentication → URL Configuration** — Site URL = this API's own public host
   (e.g. `https://munshi-api.onrender.com`, not the legacy web app), and add it
   (plus `http://127.0.0.1:4173` for local dev) to **Redirect URLs**.
2. **Authentication → Email Templates → Confirm signup** — the link must be built as
   `{{ .SiteURL }}/api/auth/confirm?token_hash={{ .TokenHash }}&type=signup` (this is
   what makes the click land on our page instead of Supabase's own generic one).

`email_redirect_to` is still sent on signup/resend (computed from the request's own
host — see `_confirm_redirect_url` in `app/routers/auth.py`), but the real
confirmation mechanism is the `token_hash` in the email template above, consumed by
`GET /api/auth/confirm`. `POST /api/auth/confirm` (JSON, same token_hash contract)
still exists for the rare case where the app itself catches a raw `casevault://`
link directly.

## Full endpoint reference

| Method | Path | Auth | What |
|---|---|---|---|
| GET | `/healthz` | public | health check |
| GET | `/api/config` | public | public runtime flags (`demo`, `vault_mode`, …) |
| GET / POST / PUT | `/api/bootstrap` | public | always 404 — no server-side case storage (vault mode) |
| POST | `/api/signup` | public | create Supabase account; case data never touches this call |
| POST | `/api/login` | public | email + password → JWT (never sends email) |
| POST | `/api/auth/demo` | public, `MUNSHI_DEMO=1` only | one-tap showcase session |
| POST | `/api/auth/refresh` | public | refresh an access token |
| GET | `/api/auth/confirm` | public | HTML landing page — see *Email confirmation* above |
| POST | `/api/auth/confirm` | public | JSON equivalent, for the app catching a raw deep link |
| POST | `/api/auth/resend-confirm` | public | resend the signup confirmation email |
| POST | `/api/dev/purge-auth-users` | `X-Admin-Token` (`MUNSHI_ADMIN_TOKEN`) **and** `MUNSHI_DEMO=1` **and** `SUPABASE_SERVICE_ROLE_KEY` set | deletes every real Supabase Auth user except the local demo addresses — dev/reset utility, never usable in production even with a leaked token |
| GET | `/api/me` | Bearer | full chamber profile |
| GET | `/api/me/subscription` | Bearer | just `plan`/`demo`/`read_only` |
| PATCH | `/api/me/profile` | Bearer (403 for demo) | save display name, enrolment, bar council, chamber, phone |
| POST | `/api/stripe/webhook` | Stripe signature (`STRIPE_WEBHOOK_SECRET`) — 503 if unset, never accepts an unsigned body | updates `profiles.plan` only |
| GET | `/api/courts` | Bearer | public court catalog |
| POST | `/api/courts/lookup` | Bearer | match one case number on a live/cached cause list |
| POST | `/api/courts/sync-hearings` | Bearer | batch refresh next-hearing hints (+ optional advocate scan) |
| POST | `/api/courts/parse-causelist` | Bearer, multipart | parse an uploaded cause-list file in memory (never stored) |
| POST | `/api/cron/causelist-sync` | `X-Cron-Secret` | inbox + live DRT refresh |
| POST | `/api/cron/process-inbox` | `X-Cron-Secret` | parse `data/inbox/` only |
| GET | `/api/cron/causelist-status` | `X-Cron-Secret` | which dates are cached per court |

Every JSON response carries `"ok": true|false`. Errors are FastAPI's standard
`{"detail": "..."}` shape via `HTTPException`.

## Chamber profile (Supabase)

Run `backend/profiles_schema.sql` in the Supabase SQL editor (adds `display_name`, `enrolment`, `bar_council`, `chamber`). Then Profile → Edit chamber profile saves to `/api/me/profile`.

## Seeded login

`demo@localhost` / `demo-password-change-me`

Case data stays in the browser vault — not on this server.

## Court lookup (metadata only)

When adding a case, the PWA and mobile app can ask the server to match a case number on a **live cause list** (DRT Dehradun today). The server returns parties/stage/hearing hints only; nothing is stored server-side.

| Method | Path | Auth |
|---|---|---|
| GET | `/api/courts` | Bearer |
| POST | `/api/courts/lookup` | Bearer — body `{ "court_id": 7, "case_no": "…", "list_date": "YYYY-MM-DD" optional }` |
| POST | `/api/courts/sync-hearings` | Bearer — refresh next hearings for tracked cases (metadata only); optional `advocate_name` for DRT scan |

## Cause-list cron (no S3, no lawyer vault on server)

Public cause lists only — cached as JSON under `backend/data/causelist_cache/`. Lawyer notes/fees/clients stay on device.

1. Set **`MUNSHI_CRON_SECRET`** (or reuse **`MUNSHI_ADMIN_TOKEN`**) in `.env`.
2. **DRT:** cron auto-fetches Dehradun/Allahabad into cache.
3. **District / Family / HC:** ops drops HTML once per day into **`data/inbox/`** as  
   `{court_id}_{YYYY-MM-DD}.html` (see `backend/inbox.example/README.txt`). Cron parses → cache; lawyers do not upload.

| Method | Path | Auth |
|---|---|---|
| POST | `/api/cron/causelist-sync` | Header `X-Cron-Secret: …` — inbox + DRT refresh |
| GET | `/api/cron/causelist-status` | same — which dates are cached per court |

**Local cron (no HTTP):**

```powershell
cd backend
$env:MUNSHI_CRON_SECRET = "your-secret"
python -m app.jobs.causelist_cron
```

**HTTP (GitHub Actions / Render cron):** `backend/scripts/run-causelist-cron.ps1`

On **Render**, mount a **persistent disk** at `MUNSHI_DATA_DIR` (e.g. `/var/data/munshi`) so inbox + cache survive redeploys. Without disk, cache is ephemeral but still works until the next deploy.

Run **`backend/profiles_schema.sql`** in Supabase if you add new profile columns (includes `phone`).

`/api/bootstrap` returns **404** in vault mode (no server-side case seed).

## Admin / dev-only routes

`POST /api/dev/purge-auth-users` requires **all three**: `MUNSHI_DEMO=1`, a matching
`X-Admin-Token` header (`MUNSHI_ADMIN_TOKEN` in `.env`), and `SUPABASE_SERVICE_ROLE_KEY`
configured. It is a reset utility for a throwaway/demo Supabase project — it deletes
every real user account except the local demo addresses, unconditionally, with no
way to scope it to specific accounts. Never point it at a project with real users.

## Smoke tests

```powershell
cd backend
python -m pytest -q
```
