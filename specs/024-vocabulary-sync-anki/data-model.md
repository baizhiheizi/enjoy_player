# Data Model: Vocabulary Sync & Anki Export

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Persisted vocabulary tables are unchanged from [021 data-model](../021-vocabulary-foundation/data-model.md) / ADR-0052 (schema **15**). This document clarifies **sync state transitions**, **conflict merge fields**, and **ephemeral Anki export** shapes.

## Persisted entities (unchanged columns)

### VocabularyItem

| Field | Sync | Anki | Notes |
|-------|------|------|--------|
| `id` | yes | — | UUID v5; stable across devices |
| `word`, `language`, `targetLanguage` | yes | Front / Tags | Identity |
| `status`, `easeFactor`, `interval`, `nextReviewAt`, `reviewsCount`, `lastReviewedAt` | yes | Tags (status) | **SRS** — conflict prefers newer SRS |
| `contextsCount` | yes | — | Denormalized |
| `explanation` | yes | Back | Dictionary JSON (P2 codec) |
| `createdAt`, `updatedAt` | yes | — | |
| `syncStatus` | local bookkeeping | — | `local` → `pending` → `synced` |
| `serverUpdatedAt` | yes | — | Set after successful upload/download |

### VocabularyContext

| Field | Sync | Anki | Notes |
|-------|------|------|--------|
| `id` | yes | — | UUID v5 from item + source + text + locator |
| `vocabularyItemId` | yes | — | FK |
| `text` | yes | Front | Merged with `<hr>` |
| `sourceType`, `sourceId`, `locator` | yes | Back source refs | Ebook titles may be unresolved |
| `explanation` | yes | Back | Contextual translation JSON |
| timestamps + `syncStatus` + `serverUpdatedAt` | yes | — | Context conflict = LWW `updatedAt` |

### VocabularyReview

| Field | Sync | Notes |
|-------|------|--------|
| All fields | **never** | Device-local undo audit only; do not enqueue |

### Sync queue row (existing)

| Field | Vocabulary use |
|-------|----------------|
| `entityType` | `vocabulary_item` \| `vocabulary_context` |
| `entityId` | Item or context id |
| `action` | `create` \| `update` \| `delete` |
| `payloadJson` | Serialized entity map for create/update |

## Sync status transitions

```text
create/update local mutation
  → syncStatus = pending
  → upsert sync_queue
  → (signed in) processQueue
  → upload success → syncStatus = synced, serverUpdatedAt = server time

delete local
  → queue delete (payload optional)
  → DELETE API → remove local row (already cascaded for item)

download remote newer/missing
  → upsert local via conflict resolver
  → syncStatus = synced
```

**Invariants**:

- Review insert/delete MUST NOT create queue rows.
- Item delete cascades local contexts + reviews; queue **item** delete (server cascade assumed — document in ADR-0054).
- Offline mutations remain `pending` until drain succeeds or retries exhaust (same as media).

## Conflict merge (items)

Inputs: local item `L`, server item `S` (same `id`).

```text
localSrsNewer =
  if both have lastReviewedAt → L.lastReviewedAt > S.lastReviewedAt
  else if only L has lastReviewedAt → true
  else if only S has lastReviewedAt → false
  else → L.reviewsCount > S.reviewsCount

if localSrsNewer:
  result = L SRS fields kept
  optionally adopt S metadata (explanation, word display fields) when S.updatedAt is newer
    (match web resolveVocabularyItemConflict)
else:
  result = prefer S (with any future local-only fields preserved — none today)
```

Contexts: if `S.updatedAt >= L.updatedAt` → take `S`, else `L`.

## Ephemeral: Anki export set

Not persisted. Built at export time:

| Field | Source |
|-------|--------|
| `filters.search` | optional string |
| `filters.status` | `all` \| status enum |
| `filters.language` | `all` \| BCP-47 |
| `items` | filtered `VocabularyItem` list |
| `contextsByItemId` | map of contexts per item |
| `sourceRefs` | optional title lookup from library by `sourceId` |
| `csvBytes` | UTF-8 BOM + CSV string |

**Validation**: Empty filtered set → do not write a bogus file; show empty-export message. Free tier → no `csvBytes` generation for user download.

## Settings cursors (new keys)

| Key | Purpose |
|-----|---------|
| `sync.cursor.vocabulary_item` | Last successful `updatedAfter` for item pull |
| `sync.cursor.vocabulary_context` | Last successful `updatedAfter` for context pull |

## Derived: CSV row

| Column | Construction |
|--------|----------------|
| Front | HTML word + context block |
| Back | HTML context translations + dictionary sections + source line |
| Tags | space-separated `vocabulary`, `lang-target`, optional status |

See [vocabulary-anki-export.md](./contracts/vocabulary-anki-export.md).
