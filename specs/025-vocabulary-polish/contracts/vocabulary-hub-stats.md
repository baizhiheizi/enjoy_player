# Contract: Vocabulary hub stats (compact)

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral + UI contract for FR-001, FR-002, SC-001. Supersedes the phone 2×3 bordered stats grid described in docs for the Vocabulary page.

---

## C1. Collapsed summary (default)

| Given | When | Then |
|-------|------|------|
| Vocabulary hub open, phone-width | First paint | Stats show a single compact `EnjoyCard` row with at least **Total** and **Due** (due emphasized when `due > 0`) |
| Same | Learner views first viewport | Review/All Words, search/filters (All Words), and list/empty content are reachable without scrolling past a tall six-cell grid |

**Invariants**:

- Collapsed content height stays small (~one metrics row + padding).
- No 2×3 wrap of bordered `_StatCell` tiles as the default phone layout.

---

## C2. Status breakdown

| Given | When | Then |
|-------|------|------|
| Collapsed summary visible | Learner expands stats (chevron / “details”) | New / learning / reviewing / mastered counts appear as a dense secondary row or wrap |
| Expanded | Learner collapses | Returns to Total + Due summary |

**Invariants**:

- Breakdown remains on the Vocabulary destination (not a separate route).
- Empty book: zeros or muted empty treatment; empty-state copy still primary.

---

## C3. Wide layout

| Given | When | Then |
|-------|------|------|
| Width ≥ ~560 | Hub open | Thin horizontal metrics acceptable (dividers, not tall bordered cards); hierarchy still list-first |

---

## Out of scope

- Persisted expand preference across launches (optional later).
- Charts, streaks, or weekly graphs.
