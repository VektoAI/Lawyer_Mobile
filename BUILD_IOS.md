# Building Case Vault for iPhone (Mac required)

Flutter's iOS toolchain only runs on macOS — this **cannot** be done from the
Windows PC used for the Android build. This guide is for whoever on the team
has a Mac.

The app talks to the same production backend as the Android build — you are
not standing up a second backend, just compiling the client against the URL
that's already live on Render: `https://munshi-api.onrender.com`.

---

## 1. One-time Mac setup

- **Xcode** — install from the Mac App Store (full app, not just Command Line
  Tools), then open it once and accept the license.
- **Flutter SDK** — https://docs.flutter.dev/get-started/install/macos
  Verify with:
  ```bash
  flutter doctor
  ```
  Resolve anything it flags under the "Xcode" and "Connected device" sections
  before continuing. CocoaPods is required — if `flutter doctor` flags it
  missing:
  ```bash
  sudo gem install cocoapods
  ```
- **An Apple ID** signed into Xcode (Xcode → Settings → Accounts → **+**).
  A free Apple ID works for installing to your own cabled iPhone; a paid
  Apple Developer Program membership ($99/year) is required for TestFlight
  or Ad Hoc distribution to other people's phones (see §4).

## 2. Get the code

```bash
git clone https://github.com/VektoAI/Lawyer_Mobile.git
cd Lawyer_Mobile/app
```

(If you already have the repo, just `git pull` on `main` — the same commit
the Android APK was built from.)

## 3. Install dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

`pod install` resolves the native iOS dependencies (CocoaPods) — this step
has no Android equivalent, don't skip it.

## 4. Choose a distribution path

### A. Fastest — run straight to your own iPhone (free Apple ID is enough)

Plug the iPhone in via cable, unlock it, and tap "Trust This Computer" if
prompted. Then:

```bash
flutter devices          # confirm the iPhone shows up
flutter run --release --dart-define=MUNSHI_API_BASE=https://munshi-api.onrender.com -d <device-id>
```

First run will prompt you to open `ios/Runner.xcworkspace` in Xcode to pick a
signing **Team** (Runner target → Signing & Capabilities → Team → your Apple
ID) — Xcode auto-manages the provisioning profile from there. On a **free**
Apple ID, the install expires after 7 days and needs re-running; a paid
account doesn't expire until the normal annual certificate renewal.

The first time the app launches, the iPhone will refuse to open it until you
go to **Settings → General → VPN & Device Management** and trust your
developer certificate.

### B. Distributing to other testers' iPhones — TestFlight (needs a paid Apple Developer account)

This is the iOS equivalent of handing someone an APK — no cable required on
their end.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Confirm signing: Runner target → Signing & Capabilities → Team → your
   paid Developer Program team, "Automatically manage signing" checked.
3. Set the build/version in `app/pubspec.yaml`'s `version:` line if this is
   a new release (`versionName+versionCode`, mirrors what you'd do for the
   Play Store).
4. Product → Destination → **Any iOS Device (arm64)**.
5. Product → Archive. When it finishes, the Organizer window opens
   automatically.
6. In Organizer: **Distribute App** → **TestFlight & App Store** → follow the
   prompts to upload to App Store Connect.
7. In [App Store Connect](https://appstoreconnect.apple.com) → your app →
   TestFlight tab: add internal/external testers by email. They install the
   **TestFlight** app from the App Store, accept your invite, and install
   Case Vault from there — no Xcode or cable needed on their side.

Internal testers (same App Store Connect team) see new builds within
minutes. External testers require a one-time "Beta App Review" (usually
same-day) the first time.

## 5. Confirm the backend URL baked in

Whichever path you used, open the app's sign-in screen — it prints
`API: munshi-api.onrender.com` near the bottom. If it shows anything else
(e.g. a `127.0.0.1` or `10.0.2.2` address), the build picked up a stale
`--dart-define` — rebuild with the flag shown in §4A explicitly.

## 6. Common issues

| Symptom | Fix |
|---|---|
| `CocoaPods not installed` in `flutter doctor` | `sudo gem install cocoapods`, then `cd ios && pod install` |
| Xcode build fails on signing | Runner target → Signing & Capabilities → pick your Team; make sure "Automatically manage signing" is on |
| App installs but won't open ("Untrusted Developer") | Settings → General → VPN & Device Management → trust the certificate |
| `flutter devices` doesn't list the iPhone | Unlock the phone, tap "Trust This Computer", and make sure it's on iOS 12+ |
| Free Apple ID build stops working after a week | Expected — free-account provisioning profiles expire after 7 days; re-run `flutter run` |

## Reference

- Bundle identifier: `in.vekto.casevault` (Xcode: Runner target → General → Identity)
- Display name on the home screen: **Case Vault** — the "Munshi" name in
  `pubspec.yaml`/package identifiers is an internal codename only and never
  appears in user-facing text (see `CLAUDE.md` invariant 12); nothing to
  change here before distributing.
- For local API testing instead of the production URL, see the "Run on
  device / emulator" section of `BUILD.md`.
