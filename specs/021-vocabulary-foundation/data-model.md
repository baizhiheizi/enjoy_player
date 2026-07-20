# Data Model: Vocabulary Foundation

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Behavioral field contracts match Enjoy web / [docs/features/vocabulary.md](../../docs/features/vocabulary.md). Persistence: Drift schema **15**.

## Entities

### VocabularyItem

One row per `(normalizedWord, language, targetLanguage)`.

| Field | Type | Notes |
|-------|------|--------|
| `id` | string (UUID v5) | `enjoyVocabularyItemId(word, language, targetLanguage)` |
| `word` | string | Normalized form stored |
| `language` | string | BCP-47 source language |
| `targetLanguage` | string | Native / lookup target |
| `status` | enum string | `new` \| `learning` \| `reviewing` \| `mastered` |
| `easeFactor` | real | Initial `2.5`; clamp `[1.3, 2.5]` on updates |
| `interval` | int | Days; new items start at `0` |
| `nextReviewAt` | ISO 8601 string | Due predicate uses this |
| `reviewsCount` | int | Incremented on every rating |
| `lastReviewedAt` | ISO 8601? | Set on each rating |
| `contextsCount` | int | Denormalized |
| `explanation` | text JSON? | Cached dictionary result |
| `createdAt` / `updatedAt` | ISO 8601 | |
| `syncStatus` | enum string? | `local` \| `synced` \| `pending` — unused by sync engine in P0 |
| `serverUpdatedAt` | ISO 8601? | Sync bookkeeping |

**New-item defaults**: status `new`, ease `2.5`, interval `0`, `nextReviewAt = now + 24h`, `reviewsCount = 0`, `contextsCount = 1` on first context.

### VocabularyContext

Many per item.

| Field | Type | Notes |
|-------|------|--------|
| `id` | string (UUID v5) | See identity contract |
| `vocabularyItemId` | string FK | → item |
| `text` | string | Sentence / paragraph |
| `sourceType` | enum string | `Video` \| `Audio` \| `Ebook` (UI only creates Video/Audio in P0) |
| `sourceId` | string | Library media id |
| `locator` | text JSON | Media or ebook locator |
| `explanation` | text JSON? | Cached contextual translation |
| timestamps + sync fields | | Same pattern as item |

#### MediaLocator (JSON)

```json
{ "type": "media", "start": 1234, "duration": 5000 }
```

`start` / `duration` in milliseconds.

#### EbookLocator (schema-ready; no UI)

Readium-shaped object with `type: "ebook"` as in the feature doc. Not written by P0 UI.

### VocabularyReview (local audit)

| Field | Type | Notes |
|-------|------|--------|
| `id` | string (UUID v4) | Random |
| `vocabularyItemId` | string FK | |
| `rating` | int | `0` \| `1` \| `2` |
| `at` | ISO 8601 | Action time |
| `easeFactorBefore`, `intervalBefore`, `statusBefore`, `reviewsCountBefore`, `nextReviewAtBefore`, `lastReviewedAtBefore` | | Pre-image for undo |
| timestamps + `syncStatus` | | Local only; never queued |

## Relationships

```text
VocabularyItem 1 ──* VocabularyContext
VocabularyItem 1 ──* VocabularyReview (audit)
```

Delete item → cascade contexts + reviews.

## Identity & normalization

| Rule | Detail |
|------|--------|
| Normalize | Unicode letters/numbers/spaces; lower; trim (see identity contract) |
| Item id | v5 of `vocabulary-item:${word}:${language}:${targetLanguage}` |
| Context id | v5 of `vocabulary-context:${itemId}:${sourceType}:${sourceId}:${text[0..100]}:${stableLocatorJSON}` |
| Duplicate context | Same item + sourceType + sourceId + equal media start/duration (or ebook compare later) |

## Status lifecycle (via SRS only)

| Transition | When |
|------------|------|
| → `new` | Fresh add, or rating `0` |
| → `learning` | Rating `1` when **pre-increment** `reviewsCount < 3` |
| → `reviewing` | Rating `1` with count `≥ 3`, or rating `2` before mastery |
| → `mastered` | Rating `2` when **post-increment** `reviewsCount >= 5` |

Full formulas: [contracts/vocabulary-identity-srs.md](./contracts/vocabulary-identity-srs.md).

## Due predicate

```
nextReviewAt <= now
AND (lastReviewedAt is null OR nextReviewAt > lastReviewedAt)
```

Enforce invariants on write (`interval` / next-vs-last). Optional one-time repair if importing corrupt rows later.

## Indexes (Drift / SQL)

Align with web Dexie usefulness:

- **items**: `id` PK; `(word, language)`; `status`; `nextReviewAt`; `(language, status)`; `createdAt`
- **contexts**: `id` PK; `vocabularyItemId`; `(sourceType, sourceId)`
- **reviews**: `id` PK; `(vocabularyItemId, at)`

## Validation rules

- `word` non-empty after normalize (reject empty selection for add).
- `language` / `targetLanguage` non-empty BCP-47 tags from lookup resolution.
- `rating` ∈ {0,1,2}.
- Media locator: `type == media`, non-negative `start`/`duration`.
- `contextsCount` must match actual context rows after successful mutations (maintained in transaction).

## State transitions (add path)

```text
[selection]
    → normalize + resolve languages
    → find item by id or (word, language, targetLanguage)
    → if no item: insert item (defaults) + context
    → if item: load contexts for (itemId, sourceType, sourceId)
         → if locator duplicate: return existing (isNew: false)
         → else: insert context; bump contextsCount
```

## Out of scope for this model revision

- Sync conflict merge (`resolveVocabularyItemConflict`) — document only for later ADR.
- Anki export projection.
- Notes field content (placeholder UI later).
