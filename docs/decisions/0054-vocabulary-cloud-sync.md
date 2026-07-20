# ADR-0054: Vocabulary cloud sync

## Status

Accepted

## Context

ADR-0052 shipped a local-first vocabulary book (`vocabulary_items`, `vocabulary_contexts`, `vocabulary_reviews`) with sync bookkeeping columns already present but explicitly deferred `SyncEntityType` wiring pending a dedicated conflict policy. Plain last-write-wins on `updatedAt` — the policy ADR-0010 uses for audio/video/recording — is unsafe for a spaced-repetition word: a metadata-only edit on device A (e.g. re-fetching a dictionary explanation) could otherwise clobber newer review progress made on device B. Enjoy web solves this with a dedicated `resolveVocabularyItemConflict` merge; this ADR ports that behavior to Flutter and extends ADR-0010's metadata-sync scope to cover vocabulary.

Separately, ADR-0013 stopped Enjoy Player from auto-mirroring the remote audio/video/recording catalog into the local Library on sign-in, because the Library reflects what is physically on the machine. A word book has no such "is this file on disk" concept — it is inherently a cross-device dataset — so applying ADR-0013's no-auto-mirror policy to vocabulary would regress multi-device continuity without a matching product benefit. This ADR calls out that vocabulary is an intentional, scoped exception.

## Decision

1. **Extend ADR-0010** to admit two more metadata-only synced entities: `vocabulary_item` and `vocabulary_context` (`SyncEntityType.vocabularyItem` / `.vocabularyContext`). Endpoints mirror the existing `AudioApi` / `VideoApi` shape: `GET/POST/DELETE /api/v1/mine/vocabulary_items(/:id)` and `.../vocabulary_contexts(/:id)`, implemented in `VocabularyApi` (`lib/data/api/services/vocabulary_api.dart`).
2. **`vocabulary_reviews` audits never sync** — never uploaded, never downloaded, never enter `sync_queue`. They are a device-local undo history (ADR-0052 already established this; this ADR reaffirms it as a hard invariant for the sync engine and repository).
3. **Item conflict is SRS-preserving, not plain LWW.** `resolveVocabularyItemConflict` (`lib/features/vocabulary/domain/vocabulary_item_conflict.dart`, ported from Enjoy web `apps/web/src/db/services/sync-utils.ts`) compares spaced-repetition freshness first:
   - If both sides have a `lastReviewedAt`, the later one wins.
   - If only one side has ever been reviewed, that side wins.
   - If neither side has been reviewed, the higher `reviewsCount` wins.
   - Whichever side "wins" SRS keeps its `status` / `easeFactor` / `interval` / `nextReviewAt` / `reviewsCount` / `lastReviewedAt`. When the *other* side's SRS is fresher, that side's row is taken wholesale (word, explanation, contexts count included).
   - When the **local** side wins SRS, the server's `word` / `explanation` are still adopted if `server.updatedAt` is newer than the local SRS reference (`lastReviewedAt`, or `updatedAt` if never reviewed) — so a genuinely newer remote dictionary lookup or word-casing fix is not silently dropped just because the local device also has newer review progress.
4. **Context conflict is plain last-write-wins on `updatedAt`** (server wins ties, matching `mergeAudioLastWriteWins` / web `resolveConflict`) — contexts have no SRS state to protect.
5. **Vocabulary auto-pulls on every signed-in sync** (`SyncEngine.fullSync`), paged by `updatedAfter` cursors (`sync.cursor.vocabulary_item`, `sync.cursor.vocabulary_context`) — **unlike** ADR-0013's media no-auto-mirror policy. This is a deliberate, scoped exception: vocabulary is a cross-device word book, not local-path media, so "what appears after sign-in" is expected to include the full remote word book rather than requiring a manual "Add to library" action.
6. **Outbound enqueue** happens from `VocabularyRepository` (optional `SyncEnqueueFn`, injected the same way as `MediaLibraryRepository`):
   - `addWithContext`: item `create` (new item only) + context `create` (new context only); item `update` when an existing item's `contextsCount` is bumped by a new context.
   - `markReviewed` / `undoLatestReview`: item `update` only — the review audit row itself is never enqueued.
   - `updateItemExplanation`: item `update`. `updateContextExplanation`: context `update`.
   - `deleteItem`: item `delete`, enqueued after the local cascade (contexts + reviews deleted locally first); the server is expected to cascade its own contexts on item delete, so contexts are not enqueued individually for delete.

## Consequences

- Multi-device word books converge: adding/reviewing offline on one device and signing in on another pulls the merged word book without losing either device's spaced-repetition progress.
- Review audits staying local-only means "undo last review" is a per-device action; a review undone on device A does not undo the equivalent review on device B (device B still sees the item update that resulted from that review, until its own next sync reconciles SRS state).
- `docs/features/sync.md` gains a vocabulary section; `docs/features/vocabulary.md` P3 acceptance criteria are satisfied by this ADR plus the implementation it describes.
- Does not rewrite ADR-0010 or ADR-0013; this ADR extends the former's entity list and carves out a documented, narrow exception to the latter's auto-mirror policy for vocabulary only.

## References

- Extends: [ADR-0010](0010-cloud-sync-mvp.md)
- Clarifies vs: [ADR-0013](0013-local-first-sync.md)
- Supersedes the "sync deferred" bullet of: [ADR-0052](0052-vocabulary-local-first-schema.md)
- Feature: [docs/features/vocabulary.md](../features/vocabulary.md), [docs/features/sync.md](../features/sync.md)
- Spec: `specs/024-vocabulary-sync-anki/`
- Web reference: `apps/web/src/db/services/sync-utils.ts` (`resolveVocabularyItemConflict`), `apps/web/src/services/vocabulary.ts`
