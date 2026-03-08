# Release Checklist

Use this checklist for every release to keep the Firebase deployment path stable and repeatable.

## Preconditions
- GitHub repository: `https://github.com/Zephaniah4/Worshipcharts`
- Firebase project ID: `worship-charts-c0b65`
- Workflow files exist:
  - `.github/workflows/flutter-ci.yml`
  - `.github/workflows/firebase-hosting.yml`

## One-Time Setup Validation
- GitHub Actions secrets are present:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_SERVICE_ACCOUNT`
- `firebase.json` contains both:
  - `hosting` config
  - `firestore.rules` target (`backend/firebase/firestore.rules`)
- Flutter Firebase config exists:
  - `apps/worship_app/lib/firebase_options.dart`

## Pre-Release Local Checks
From `apps/worship_app`:

```bash
flutter pub get
flutter test
flutter analyze
flutter build web --release
```

## PR Flow
1. Create branch from `main`.
2. Push branch and open PR.
3. Verify checks:
   - `Flutter CI / build-and-test`
   - `Firebase Hosting Deploy / build_and_deploy`
4. Confirm Firebase preview URL appears in PR checks/comments.

## Merge Flow
1. Merge PR into `main`.
2. Open GitHub `Actions` and verify latest `Firebase Hosting Deploy` run on `main` is green.
3. Open Firebase Console -> Hosting and verify a new live release exists.

## Common Failures
- `Invalid workflow file` with `Unrecognized named-value: 'secrets'`:
  - Do not use `secrets.*` directly inside workflow `if:` expressions.
  - Gate deploy steps with outputs from a prior secret-check step.
- `unable to find version v1` for hosting action:
  - Use `FirebaseExtended/action-hosting-deploy@v0`.
- Web compile errors related to SQLite:
  - Keep sqlite implementation out of web builds using conditional exports:
    - `local_database_io.dart` for native
    - `local_database_web.dart` for web

## Security Note
- Never paste service account JSON in chat, tickets, or commits.
- If a key is exposed, rotate it immediately and update `FIREBASE_SERVICE_ACCOUNT` secret.
