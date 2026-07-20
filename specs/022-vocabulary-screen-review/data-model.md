# Data Model: Vocabulary Screen & Review

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Persisted entities are unchanged from [021 data-model](../021-vocabulary-foundation/data-model.md) / ADR-0052 (schema **15**). This document adds **ephemeral** and **derived** models for the P1 UI.

## Persisted (unchanged)

| Entity | Role in P1 |
|--------|------------|
| `VocabularyItem` | Stats, list rows, session queue members, rating target |
| `VocabularyContext` | Primary context preview + Context tab text |
| `VocabularyReview` | Undo audit via existing `markReviewed` / `undoLatestReview` |

No new tables, columns, or migrations.

## Derived: VocabularyStats

Computed from `List<VocabularyItem>` + due predicate at `now`.

| Field | Meaning |
|-------|---------|
| `total` | `items.length` |
| `due` | count where due predicate true |
| `newCount` | status `new` |
| `learningCount` | status `learning` |
| `reviewingCount` | status `reviewing` |
| `masteredCount` | status `mastered` |

**Invariant**: Sum of the four status counts equals `total`.

## Ephemeral: ReviewSelectionOptions

Inputs to queue builder (not persisted).

| Field | Values |
|-------|--------|
| `mode` | `due` \| `all` \| `byStatus` \| `byLanguage` \| `random` |
| `status` | optional `VocabularyStatus` when mode = byStatus |
| `language` | optional BCP-47 source language when mode = byLanguage |
| `randomCount` | int, default `20` when mode = random |

## Ephemeral: ReviewSessionState

Held by the review session notifier for one run.

| Field | Notes |
|-------|--------|
| `queue` | Ordered `List<VocabularyItem>` (snapshots at start; refresh item after rate) |
| `index` | Current card index `0..queue.length` (length ⇒ complete) |
| `flipped` | bool — back visible |
| `ratingInFlight` | bool — block duplicate rates |
| `ratedStack` | Stack of item ids rated this session (for undo order) |
| `history` | Session navigation history for ← previous (ids + whether rated) |
| `completed` | bool — show complete chrome |
| `primaryContextByItemId` | Optional cache of context text loaded for previews |

**Transitions**:

```text
start(options) → queue non-empty → index=0, flipped=false
flip → flipped=true
rate(0|1|2) → markReviewed → push ratedStack → advance
skip → advance (no markReviewed)
undo → pop ratedStack → undoLatestReview → set index to that card, flipped=false
previous ← → move index in history without SRS change (unless user then undoes)
exit → dispose session; committed ratings remain in DB
complete → index past end OR explicit complete when queue exhausted
```

## Derived: WordListRowView

Presentation helper (may be a typedef over `VocabularyItem` + label enum).

| Field | Source |
|-------|--------|
| `item` | `VocabularyItem` |
| `relativeNextReview` | from `nextReviewAt` vs local calendar |
| visible after | status filter ∩ language filter ∩ search contains |

**Search**: case-insensitive `contains` on `word` and `language` (web parity), applied in memory after DB/status/language filter.

## Domain helpers (pure)

| Helper | Responsibility |
|--------|----------------|
| `computeVocabularyStats(items, now)` | Stats strip |
| `buildVocabularySessionQueue(...)` | Mode filters + Fisher–Yates |
| `relativeNextReviewLabel(nextReviewAt, now)` | overdue / today / tomorrow / inDays |
| Existing `isDue` / `calculateNextReview` | Unchanged foundation |

## Validation rules (P1)

- Cannot start session when built queue is empty.
- Rating only when `flipped && !ratingInFlight && !completed`.
- Undo no-op when `ratedStack` empty.
- Delete item cascades contexts + reviews (existing repository); list/stats providers refresh.
- Random N > available ⇒ use all available (no duplicates padding).
