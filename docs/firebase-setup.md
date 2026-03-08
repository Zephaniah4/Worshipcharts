# Firebase Setup Guide

## 1. Create Project
- Open Firebase Console.
- Create a new project (or reuse your existing one).
- Enable Firestore Database (Native mode).
- Enable Firebase Authentication with Email/Password.

## 2. Register App Targets
From `apps/worship_app` run:

```bash
flutterfire configure
```

This generates platform-aware Firebase bindings for Flutter.

## 3. Platform Config Files
Ensure config files are present for each target you use:
- Android: `android/app/google-services.json`
- iOS/macOS: `ios/Runner/GoogleService-Info.plist`, `macos/Runner/GoogleService-Info.plist`
- Web: generated in FlutterFire options

## 4. Firestore Rules
Deploy starter rules from `backend/firebase/firestore.rules`.

## 5. Data Collections
The app expects these Firestore collections:
- `songs`
- `setlists`
- `setlists/{setlistId}/shares`
- `sync_operations`

## 6. Verify In App
- Start app.
- Open `Integrations` tab.
- Sign up/sign in with Firebase Auth credentials.
- Add songs/setlists and use `Pull Remote` to validate cloud roundtrip.

## 7. GitHub Hosting/CI (Optional)
- Use GitHub Actions for Flutter web build.
- Deploy web build artifacts to Firebase Hosting.
