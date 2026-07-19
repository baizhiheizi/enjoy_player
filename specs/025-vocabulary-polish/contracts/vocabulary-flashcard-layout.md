# Contract: Vocabulary flashcard layout (sheet-aware)

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> UI/layout contract for FR-013, SC-008, SC-011, and Enjoy-aligned polish. Practice chrome is **not** embedded in the Context tab body (clarified).

---

## C1. Context tab vertical order

Fixed order inside the scrollable Context body:

1. Context quote (word highlight)
2. Context pager (only if ≥ 2 contexts)
3. Source title + locator meta
4. Media action row (Play clip / Open in player / Echo reading)
5. Contextual translation / AI content

**Invariants**:

- **No** embedded video stage or ShadowReadingPanel in this scroll list.
- Rating chips / flip-back stay in the **sticky footer** (existing pattern).
- Practice opens the **modal adaptive practice sheet** ([vocabulary-practice-sheet.md](./vocabulary-practice-sheet.md)).

---

## C2. Practice sheet body sizing

| Viewport | Clip video stage | Echo panel |
|----------|------------------|------------|
| Compact bottom sheet | ≤ ~220 logical px height; 16:9; rounded | Scroll inside sheet if needed |
| Wide centered modal | ≤ ~280 logical px; constrained by `modalMaxWidthLarge` | Same |

- Dismiss control / drag affordance per Enjoy sheet patterns.
- Audio-only: artwork fallback + transport.

---

## C3. Action row affordance

- Keep quiet icon+label `_MediaAction` language.
- While sheet open, card actions underneath are non-interactive (modal).
- After dismiss, actions remain available to reopen.

---

## C4. Mobile usability checks

On phone-width with sheet **closed**:

- [ ] Quote + pager + actions + sticky rate usable
- [ ] No tall empty practice slot reserved in the card

With sheet **open**:

- [ ] Sheet content usable (play or record)
- [ ] Barrier blocks accidental rate/flip
- [ ] Dismiss returns to usable card

---

## C5. Visual language

| Do | Don’t |
|----|-------|
| Enjoy tokens, pill tabs, calm sheet | Neon/glow restyle |
| One practice surface in sheet | Stacked player + recorder |
| List-first hub stats | Six large dashboard tiles on hub or card |

---

## Out of scope

- Dictionary tab redesign.
- Rating chip / SRS label changes.
- Notes tab content.
