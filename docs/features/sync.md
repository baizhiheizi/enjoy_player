# Sync (cloud metadata)

## Scope

Offline-first sync for **audio**, **video**, and **recording** rows:

- **Upload**: `POST /api/v1/mine/audios|videos|recordings` with JSON metadata only (no file blobs).
- **Download**: paginated `GET` with `updatedAfter` + `limit`, cursors in `settings_kv` (`sync.cursor.*`).
- **Outbound queue**: Drift table `sync_queue` (`entityType`, `entityId`, `action`, optional `payloadJson`, retries).

## Triggers

- Signing in runs a **full sync** (download three entities, then process queue) via [`SyncCtrl`](../../lib/features/sync/application/sync_controller.dart).
- While signed in, queue drain repeats on a **5-minute** timer.
- Library import/delete and shadow-reading recording save/delete call [`syncEnqueueProvider`](../../lib/features/sync/application/sync_providers.dart).

## Conflict policy

Server wins when `server.updatedAt >= local.updatedAt`; local-only paths (`localUri`, `localPath`) are preserved on merge.

## Related

- [ADR-0010](../decisions/0010-cloud-sync-mvp.md)
- Web reference: `enjoy` monorepo `apps/web/src/db/services/sync-*.ts`
