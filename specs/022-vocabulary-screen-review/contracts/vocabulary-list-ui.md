# Contract: Vocabulary All Words list & empty states

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> List, filter, search, delete, and empty-state contracts for the Vocabulary destination.

---

## C1. All Words list row

Each row shows at least:

| Field | Display |
|-------|---------|
| Word | Normalized stored form (title) |
| Status | Localized status label (accent chip) |
| Contexts count | Integer (in muted secondary line) |
| Reviews count | Integer (in muted secondary line) |
| Next review | Relative label: overdue / today / tomorrow / in N days (in muted secondary line) |
| Language | Trailing muted label |

**Invariants**:

- Row actions include delete (with confirm) via overflow menu. Export lives in the list toolbar, not the row.
- Tapping a row may be no-op or expand detail later; P1 does not require a detail screen.

---

## C2. Filters & search

| Control | Behavior |
|---------|----------|
| Status filter | Optional single status; “all statuses” clears |
| Language filter | Optional single source language from distinct languages in the book |
| Search field | Case-insensitive `contains` on `word` and `language` after status/language filters |

**Invariants**:

- Search is client-side on the filtered in-memory set (no FTS).
- Debounce search input (≥150ms) before recomputing visible list.
- Changing filters updates visible rows without navigation.

---

## C3. Delete

| Step | Behavior |
|------|----------|
| Invoke delete | Confirm dialog (localized title/body + cancel/confirm) |
| Confirm | `VocabularyRepository.deleteItem(id)` — cascades contexts + review audits |
| Cancel | No mutation |
| After delete | List + stats strip refresh |

**Invariants**:

- Deletes the **whole item**, not a single context (web / foundation parity).
- Lookup CTA for that word returns to Add to Vocabulary after delete (existing foundation behavior).

---

## C4. Empty states

| Condition | Surface | Behavior |
|-----------|---------|----------|
| `total == 0` | Vocabulary (both tabs) | No-words empty copy; guide to save from transcript lookup; review start disabled or clearly blocked |
| `total > 0` && `due == 0` | Review tab | No-due empty copy; **custom review** (options) still available |
| Filtered list empty | All Words | Localized “no matches” (distinct from empty book) |

---

## C5. Stats coupling

Stats use the same item set as the book (not the search-filtered subset). Due count appears as a badge on the Review tab; full Total / Due / status breakdown is available from the app-bar insights sheet. Deleting or completing reviews that change status/due must update those surfaces on the next provider emission.
