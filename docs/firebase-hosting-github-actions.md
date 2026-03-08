# Firebase Hosting + GitHub Actions

## What This Enables
- Automatic Flutter web build on GitHub Actions.
- PR preview deploys to Firebase Hosting preview channels.
- Live deploy to Firebase Hosting on push to `main`.

## Files Added
- `.github/workflows/firebase-hosting.yml`
- `firebase.json`

## Required GitHub Secrets
Add these repository secrets:
- `FIREBASE_PROJECT_ID`: Your Firebase project ID.
- `FIREBASE_SERVICE_ACCOUNT`: JSON for a Firebase deploy service account key.

## Service Account Setup
1. Open Google Cloud Console for your Firebase project.
2. Create a service account for CI deploys.
3. Grant role: `Firebase Hosting Admin` (and minimal required read roles).
4. Create JSON key.
5. Store full JSON content in GitHub secret `FIREBASE_SERVICE_ACCOUNT`.

## Notes
- The workflow runs tests and analysis before deploy.
- If `apps/worship_app/web` is missing, CI scaffolds it with `flutter create . --platforms=web`.
- `firebase.json` is configured for SPA routing with rewrite to `/index.html`.

## First Deployment Check
1. Push a branch and open a PR to confirm preview URL is posted.
2. Merge to `main` to trigger live deploy.
3. Open Firebase Hosting console and verify latest release.
