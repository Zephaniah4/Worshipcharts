# Testing Strategy and Quality Gates

## What "Good Point" Means
A good test-ready point is when all items below pass consistently:
1. Unit tests pass (`flutter test`).
2. App launches on at least one mobile and one desktop target.
3. Offline create/edit works after app restart.
4. Sync queue persists offline operations and flushes on reconnect.
5. No critical errors in editor diagnostics.

## Test Layers
1. Unit tests
- Chord transposition correctness.
- Model serialization/deserialization.
- Sync queue operation behavior.

2. Widget/smoke tests
- App startup stability.
- Core screens render (Songs, Setlists, Integrations).

3. Manual offline tests
- Turn internet off.
- Add/edit song, build setlist, close app.
- Reopen app and verify data still present.

4. Sync tests
- Log into same account on two devices.
- Device A edits a song.
- Device B receives update after sync/reconnect.

5. Integration tests
- SongSelect/Planning Center auth and import flow.
- Error handling for expired tokens/rate limits.

## Suggested Pre-Beta Checklist
- [ ] `flutter test` is green.
- [ ] Android or iOS run is stable for 30+ min use.
- [ ] Windows or macOS run is stable for 30+ min use.
- [ ] Offline mode validated with restart.
- [ ] Sync across two devices validated.
- [ ] Import pathways tested with real licensed credentials.

## Commands
From `apps/worship_app`:
- `flutter pub get`
- `flutter test`
- `flutter analyze`
- `flutter run`

If `flutter` is not on PATH yet, run with Puro executable directly:
- `& "C:\\Users\\ojzhi\\AppData\\Local\\Microsoft\\WinGet\\Packages\\pingbird.Puro_Microsoft.Winget.Source_8wekyb3d8bbwe\\puro.exe" flutter pub get`
- `& "C:\\Users\\ojzhi\\AppData\\Local\\Microsoft\\WinGet\\Packages\\pingbird.Puro_Microsoft.Winget.Source_8wekyb3d8bbwe\\puro.exe" flutter test`
- `& "C:\\Users\\ojzhi\\AppData\\Local\\Microsoft\\WinGet\\Packages\\pingbird.Puro_Microsoft.Winget.Source_8wekyb3d8bbwe\\puro.exe" flutter analyze`

With Firebase runtime config:
- Configure Firebase for platform targets (`flutterfire configure`).
- Ensure Firebase config files are available for the run target.

## CI Pipeline
- GitHub Actions workflow: `.github/workflows/flutter-ci.yml`
- Runs on push and pull request:
	- `flutter pub get`
	- `flutter analyze`
	- `flutter test`

## In-App Test Mode
In the Integrations tab, use Test Mode to:
- Toggle simulated network availability.
- Queue synthetic operations.
- Flush queue and verify offline/online behavior.

## Auth and Remote Sync Validation
In the Integrations tab:
- Sign up or sign in with Firebase Auth credentials.
- Confirm account state is shown in UI.
- Use `Pull Remote` and verify remote song/setlist updates are applied locally.
- Keep app open and confirm periodic auto-sync after login (every ~12s).

## Latest Verification (2026-03-08)
- `flutter pub get`: success
- `flutter test`: success (`All tests passed`)
- `flutter analyze`: success (`No issues found`)
