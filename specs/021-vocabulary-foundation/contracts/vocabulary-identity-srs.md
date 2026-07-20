# Contract: Vocabulary Identity & SRS

**Implements**: FR-006, FR-007, FR-010, FR-011, FR-012 · [data-model.md](../data-model.md)

Behavioral parity with Enjoy web `vocabulary-utils`, `id-generator`, `vocabulary-srs`.

## Normalization

```
normalizeWord(raw):
  lower case → trim → remove chars not in Unicode letters/numbers/spaces
```

Same function for storage, id input, existence checks, and CTA state. No ASCII-only `\w` path.

## Deterministic IDs

Namespace: RFC 4122 URL `6ba7b811-9dad-11d1-80b4-00c04fd430c8` (`enjoyUuidNamespaceUrl`).

| Entity | Name string |
|--------|-------------|
| Item | `vocabulary-item:${normalizedWord}:${language}:${targetLanguage}` |
| Context | `vocabulary-context:${itemId}:${sourceType}:${sourceId}:${text.slice(0,100)}:${stableLocatorJSON}` |
| Review | UUID v4 (random) |

`stableLocatorJSON`: JSON object with keys sorted alphabetically at every nesting level used by web (top-level locator keys at minimum). Media example after sort: `duration`, `start`, `type`.

## New item defaults

| Field | Value |
|-------|--------|
| status | `new` |
| easeFactor | `2.5` |
| interval | `0` |
| nextReviewAt | now + 24 hours (ISO) |
| reviewsCount | `0` |
| contextsCount | number of contexts inserted in the same transaction (1 on first add) |

## SRS constants

| Name | Value |
|------|--------|
| MIN_EASE_FACTOR | 1.3 |
| MAX_EASE_FACTOR | 2.5 |
| DEFAULT_EASE_FACTOR | 2.5 |
| MIN_INTERVAL_DAYS | 1 |
| MAX_INTERVAL_DAYS | 365 |

## Ratings

| UI | Value |
|----|--------|
| Don’t Know | 0 |
| Know | 1 |
| Know Well | 2 |

## `calculateNextReview`

Inputs: current `ease`, `interval`, `reviewsCount`, `rating`, `now`.

Always:

- `reviewsCount' = reviewsCount + 1`
- `lastReviewedAt' = now` (ISO)

**Rating 0**

```
ease'     = max(1.3, ease - 0.15)
interval' = 1
status'   = new
```

**Rating 1**

```
interval' = (reviewsCount == 0 || interval == 0)
            ? 1
            : clamp(round(interval * ease), 1, 365)
status'   = reviewsCount < 3 ? learning : reviewing   // PRE-increment count
```

**Rating 2**

```
ease'     = min(2.5, ease + 0.1)
interval' = (interval == 0)
            ? 1
            : clamp(round(interval * ease' * 1.5), 1, 365)
status'   = reviewsCount' >= 5 ? mastered : reviewing  // POST-increment count
```

### `nextReviewAt`

UTC midnight of calendar day `(today UTC + interval' days)`:

```
date = now as UTC
date.day += interval'
date.setUTCHours(0, 0, 0, 0)
nextReviewAt = date.toISOString()
```

### Due predicate

```
nextReviewAt <= now
AND (lastReviewedAt is null OR nextReviewAt > lastReviewedAt)
```

## Mark reviewed / undo

**Mark reviewed** (atomic):

1. Capture pre-image into `VocabularyReview`.
2. Apply `calculateNextReview`.
3. Update item; insert audit.

**Undo latest** (atomic):

1. Load latest audit by `(vocabularyItemId, at)` descending.
2. Restore `*Before` fields onto item.
3. Delete audit row.

P0 ships these APIs + tests; flashcard UI is out of scope.

## Test obligations

Port / mirror web cases for: all rating branches; ease clamps; interval caps; mastery at 5; status pre/post count; normalize Unicode; stable context id; different `targetLanguage` → different item id.
