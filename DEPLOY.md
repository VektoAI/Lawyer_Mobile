# Deploying to Render (backend + web)

This repo deploys **two** Render services from `render.yaml`:

| Service | URL (default) | Purpose |
|---------|---------------|---------|
| **munshi-api** | `https://munshi-api.onrender.com` | FastAPI backend — auth, courts, cron |
| **casevault-web** | `https://casevault-web.onrender.com` | Flutter web app (browser) |

The **Android APK is built locally** (not on Render). See `BUILD.md` and `scripts/build-apk.ps1`.

Case data stays encrypted on the device — the server never stores cases.

---

## 1. Push to GitHub

```powershell
cd c:\Users\omkar\Documents\vekto\casevault
git add .
git commit -m "Render deploy: API + web"
git push origin main
```

## 2. Apply Render Blueprint

1. [render.com](https://render.com) → **New +** → **Blueprint**
2. Connect your GitHub repo
3. **Apply** — creates `munshi-api` and `casevault-web`

## 3. Set secrets (munshi-api service → Environment)

These are marked `sync: false` in `render.yaml` — you must set them in the dashboard:

| Variable | Required | Notes |
|----------|----------|-------|
| `SUPABASE_URL` | **Yes** | e.g. `https://xxxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | **Yes** | Supabase publishable anon key |
| `MUNSHI_CRON_SECRET` | Recommended | Random 32+ chars — protects cron endpoint |
| `MUNSHI_ADMIN_TOKEN` | Optional | Admin/dev routes; cron fallback |
| `STRIPE_WEBHOOK_SECRET` | Optional | When billing goes live |
| `SUPABASE_SERVICE_ROLE_KEY` | Optional | Dev purge route only |

Generate a secret:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Non-secret vars are already in `render.yaml` (`MUNSHI_DEMO=0`, `MUNSHI_FRONTEND_URL`, etc.).

### Optional: persistent disk (causelist cache)

Render Dashboard → **munshi-api** → **Disks** → add disk mounted at `/data`.  
`MUNSHI_DATA_DIR=/data` is already set in `render.yaml`.

## 4. Supabase setup

1. Run `backend/profiles_schema.sql` in Supabase → **SQL Editor**
2. **Authentication → URL Configuration:**
   - **Site URL:** `https://munshi-api.onrender.com`
   - **Redirect URLs:**
     - `https://munshi-api.onrender.com/**`
     - `casevault://auth/confirm`
3. **Email template** (Confirm signup) — link:
   ```
   {{ .SiteURL }}/api/auth/confirm?token_hash={{ .TokenHash }}&type=signup
   ```

## 5. Verify deployment

```powershell
curl https://munshi-api.onrender.com/healthz
```

Expected:

```json
{"ok": true, "mode": "api-only", "supabase": true, "demo": false}
```

Web app: open `https://casevault-web.onrender.com` in a browser.

> **Free tier:** services sleep after ~15 min idle. First request after sleep may take 30–60 seconds.

## 6. Build APK (local — points at Render API)

```powershell
.\scripts\build-apk.ps1 -ApiBase https://munshi-api.onrender.com -Mode debug
adb install app\build\app\outputs\flutter-apk\app-debug.apk
```

## Cron (cause-list sync)

POST `https://munshi-api.onrender.com/api/cron/causelist-sync` with header `X-Cron-Secret: <MUNSHI_CRON_SECRET>`.

Use Render Cron Jobs, GitHub Actions, or `backend/scripts/run-causelist-cron.ps1` locally. See `backend/README.md`.

## Files

| File | Role |
|------|------|
| `Dockerfile.api` | Backend Docker image |
| `Dockerfile.web` | Flutter web build + nginx |
| `render.yaml` | Blueprint for both services |
| `docker/` | nginx config + web build script |
| `scripts/build-apk.ps1` | Local APK build |
| `scripts/build-web.ps1` | Local web build |
