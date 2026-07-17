# Contract: Vocabulary Cloud Sync

**Feature**: [spec.md](../spec.md) · ADR to write: **0054** · Parent: [docs/features/vocabulary.md](../../../docs/features/vocabulary.md) § Sync semantics  
**Extends**: [ADR-0010](../../../docs/decisions/0010-cloud-sync-mvp.md) · Clarifies vs [ADR-0013](../../../docs/decisions/0013-local-first-sync.md) (media no-auto-mirror)

## Entities

| Entity | Sync | Conflict |
|--------|------|----------|
| Vocabulary item | Upload + download | SRS-preserving (`resolveVocabularyItemConflict`) |
| Vocabulary context | Upload + download | Last-write-wins on `updatedAt` |
| Vocabulary review audit | **Never** | N/A (device-local) |

## Wire entity types

| Dart / domain | Queue `entityType` string |
|---------------|---------------------------|
| `vocabularyItem` | `vocabulary_item` |
| `vocabularyContext` | `vocabulary_context` |

## Mutation → queue

| Local action | Queue |
|--------------|--------|
| New item + context | item `create` + context `create` |
| Add context to existing item | context `create`; item `update` if `contextsCount`/timestamps change |
| Duplicate context no-op | no queue |
| `markReviewed` / undo restore | item `update` only |
| Explanation write-through | item or context `update` |
| Delete item | item `delete` (local cascade contexts/reviews); do not require per-context delete queue if server cascades — document assumption in ADR |

## Signed-in sync behavior

1. **Outbound**: drain `sync_queue` for vocabulary entity types (same batch/retry as media).
2. **Inbound**: page `GET …/vocabulary_items` and `…/vocabulary_contexts` with `updatedAfter` cursors; merge into Drift.
3. Vocabulary pull **does** run on signed-in sync (word-book continuity). This is **not** a reintroduction of media library auto-mirror.

## Offline

Full local CRUD + review + Anki (if Pro) while offline. Pending rows retain `syncStatus: pending` until successful drain.

## Acceptance checks

| ID | Check |
|----|--------|
| C1 | Add word offline → sign-in/drain → appears on second device/store after pull |
| C2 | Conflicting reviews: newer `lastReviewedAt` (else higher `reviewsCount`) wins SRS fields |
| C3 | Identical context locator / id does not duplicate rows |
| C4 | Review audit rows never appear in upload payloads or remote list handling |
| C5 | Failed network leaves local data intact; retry later succeeds without silent drop |
