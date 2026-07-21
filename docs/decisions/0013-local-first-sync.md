# ADR-0013: Local-first cloud sync (player)

## Status

Accepted

## Context

ADR-0010 shipped metadata sync including **automatic download** of all remote audios, videos, and recordings on sign-in. For a **desktop player**, the Library should reflect **local Drift** only; mirroring the entire cloud catalog blurs "what is on this machine" and conflicts with MVP expectations (local files, optional account).

The web app uses deterministic IDs for local uploads (`hashBlob` + `sha256(contentHash:userId)` + UUID v5). The player must match that so the same file for the same user maps to one remote row.

## Decision

1. **Stop auto-pulling** remote `audios` / `videos` / global `recordings` into SQLite on `SyncEngine.fullSync`. `fullSync` means **outbound queue drain** only.
2. **Cloud page**: optional UI to page remote audios/videos and **copy** selected rows into the local DB (`Add to library`).
3. **Recordings**: when **signed in**, pull metadata **per media target** when the player opens that target (`GET …/recordings?targetId=&targetType=`), with a per-target `updatedAfter` cursor in `settings_kv`.
4. **IDs**: align with Enjoy web `apps/web/src/db/id-generator.ts` — partial file SHA-256 for `md5` / content hash; signed-in `aid` = `SHA-256(contentHash + ":" + userId)` (audio). Video uploads now use content-addressed ids per [ADR-0056](0056-uservideo-library-membership.md) (`vid = contentHash`, no `userId` salt); the per-user `vid` scheme applies only to legacy video rows. Signed-out imports and `local-pending-rekey` were removed with login-only access ([ADR-0031](0031-login-only-access.md)).

## Consequences

- ADR-0010 remains the historical record for "metadata sync exists"; this ADR **supersedes** its automatic **download-all-on-sign-in** behavior for Enjoy Player.
- [ADR-0056](0056-uservideo-library-membership.md) partially supersedes Decision #4: new video uploads are content-addressed (no `userId` salt); audio ids remain user-scoped.
- Users who relied on the old "everything appears in Library after sign-in" flow must use **Cloud → Add to library** (or re-import local files).
- Fewer large SQLite merges on sign-in; recording API traffic moves to **on-demand** per played title.
