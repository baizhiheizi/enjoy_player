# Sync (cloud metadata)

## Scope

**Local-first** metadata sync for **audio**, **video**, and **recording** rows:

- **Upload**: `POST /api/v1/mine/audios|videos|recordings` with JSON metadata only (no file blobs).
- **Outbound queue**: Drift table `sync_queue` (`entityType`, `entityId`, `action`, optional `payloadJson`, retries).
- **No automatic library mirror**: signing in does **not** download every remote audio/video/recording into the Library. Remote browsing is opt-in via the [Cloud](cloud.md) screen.

### Vocabulary (items + contexts) — auto-pull exception

[ADR-0054](../decisions/0054-vocabulary-cloud-sync.md) extends the entities above with **vocabulary items** and **vocabulary contexts** (`SyncEntityType.vocabularyItem` / `.vocabularyContext`, wire `vocabulary_item` / `vocabulary_context`):

- **Upload**: `POST /api/v1/mine/vocabulary_items|vocabulary_contexts` via [`VocabularyApi`](../../lib/data/api/services/vocabulary_api.dart), same envelope shape as audio/video (`{ vocabularyItem: {…} }` / `{ vocabularyContext: {…} }`).
- **Auto-pull on every signed-in `fullSync`** — unlike audio/video/recording above, vocabulary **is** mirrored automatically (paged by `updatedAfter` cursors `sync.cursor.vocabulary_item` / `sync.cursor.vocabulary_context`). This is a deliberate, narrow exception to the no-auto-mirror policy: a word book is a cross-device dataset, not local-path media.
- **Item conflict is SRS-preserving**, not plain last-write-wins: [`resolveVocabularyItemConflict`](../../lib/features/vocabulary/domain/vocabulary_item_conflict.dart) keeps whichever side's spaced-repetition activity (`lastReviewedAt`, else `reviewsCount`) is fresher, and only adopts the other side's `word` / `explanation` when that side's `updatedAt` is newer than the SRS-winning side's review reference. **Context conflict** stays plain LWW on `updatedAt` (server wins ties).
- **Review audits (`vocabulary_reviews`) never sync** — never uploaded, never downloaded, never enqueued. Undo history is per-device only.
- Enqueued from [`VocabularyRepository`](../../lib/features/vocabulary/data/vocabulary_repository.dart): item/context `create` on `addWithContext`, item `update` on `markReviewed` / `undoLatestReview` / explanation write-through / context-count bump, item `delete` after the local cascade (contexts + reviews) on `deleteItem`.

**Recording metadata** on the wire (`duration`, `referenceStart`, `referenceDuration`) uses **milliseconds**, matching the enjoy web/extension `Recording` type. The local Drift `recordings` row uses the same Dart field names (`duration`, `referenceStart`, `referenceDuration`); SQLite columns are `duration`, `reference_start`, `reference_duration`. Audio and video rows still use **seconds** for `duration` in their payloads.

### Lazy recording pull

When the user opens a media item in the player **while signed in**, the app pulls **recording metadata only** for that `(targetType, targetId)` from `GET /api/v1/mine/recordings` (paged with `updatedAfter`). Cursors live under `settings_kv` as `sync.cursor.recording.{TargetType}.{targetId}`. This replaces the old global “download all recordings” pass on sign-in.

### Import IDs (web parity)

Local file fingerprints use the same **partial SHA-256** strategy as the Enjoy web `hashBlob` helper in `apps/web/src/db/id-generator.ts` (first / middle / last 4 MiB). Signed-in imports use `aid` / `vid` = `SHA-256(contentHash + ":" + userId)` then UUID v5 (`audio:user:{aid}` / `video:user:{vid}`), matching `generateLocalAudioAid` / `generateLocalVideoVid` on web. Imports require a signed-in session (ADR-0031); there is no signed-out import or re-key path.

## Sync status (Settings)

**Settings → Cloud sync → Sync status** opens a screen that:

- Streams live counts from the local `sync_queue` table (**waiting to upload** vs **failed permanently** after max retries).
- Shows **last successful full sync** time (stored in settings KV as `sync.last_full_sync_at` after a successful `fullSync`).
- Offers **Sync now** (queue processing only) and **Retry failed items** (resets exhausted rows then runs `fullSync`).

When signed out, the sync screen explains that sign-in is required and links to the sign-in flow.

## Triggers

- Signing in schedules [`SyncEngine.fullSync`](../../lib/features/sync/application/sync_engine.dart) via [`SyncCtrl`](../../lib/features/sync/application/sync_controller.dart) on the **first frame after** auth transitions to signed-in (`addPostFrameCallback`).
- While signed in, queue drain repeats on a **5-minute** timer.
- Library import/delete and shadow-reading recording save/delete call [`syncEnqueueProvider`](../../lib/features/sync/application/sync_providers.dart).

## Conflict policy

Server wins when `server.updatedAt >= local.updatedAt`; local-only paths (`localUri`, `localPath`) are preserved on merge.

When the server accepts an upload but **omits** the `updatedAt` field in its response, [`SyncUploadService`](../../lib/features/sync/data/sync_upload_service.dart) throws a `SyncMissingUpdatedAtError` instead of silently stamping the row with `DateTime.now()`. The local `serverUpdatedAt` is preserved as-is and the queue row is marked for a follow-up pull — this prevents a clock-skewed "successful" upload from masking a real divergence on the next reconciliation. Callers should treat `SyncMissingUpdatedAtError` as a soft failure (retry eligible) rather than a hard conflict.

**Vocabulary exception:** older `POST /mine/vocabulary_items|vocabulary_contexts` responses were only `{ success: true }` (`len=16`). The client refetches `GET …/:id` when the create body lacks `updatedAt`. The API should return the persisted row via `render :show` (same shape as GET show).

### Library membership (UserVideo)

Mine video APIs mean **library membership**, not exclusive ownership of the catalog `Video` row. Many users can enroll the same YouTube/Netflix (or new content-addressed upload) id. `DELETE /mine/videos/:id` leaves the library (soft-deletes membership); pulls may include `deletedAt` tombstones — the player removes the local row.

New local uploads use **content-addressed** ids: `vid = contentHash` (no `userId`), `id = uuid_v5(video:user:{vid})`. Legacy per-user upload ids on the server are left as-is.

### Duplicate create recovery

On rare unique races during `POST /mine/videos`, the client retries with `GET /mine/videos/:id`. If that 404s, sync marks the queue item permanently failed (`SyncDuplicateMissingError`). Public catalog GET is no longer used for ownership recovery.

## Related

- [ADR-0010](../decisions/0010-cloud-sync-mvp.md) (historical bidirectional download scope)
- [ADR-0013](../decisions/0013-local-first-sync.md) (local-first + lazy recordings)
- [ADR-0054](../decisions/0054-vocabulary-cloud-sync.md) (vocabulary items/contexts, SRS-preserving conflict, auto-pull exception)
- [Cloud index](cloud.md)
- [Vocabulary](vocabulary.md)
- Web reference: `enjoy` monorepo `apps/web/src/db/services/sync-*.ts`, `apps/web/src/db/id-generator.ts`
