# Contract: Vocabulary Context tab chrome

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral contracts for Context tab content beyond plain text (FR-001, FR-003, FR-009, FR-011).

---

## C1. Tab structure (unchanged shell)

| Tab | P2 content |
|-----|------------|
| Context | Text + source/locator labels + contextual translation + media actions |
| Dictionary | Cached + fetch/persist (see explanation-persist contract) |
| Notes | Placeholder only (“coming soon”) |

---

## C2. Context content

| Element | Requirement |
|---------|-------------|
| Context text | Primary context `text` (earliest `createdAt`); else no-context copy |
| Source identity | Show title/id when library resolve succeeds; graceful fallback otherwise |
| Locator label | Human-readable segment hint for media locators; unavailable for ebook/missing |
| Contextual translation | Per explanation-persist contract |
| Actions row | Play segment, Open in player, Shadow reading — visibility per media-actions contract |

---

## C3. Empty / unavailable

| Case | UI |
|------|-----|
| No contexts on item | No-context copy; media actions hidden |
| Ebook locator | Media actions hidden/disabled with unavailable meaning |
| Missing library media | Actions may show but fail with clear message on tap |

---

## Invariants

- Primary context selection remains earliest-by-`createdAt` unless a later phase adds a picker.
- Context tab MUST NOT advance SRS by itself.
