# Contract: Vocabulary review selection & session

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral contracts for review options, flashcard session, SRS writes, and desktop shortcuts.

---

## C1. Review selection modes

| Mode | Queue membership |
|------|------------------|
| Due | Items matching foundation due predicate at start time |
| All | All local items |
| By status | Items with selected `VocabularyStatus` |
| By language | Items with selected source `language` |
| Random | Fisher–Yates shuffle of all items, take first N (default **20**; if fewer, take all) |

**Invariants**:

- Empty queue ⇒ do not open session; show localized message on options UI.
- Queue order is fixed at session start (except undo restoring a prior card’s item snapshot after DB undo).
- Selection UI lives on Review tab (sheet/dialog) before navigating to `/vocabulary/review`.

---

## C2. Flashcard chrome

| State | UI |
|-------|-----|
| Front | Word + primary context preview; progress `current / total`; skip; exit; undo if available |
| Back | Same chrome + rating row (Don’t Know / Know / Know Well); tabs Context / Dictionary / Notes |
| Rating in flight | Rating buttons + digit shortcuts disabled/ignored |
| Complete | Localized complete state; leave returns to `/vocabulary` |

**Card back tab content (P1)**:

| Tab | Content |
|-----|---------|
| Context | Primary context text (or no-context copy) |
| Dictionary | Cached explanation render if present; else unavailable copy — no AI fetch |
| Notes | Placeholder only |

**Invariants**:

- Ratings available only after flip (or only on back).
- Skip advances without `markReviewed`.
- Rate calls repository `markReviewed` with `0|1|2`; SRS matches foundation / web tests.
- Undo calls `undoLatestReview` for the last rated item in the session stack and returns UI to that card (unflipped).
- Exit keeps committed ratings; does not auto-undo.

---

## C3. Desktop in-session shortcuts

Active only while review route has focus:

| Key | Action |
|-----|--------|
| Space | Flip |
| `1` / `2` / `3` | Rate 0 / 1 / 2 (back only; ignored if not flipped or in flight) |
| ← | Previous in session history |
| → | Skip |
| Esc | Exit session |

**Invariants**:

- Not registered in global `AppHotkeys` in this phase.
- Shortcut hint/legend visible in review UI (localized).
- Rapid key repeat during `ratingInFlight` must not double-apply.

---

## C4. Repository calls

| Action | API |
|--------|-----|
| Rate | `VocabularyRepository.markReviewed(itemId:, rating:)` |
| Undo | `VocabularyRepository.undoLatestReview(itemId)` |
| Contexts | `getContextsForItem` for preview/tab |
| Due list | `listDue` and/or filter via `isDue` on `listAll` |

No sync enqueue. No second media player.
