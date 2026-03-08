# Worship Music App Monorepo

Cross-platform worship music chord display app starter.

## Project Layout
- `apps/worship_app`: Flutter client (mobile, desktop, web)
- `backend/supabase/schema.sql`: Postgres schema + RLS scaffolding
- `backend/firebase/firestore.rules`: Firestore security rule starter
- `docs/sync-protocol.md`: Offline-first and cross-device sync protocol
- `docs/implementation-plan.md`: Build plan and feature mapping

## Quick Start (Flutter)
1. Install Flutter stable channel.
2. From `apps/worship_app` run `flutter pub get`.
3. Run with `flutter run` on your preferred target.

Optional Firebase setup:
- Add Firebase app configuration for each target platform.
- Run `flutterfire configure` from `apps/worship_app` to generate app bindings.
- Ensure platform config files are present (`google-services.json`, `GoogleService-Info.plist`, etc.).

## Current Status
This repository contains a production-oriented starter architecture with:
- Song and setlist models
- Chord transposition engine
- Local-first persistent storage via Drift/SQLite
- Persistent sync queue and Firebase sync API plumbing
- Initial UI screens for song and setlist workflows
- Firebase-ready cloud sync integration path

## Testing
From `apps/worship_app`:
- `flutter test`
- `flutter analyze`

Integration test scaffold:
- `integration_test/offline_sync_smoke_test.dart`

Detailed quality gates and manual test scenarios:
- `docs/testing-strategy.md`

CI workflow:
- `.github/workflows/flutter-ci.yml`
- `.github/workflows/firebase-hosting.yml`

Deployment status:
- PR preview deployment and `main` live deployment are configured through GitHub Actions + Firebase Hosting.

Firebase Hosting deployment guide:
- `docs/firebase-hosting-github-actions.md`

Release checklist:
- `docs/release-checklist.md`

## Notes on Imports
Integrations for SongSelect/CCLI and Ultimate Guitar must follow provider licensing and terms. The backend schema and docs are prepared for compliant connector implementations.
