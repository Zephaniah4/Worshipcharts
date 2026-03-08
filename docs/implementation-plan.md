# Implementation Plan and Feature Mapping

Date: 2026-03-07

## Current Build Artifacts
- Flutter app starter in `apps/worship_app`.
- SQL schema in `backend/supabase/schema.sql`.
- Offline/cross-device sync design in `docs/sync-protocol.md`.
- Local persistent data store and persistent sync queue in app code.
- Supabase runtime initialization and sync API integration path.

## Requirement Coverage
1. Native app on all major platforms.
- Planned via Flutter targets: iOS, Android, Web, Windows, macOS, Linux.

2. Add/edit from any platform and update all others.
- Addressed through operation queue + realtime delta sync model.

3. Chord formatting and key-change with one tap.
- Starter `ChordEngine` and transpose controls implemented.

4. Setlist build and sharing.
- Starter setlist creation and song assignment in app.
- Team sharing represented in schema (`setlist_shares`).

5. Import from Ultimate Guitar and SongSelect/CCLI.
- Connector model and import tables in schema.
- Implementation must follow legal provider terms and APIs.

6. Integration with Planning Center Online.
- Integration account model and endpoint plan included.

7. Offline support.
- Local-first writes and queued sync operations in app architecture.

## Next Build Tasks (Priority)
1. Move from `SharedPreferences` to Drift/SQLite for richer querying and larger datasets.
2. Implement Supabase auth screens and session management.
3. Add delta pull endpoint/client handling so devices receive remote edits automatically.
4. Add collaborative setlist sharing screens and role management.
5. Implement importer connectors with provider-compliant auth.
6. Add test suite for sync conflicts and offline recovery.
