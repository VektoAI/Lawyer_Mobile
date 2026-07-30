# Munshi mobile (Flutter client)

Dart source only — this environment has no Flutter/Dart SDK installed, so the
native `android/`/`ios/`/`windows/` platform folders that `flutter create`
normally generates **do not exist yet** and were not hand-written (that's
generated boilerplate, not something to author by hand). None of this has
been compiled or run. Do that locally:

## One-time setup (once Flutter is installed)

```powershell
cd mobile/app

# Generates android/, ios/, web/, windows/, linux/, macos/ around the existing
# lib/ and pubspec.yaml without touching them. Pick a real org id when you
# have one — "com.example" is a placeholder, not for store submission.
flutter create --org com.example --project-name munshi_mobile .

flutter pub get

# drift needs code generation for app_database.g.dart (referenced via `part`
# in lib/db/app_database.dart) — this will fail to build until you run this:
dart run build_runner build --delete-conflicting-outputs

flutter run
```

## What's real vs. placeholder here

| File | Status |
|---|---|
| `lib/theme.dart` | Design tokens matching CLAUDE.md invariant 13 — real |
| `lib/db/app_database.dart` | Real drift schema (event-log model) — needs codegen, untested |
| `lib/crypto/vault_crypto.dart` | Mirrors `munshi-ui/vault.js`'s exact PBKDF2/AES-GCM scheme — untested, **not cross-checked against a real vault.js-produced envelope yet** |
| `lib/crypto/backup_import.dart` | Parses the real `munshi-vault-backup-v1` format — untested |
| `lib/services/sync_service.dart` | Talks to `../backend/` — untested |
| `lib/screens/*.dart` | Placeholder UI only, not wired to the db/crypto layers |

## Naming

Package name is `munshi_mobile` (internal codename, matches the existing
`munshi-ui/` convention). The **display name and bundle ID must not ship
publicly under "Munshi"** — a live competitor (MyMunshi) exists in this exact
market (CLAUDE.md invariant 12). Rename is tracked in ROADMAP.md 2.2.

## Relationship to the PWA

`munshi-ui/` is not going away — see
[docs/Munshi_Scale_Up_Architecture.html](../../docs/Munshi_Scale_Up_Architecture.html)
§10: "Phase A ships value on the PWA first; PWA stays live as web fallback."
This Flutter app is the Phase B target, built against the same zero-knowledge
principle, not a replacement shipped before it's ready.
