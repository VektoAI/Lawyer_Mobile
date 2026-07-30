# Case Vault — mobile app + API

Flutter client + FastAPI backend. Case data is **encrypted on device**; the server handles auth, profiles, and court metadata only.

## Layout

```
casevault/
├── app/              Flutter (Android APK, iOS, web)
├── backend/          FastAPI — auth, courts, cron
├── sync-backend/     Future E2EE sync (not production)
├── Dockerfile.api    Backend image → Render munshi-api
├── Dockerfile.web    Flutter web → Render casevault-web
├── render.yaml       Render Blueprint (both services)
└── scripts/          build-apk.ps1, build-web.ps1
```

## Quick start (local)

**API:**

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 4173 --reload
```

**Flutter:**

```powershell
cd app
flutter pub get
flutter run --dart-define=MUNSHI_API_BASE=http://127.0.0.1:4173
```

## Deploy (Render)

1. Push repo to GitHub
2. Render → Blueprint → apply `render.yaml`
3. Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MUNSHI_CRON_SECRET` in dashboard
4. Run `backend/profiles_schema.sql` in Supabase

Full guide: **`DEPLOY.md`**

| Service | Hosts |
|---------|-------|
| `munshi-api` | Backend API |
| `casevault-web` | Flutter web (browser) |
| Local APK | Built with `scripts/build-apk.ps1` — **not** on Render |

## Build APK for phone

```powershell
.\scripts\build-apk.ps1 -ApiBase https://munshi-api.onrender.com
adb install app\build\app\outputs\flutter-apk\app-debug.apk
```

See **`BUILD.md`**.

## Tests

```powershell
cd backend
python -m pytest tests/ -q
```

## Invariants

- Integer rupees; append-only event log on client
- Honest court sync errors
- No server-side case vault
