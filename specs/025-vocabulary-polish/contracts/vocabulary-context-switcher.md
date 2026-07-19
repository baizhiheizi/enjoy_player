# Contract: Vocabulary flashcard context switcher

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral contract for FR-009–FR-011, FR-014, SC-007. Extends [023 vocabulary-context-tab](../../023-vocabulary-context-richness/contracts/vocabulary-context-tab.md) with explicit multi-context navigation. Modal practice sheet interaction per clarifications.

---

## C1. Visibility

| Given | When | Then |
|-------|------|------|
| Current item has ≥ 2 contexts | Context tab (and front preview as applicable) | Show pager: previous, next, and position label (`n of m` / localized) |
| Exactly 1 context | View Context | No pager chrome |
| 0 contexts | View Context | Existing empty/unavailable state; no pager |

---

## C2. Ordering & default

| Rule | Behavior |
|------|----------|
| Order | `createdAt` ascending (stable) |
| Default active | Index `0` (earliest) |
| Wrap | **Clamp** (no wrap) at ends |

---

## C3. Binding

| Surface | Binds to |
|---------|----------|
| Front context preview | Active context text |
| Quote / highlight | Active context |
| Source title / locator meta | Active context |
| Play clip / echo / open in player | Active context locator + source |
| Contextual translation | Active context `explanation` |
| Practice sheet (when open) | Must target active context; reopen after switch |

---

## C4. Interaction with practice sheet

| When | Then |
|------|------|
| Practice sheet open | Pager / context change on the card is blocked until dismiss (modal), **or** changing context dismisses the sheet first then applies the new index |
| Active index changes after dismiss | `practice = none` already; do not leave sheet bound to previous locator |
| Learner rates card | SRS writes to **item**; context index irrelevant |

---

## C5. Accessibility

- Prev/next icon buttons with localized tooltips.
- Semantics label includes n of m.

---

## Out of scope

- Reordering contexts by drag.
- Deleting a single context from the flashcard.
- Persisting last active context across sessions.
