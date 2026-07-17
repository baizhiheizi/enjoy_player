# Contract: Vocabulary navigation & destination shell

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Internal navigation / shell contracts for implementers and widget tests. Durable product decision: **ADR-0053**.

---

## C1. Routes

| Path | Screen | Notes |
|------|--------|-------|
| `/vocabulary` | `VocabularyScreen` | **NEW** — stats + Review / All Words |
| `/vocabulary/review` | `VocabularyReviewSessionScreen` | **NEW** — fullscreen session; requires active session state |

**Invariants**:

- Both routes live under the existing `ShellRoute` → `RootShell` (same pattern as `/craft`, `/credits`).
- Neither path is a primary shell tab destination (Home / Discover / Library / Profile unchanged).
- Signed-out users remain gated by existing auth redirects.
- Back from `/vocabulary` returns to the previous route (typically Profile).
- Back / Esc from `/vocabulary/review` returns to `/vocabulary` without discarding already-committed ratings.
- Deep link `/vocabulary` opens the destination when signed in; `/vocabulary/review` without an active session redirects to `/vocabulary` (or shows empty and pops).

---

## C2. Profile entry

| Element | Behavior |
|---------|----------|
| Profile list row | Localized title/subtitle for Vocabulary |
| Action | `context.push('/vocabulary')` |
| Placement | Near other secondary learning/account rows (e.g. above or below Preferences / Settings — prefer with learning-adjacent entries) |

**Invariants**:

- Entry visible when signed in.
- Does not require due count badge in P1 (home due widget deferred).

---

## C3. Vocabulary screen chrome

| Element | Behavior |
|---------|----------|
| App bar | Title = Vocabulary; back affordance |
| Stats strip | total, due, new, learning, reviewing, mastered |
| Tabs | **Review** \| **All Words** |
| Empty book | Localized empty state; still show chrome; Review custom start disabled or explained until words exist |

**Invariants**:

- Stats refresh after return from a review session that rated/deleted items and after All Words delete.
- No Anki Export control in P1.
- No sync status chrome in P1.

---

## C4. ADR

Implementation PR adds `docs/decisions/0053-vocabulary-secondary-route.md` and indexes it in `docs/decisions/README.md`.
