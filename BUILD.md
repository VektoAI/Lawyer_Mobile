# Building Case Vault (APK / web / iOS)

The **APK is built on your PC** and installed on a phone — Render hosts the **API** and optional **web** app only.

## Prerequisites

- Flutter stable (3.22+), Android SDK
- API running locally or deployed on Render (`munshi-api`)

```powershell
cd app && flutter pub get
```

---

## Quick scripts (from repo root)

```powershell
# Debug APK → sideload on phone
.\scripts\build-apk.ps1 -ApiBase https://munshi-api.onrender.com -Mode debug

# Release APK
.\scripts\build-apk.ps1 -ApiBase https://munshi-api.onrender.com -Mode release

# Flutter web (same as casevault-web on Render)
.\scripts\build-web.ps1 -ApiBase https://munshi-api.onrender.com
```

APK output: `app/build/app/outputs/flutter-apk/app-debug.apk` (or `app-release.apk`)

---

## Run on device / emulator

```powershell
cd app

# Local API
flutter run --dart-define=MUNSHI_API_BASE=http://127.0.0.1:4173

# Render API
flutter run --dart-define=MUNSHI_API_BASE=https://munshi-api.onrender.com

# Android emulator (local API)
flutter run --dart-define=MUNSHI_API_BASE=http://10.0.2.2:4173
```

**Network tips:**
- Emulator → local API: `http://10.0.2.2:4173`
- USB phone on same Wi‑Fi → use your PC's LAN IP, not `127.0.0.1`
- Guest mode works offline; sign-in needs live API

---

## Install APK on phone

```powershell
adb install app\build\app\outputs\flutter-apk\app-debug.apk
```

Or copy the APK to the phone and install manually (enable "Install unknown apps").

The login screen shows `API: munshi-api.onrender.com` — confirms the baked-in URL.

---

## Email verification (mobile)

1. Supabase redirect URL: `casevault://auth/confirm`
2. Email link opens `https://munshi-api.onrender.com/api/auth/confirm?...`
3. API verifies token → redirects to `casevault://auth/confirm#access_token=...`
4. App opens via deep link (configured in `AndroidManifest.xml`)

---

## Android release / Play Store

```powershell
flutter build appbundle --release --dart-define=MUNSHI_API_BASE=https://munshi-api.onrender.com
```

Before store upload:
- Edit `version:` in `app/pubspec.yaml`
- Add a release keystore in `android/app/build.gradle.kts` (currently uses debug signing)
- Rename internal "Munshi" codename in display strings if needed

---

## iOS

```bash
cd app && flutter build ios --release --dart-define=MUNSHI_API_BASE=https://munshi-api.onrender.com
```

Open `ios/Runner.xcworkspace` in Xcode → Archive.

---

## Web (browser)

Hosted on Render as **casevault-web**, or run locally:

```powershell
cd app
flutter run -d chrome --dart-define=MUNSHI_API_BASE=https://munshi-api.onrender.com
```

Web email confirm uses the API HTML page (no `casevault://` deep link in browser).
