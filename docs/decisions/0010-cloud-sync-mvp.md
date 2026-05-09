# ADR-0010: Cloud sync MVP (metadata)

## Status

Accepted

## Context

ADR-0005 scoped MVP away from cloud sync. The product still needs offline-first parity with the Enjoy web app for media metadata once auth exists (ADR-0006). Binary uploads (ActiveStorage) are deferred.

## Decision

Ship **metadata-only** bidirectional sync for:

- `audios`
- `videos`
- `recordings`

Implementation lives under `lib/features/sync/`:

- Drift `sync_queue` for outbound operations (aligned with web Dexie queue).
- Download merge uses **last-write-wins** on `updatedAt`, preserving local-only columns (`localUri`, `localPath`).
- `SyncCtrl` runs a **full sync** when the session becomes signed-in and drains the upload queue every **5 minutes** while signed in.
- Local mutations enqueue via `syncEnqueueProvider` (library import, recording save/delete).

Explicitly **not** in this ADR: transcript sync, echo session sync, media byte uploads, vocabulary/ebooks.

## Consequences

- Users can sign in on desktop and see server-side metadata for these entities; local files remain on disk until a future ADR adds ActiveStorage uploads.
- ADR-0005 remains historically accurate for the original MVP cut; this ADR **supersedes** only the “cloud sync excluded” bullet for the entities listed above.
