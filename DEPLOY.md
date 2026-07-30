# Deploy backend only → build APK → test on phone

**Render:** backend API only  
**Phone:** Flutter APK only (no web app)

Repo: **https://github.com/VektoAI/Lawyer_Mobile**

---

## Plan

1. Deploy **backend** on Render (you do this now)
2. Send me your live Render URL (e.g. `https://munshi-api.onrender.com`)
3. We build the APK with that URL baked in
4. Install on your phone and test sign-up, login, courts, etc.

---

## Important: `MUNSHI_FRONTEND_URL` is NOT a web app

The name is confusing. **There is no web frontend on Render.**

For **mobile-only**, set:

```
MUNSHI_FRONTEND_URL = same as your backend Render URL
```

Example: if backend is `https://munshi-api.onrender.com`, then:

```
MUNSHI_FRONTEND_URL=https://munshi-api.onrender.com
```

It is a legacy variable (from an old browser UI). The app on your phone uses **`MUNSHI_API_BASE`** at APK build time — that is the only URL that matters for the mobile app.

Email verification links are served by the **backend** at `/api/auth/confirm`, then redirect into the app via `casevault://auth/confirm`.

---

## Render env vars (backend only)

### Required

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | `https://yacyqfxaogynvdlohfeo.supabase.co` |
| `SUPABASE_ANON_KEY` | `sb_publishable_8bFiyh_91HKyZNrUsaXnWQ_rdfyEv-n` |
| `MUNSHI_DEMO` | `0` |
| `MUNSHI_SERVE_UI` | `0` |
| `MUNSHI_OPENAPI` | `1` (Swagger at `/api/docs`) |
| `MUNSHI_FRONTEND_URL` | **Same as your Render backend URL** (see above) |
| `MUNSHI_MOBILE_AUTH_REDIRECT` | `casevault://auth/confirm` |
| `MUNSHI_CRON_SECRET` | Random string you generate (see below) |
| `PYTHONUNBUFFERED` | `1` |

### Generate `MUNSHI_CRON_SECRET` (not from Supabase)

```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Copy the output into Render. Skip `MUNSHI_ADMIN_TOKEN`, Stripe, and service role key for now.

---

## Deploy on Render

**Dockerfile path:** `Dockerfile.api`  
**Health check:** `/healthz`

If repo not visible: GitHub → Settings → Applications → Render → allow **Lawyer_Mobile**.

---

## Supabase (one-time)

1. SQL Editor → run `backend/profiles_schema.sql`
2. Auth → URL configuration:
   - **Site URL:** your Render backend URL
   - **Redirect URLs:** `https://YOUR-RENDER-URL/**` and `casevault://auth/confirm`

---

## After deploy — send me the URL

```powershell
curl https://YOUR-RENDER-URL.onrender.com/healthz
```

When that returns `"ok": true`, share the URL and we will:

```powershell
.\scripts\build-apk.ps1 -ApiBase https://YOUR-RENDER-URL.onrender.com
adb install app\build\app\outputs\flutter-apk\app-debug.apk
```

Then test on your phone: guest mode, sign-up, email confirm, login, profile, court lookup.
