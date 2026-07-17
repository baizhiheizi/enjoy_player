# Research: Vocabulary Screen & Review

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Resolves open product/tech choices for P1. Foundation research in [021 research](../021-vocabulary-foundation/research.md) remains authoritative for identity/SRS/persistence.

---

## 1. Navigation destination

**Decision**: Add `ShellRoute` sibling path `/vocabulary` (like `/craft`, `/credits`, `/subscription`) and a Profile `SettingsRow` that `context.push('/vocabulary')`. Do **not** add a primary bottom-nav / rail destination. Record as **ADR-0053**.

**Rationale**: Spec FR-015 defaults to a secondary route. Primary shell already has Home / Discover / Library / Profile ([ADR-0009](../../docs/decisions/0009-platform-adaptive-shell.md)). Vocabulary is a learning book, not a top-level media surface; Profile already hosts Credits/Settings-style secondary entries. Matching craft’s “push under shell” keeps back-stack and adaptive shell chrome consistent.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| New primary shell tab | Crowds mobile bottom nav; costly IA change without usage data |
| Nested under `/library` | Couples word book to media library mental model |
| Settings-only entry | Too buried for a daily review loop |

---

## 2. Review session presentation

**Decision**: Pushed route `/vocabulary/review` (child or sibling under shell) hosting a fullscreen `Scaffold` session. Options collected on Vocabulary Review tab via `showEnjoySheet` / dialog before `push`.

**Rationale**: Fullscreen focus, clear Esc/back exit, easy Focus scope for shortcuts, and stable widget-test harness. Modal-only sessions fight nested navigators and player chrome on some platforms.

**Alternatives considered**:

| Option | Why rejected for P1 |
|--------|---------------------|
| `showGeneralDialog` only | Harder deep-link/test; back stack quirks on desktop |
| Embed session inside Vocabulary tab | Harder to hide chrome and own keyboard focus |

---

## 3. Keyboard shortcuts scope

**Decision**: **In-session only** via Flutter `Shortcuts` / `Actions` (or `CallbackShortcuts`) inside the review route’s focus tree. Do **not** register Space/1/2/3 in `AppHotkeys` / `hotkey_definitions.dart` in this phase.

**Rationale**: Spec assumption + open decision #4 in feature doc. Global Space/digits would collide with playback and text fields. In-session bindings match Enjoy web review when the flashcard surface has focus.

**Alternatives considered**: Global hotkeys with “review mode” gate — more moving parts; defer until hotkeys.md alignment if product later wants app-wide review hotkeys.

---

## 4. Repository / query surface gaps

**Decision**: Extend `VocabularyRepository` (and DAO if needed) with:

- `listAll()` / `watchAll()` (or single watch of all items)
- Optional `listByStatus` / language filter in Dart after `listAll` for personal scale
- Stats computed in domain from the item list + `isDue` predicate (reuse foundation due rules)
- No schema change

**Rationale**: DAO already has `listAll` + `listDue`. Foundation repo exposes `listDue` but not list-all for UI. Watching all items keeps stats/list coherent after rate/delete without ad-hoc invalidation bugs. Hundreds–low thousands fit memory filter/search (feature doc: no FTS for v1).

**Alternatives considered**: SQL aggregate queries for stats — premature; harder to keep due predicate identical to Dart `isDue`.

---

## 5. Session queue & random shuffle

**Decision**: Pure domain function `buildVocabularySessionQueue({items, mode, status?, language?, randomCount, random, now})` returning an ordered `List<VocabularyItem>`. Random mode: Fisher–Yates with injectable `Random` (tests use seed). Default `randomCount = 20`; if fewer items, use all. Empty queue → do not navigate to session; show message on options UI.

**Rationale**: Spec SC/FR require fair shuffle and empty-queue guard. Injectable RNG makes tests deterministic (web’s `Math.random` shuffle is weak — do not copy).

---

## 6. Primary context preview on flashcard

**Decision**: For card front/back Context tab text, load contexts for the current item and use the **earliest by `createdAt`** (stable “primary”). If none (should not happen for capture path), show localized no-context string.

**Rationale**: Simple, deterministic, matches “primary context preview” without ranking UI. P2 may prefer locator-linked “best” context.

**Alternatives considered**: Most recently added — also fine, but less stable across devices later; earliest is fine for P1.

---

## 7. Card back tabs (P1 vs P2)

**Decision**: Render three tabs — Context / Dictionary / Notes — for layout parity:

- **Context**: sentence text only (no play / open player / shadow).
- **Dictionary**: render cached `item.explanation` if present; otherwise empty/unavailable copy — **no AI fetch** in P1.
- **Notes**: placeholder string only.

**Rationale**: Spec FR-014 explicitly defers richness while allowing tab structure. Avoids half-working media actions that would violate single-player rules if rushed.

---

## 8. Undo / previous semantics

**Decision**: Session maintains a stack of item ids that were **rated** in this session (not skips). **Undo** calls `undoLatestReview(itemId)` for the top stack id, restores card index to that item, unflips. **← Previous** walks the session presentation stack (rated/skipped history) for navigation without mutating SRS when moving back over a skip; if landing on a rated card, undo is still the explicit action (do not auto-undo on ←). Align widget copy with web: ← = previous in session stack; Undo = separate control when stack non-empty.

**Rationale**: Matches foundation audit API (undo latest per item) and web’s session stack concept without inventing multi-step SRS rewind beyond latest audit.

---

## 9. Relative next-review labels

**Decision**: Pure helper comparing `nextReviewAt` to “today” in local calendar days → `overdue` | `today` | `tomorrow` | `inDays(n)`. Used by All Words rows. Localize in presentation.

**Rationale**: Feature string inventory already lists these labels; keep calendar math out of widgets.

---

## 10. Anki / sync / home widget

**Decision**: Out of scope. Do not show Export or sync status UI. Home due nudge remains a later phase.

**Rationale**: Spec SC-007 / FR-014.

---

## NEEDS CLARIFICATION

None remaining — all planning unknowns resolved above.
