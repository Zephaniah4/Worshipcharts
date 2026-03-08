# Sync Protocol v1 (Offline First)

## Goals
- Allow create/edit from any platform.
- Propagate updates to all devices logged into the same account.
- Preserve writes while offline and reconcile safely after reconnect.

## Client Model
1. Write locally first into SQLite.
2. Create a `sync_operation` record with:
- `operation_id` (UUID)
- `device_id`
- `entity_type`
- `entity_id`
- `op_type`
- `payload`
- `client_created_at`
- `operation_hash` (idempotency key)
3. Push queued operations in chronological order when online.

## Server Model
1. Validate auth and team permissions.
2. Reject duplicates by `operation_hash`.
3. Apply operation in transaction.
4. Publish realtime event for affected users/devices.
5. Return authoritative `updated_at` and `version`.

## Cross-Device Propagation
1. Device A sends op and receives commit ack.
2. Backend publishes realtime event.
3. Devices B/C pull delta changes since cursor.
4. Devices apply remote updates and advance cursor.

## Conflict Strategy
- Baseline: field-level last-write-wins using `updated_at` and `version`.
- Critical text fields (lyrics/chords): optional conflict object with side-by-side merge UI.
- Setlist ordering conflicts: resolve by explicit `position` rebasing.

## Reliability Rules
- Sync loop retries with exponential backoff.
- Queue survives app restarts.
- Flush queue on reconnect and app foreground.
- Use idempotent APIs so retried operations are safe.

## Security
- Every operation scoped to authenticated user and team membership.
- Enforce role checks server-side.
- Store provider tokens encrypted.

## Recommended API Endpoints
- `POST /sync/ops/batch`
- `GET /sync/delta?since=<cursor>`
- `POST /integrations/songselect/import`
- `POST /integrations/planning-center/pull`
