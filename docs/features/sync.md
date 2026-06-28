# Sync (cloud metadata)

## Scope

**Local-first** metadata sync for **audio**, **video**, and **recording** rows:

- **Upload**: `POST /api/v1/mine/audios|videos|recordings` with JSON metadata only (no file blobs).
- **Outbound queue**: Drift table `sync_queue` (`entityType`, `entityId`, `action`, optional `payloadJson`, retries).
- **No automatic library mirror**: signing in does **not** download every remote audio/video/recording into the Library. Remote browsing is opt-in via the [Cloud](cloud.md) screen.

**Recording metadata** on the wire (`duration`, `referenceStart`, `referenceDuration`) uses **milliseconds**, matching the enjoy web/extension `Recording` type. The local Drift `recordings` row uses the same Dart field names (`duration`, `referenceStart`, `referenceDuration`); SQLite columns are `duration`, `reference_start`, `reference_duration`. Audio and video rows still use **seconds** for `duration` in their payloads.

### Lazy recording pull

When the user opens a media item in the player **while signed in**, the app pulls **recording metadata only** for that `(targetType, targetId)` from `GET /api/v1/mine/recordings` (paged with `updatedAfter`). Cursors live under `settings_kv` as `sync.cursor.recording.{TargetType}.{targetId}`. This replaces the old global “download all recordings” pass on sign-in.

### Import IDs (web parity)

Local file fingerprints use the same **partial SHA-256** strategy as the Enjoy web `hashBlob` helper in `apps/web/src/db/id-generator.ts` (first / middle / last 4 MiB). Signed-in imports use `aid` / `vid` = `SHA-256(contentHash + ":" + userId)` then UUID v5 (`audio:user:{aid}` / `video:user:{vid}`), matching `generateLocalAudioAid` / `generateLocalVideoVid` on web.

Imports while **signed out** use `aid`/`vid` = raw `contentHash` and `sync_status = local-pending-rekey`. On **sign-in**, [`rekeyLocalMediaRowsOnSignIn`](../../lib/features/sync/application/rekey_local_rows.dart) rewrites rows to the canonical ids and updates `transcripts`, `recordings`, `echo_sessions`, `dictations`, `transcript_fetch_states`, and `sync_queue` references, then enqueues upload where appropriate.

## Sync status (Settings)

**Settings → Cloud sync → Sync status** opens a screen that:

- Streams live counts from the local `sync_queue` table (**waiting to upload** vs **failed permanently** after max retries).
- Shows how many library rows are still **`local-pending-rekey`** (imported offline, waiting for the next sign-in migration).
- Shows **last successful full sync** time (stored in settings KV as `sync.last_full_sync_at` after a successful `fullSync`).
- Offers **Sync now** (queue processing only) and **Retry failed items** (resets exhausted rows then runs `fullSync`).

When signed out, the sync screen explains that sign-in is required and links to the sign-in flow.

## Triggers

- Signing in schedules **re-key** (if needed) then [`SyncEngine.fullSync`](../../lib/features/sync/application/sync_engine.dart) via [`SyncCtrl`](../../lib/features/sync/application/sync_controller.dart) on the **first frame after** auth transitions to signed-in (`addPostFrameCallback`).
- **Re-key** runs pending `local-pending-rekey` video/audio rows inside a **single Drift transaction** so dependent tables update in one batch (fewer `watchAll` emissions than per-row transactions).
- While signed in, queue drain repeats on a **5-minute** timer.
- Library import/delete and shadow-reading recording save/delete call [`syncEnqueueProvider`](../../lib/features/sync/application/sync_providers.dart).

## Conflict policy

Server wins when `server.updatedAt >= local.updatedAt`; local-only paths (`localUri`, `localPath`) are preserved on merge.

When the server accepts an upload but **omits** the `updatedAt` field in its response, [`SyncUploadService`](../../lib/features/sync/application/sync_upload_service.dart) throws a `SyncMissingUpdatedAtError` instead of silently stamping the row with `DateTime.now()`. The local `serverUpdatedAt` is preserved as-is and the queue row is marked for a follow-up pull — this prevents a clock-skewed "successful" upload from masking a real divergence on the next reconciliation. Callers should treat `SyncMissingUpdatedAtError` as a soft failure (retry eligible) rather than a hard conflict.

## Related

- [ADR-0010](../decisions/0010-cloud-sync-mvp.md) (historical bidirectional download scope)
- [ADR-0013](../decisions/0013-local-first-sync.md) (local-first + lazy recordings)
- [Cloud index](cloud.md)
- Web reference: `enjoy` monorepo `apps/web/src/db/services/sync-*.ts`, `apps/web/src/db/id-generator.ts`
