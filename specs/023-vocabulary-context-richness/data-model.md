# Data Model: Vocabulary Context Richness

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Persisted tables/columns are unchanged from [021 data-model](../021-vocabulary-foundation/data-model.md) / ADR-0052 (schema **15**). This document clarifies **explanation payloads**, **session enrichment**, and **media-action inputs**.

## Persisted (unchanged schema)

| Entity | Fields used in P2 | Notes |
|--------|-------------------|--------|
| `VocabularyItem` | `id`, `word`, `language`, `targetLanguage`, `explanation`, SRS fields | `explanation` written by Dictionary tab |
| `VocabularyContext` | `id`, `vocabularyItemId`, `text`, `sourceType`, `sourceId`, `locator`, `explanation` | Contextual AI + media actions |
| `VocabularyReview` | (unchanged) | Ratings/undo unaffected by AI/media |

No new tables, columns, or migrations.

### Item explanation (JSON text)

Compatible with `DictionaryResult`:

| Field | Required | Notes |
|-------|----------|--------|
| `word` | yes | |
| `sourceLanguage` | yes | |
| `targetLanguage` | yes | |
| `lemma` / `ipa` | no | |
| `senses[]` | yes (may be empty list) | `definition`, optional `translation`, `partOfSpeech`, `examples`, `notes` |

**Invariant**: Invalid JSON or failed decode ⇒ UI shows dictionary-unavailable; do not crash review.

### Context explanation (JSON text)

Compatible with `ContextualTranslationResult`:

| Field | Required |
|-------|----------|
| `translatedText` | yes |
| `aiModel` / `tokensUsed` | optional (store if service provides) |

**Invariant**: Updating one context’s explanation does not modify sibling contexts on the same item.

### Locator (unchanged)

| Type | Fields | P2 actions |
|------|--------|------------|
| `MediaLocator` | `type: media`, `start` ms, `duration` ms | Play segment, open in player, shadow hand-off |
| `EbookLocator` | Readium-shaped | Actions unavailable |

## Ephemeral: ReviewSessionState (enriched)

Extends P1 session state ([022 data-model](../022-vocabulary-screen-review/data-model.md)):

| Field | Change |
|-------|--------|
| `primaryContextByItemId` | **`Map<String, VocabularyContext>`** (was text-only) |
| `dictionaryFetchInFlight` | optional bool / item id — independent of `ratingInFlight` |
| `contextualFetchInFlight` | optional bool / context id |
| `clipPlayInFlight` | optional bool — disable double-start |

**Transitions (additive)**:

```text
persistDictionary(itemId, json) → updateItemExplanation → refresh queue item
persistContextual(contextId, json) → updateContextExplanation → refresh primaryContext map
playClip(context) → openMedia + seek + play (+ optional echo); session remains active
confirmOpenPlayer(context) → exit session → openPlayerRoute + seek
confirmShadow(context) → exit session → openPlayerRoute + echo activate → shadow UI
```

**Invariant**: AI persist and clip play MUST NOT call `markReviewed`. Session-ending actions MUST NOT undo committed ratings.

## Derived: ContextTabViewModel

Presentation helper (not persisted).

| Field | Source |
|-------|--------|
| `contextText` | `VocabularyContext.text` |
| `sourceTitle` | resolve from library by `sourceId` when available; else fallback label |
| `locatorLabel` | human-readable start/duration or “unavailable” |
| `contextualTranslation` | decode `explanation` or empty |
| `canPlayClip` | media locator + resolvable source |
| `canOpenPlayer` | same |
| `canShadow` | same (hand-off) |
| `canFetchContextual` | auth/credits allow + network path available |

## Derived: DictionaryTabViewModel

| Field | Source |
|-------|--------|
| `result` | decode item.explanation → `DictionaryResult?` |
| `canFetch` | auth/credits allow |
| `fetchInFlight` | session flag |

## Validation rules

- Explanation writes update `updatedAt` only (plus explanation column); ease/interval/status unchanged.
- Empty string and `null` both mean “no cached explanation”.
- Media actions require `sourceType` ∈ {Video, Audio} and `MediaLocator` with `duration > 0` (or product-equivalent guard).
