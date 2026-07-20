# Feature Specification: Vocabulary Foundation

**Feature Branch**: `021-vocabulary-foundation`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "Let's implement the vocabulary feature: docs/features/vocabulary.md. We'll make it several specs. As the first spec, let's finish the foundation for this feature."

**Parent feature contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (P0 — Domain + persistence + add from lookup). Later specs will cover the vocabulary screen / review session, context richness, sync, and Anki export.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Save a word from transcript lookup (Priority: P1)

While watching or listening, the learner selects a word (or short phrase) in the transcript, opens the existing dictionary lookup sheet, and saves that word into their personal vocabulary book together with the surrounding media sentence and a locator that can later reopen the clip.

**Why this priority**: Without a reliable “capture while learning” path, the vocabulary book never fills. This is the first user-visible value of the feature and the gate for all later review work.

**Independent Test**: Play media with a transcript, select a word, open lookup, tap Add to Vocabulary, then confirm the word exists in local vocabulary storage with one context pointing at the current media and sentence/locator.

**Acceptance Scenarios**:

1. **Given** the learner has a media session with a transcript and selects a word that is not yet in their book, **When** they choose **Add to Vocabulary** on the lookup sheet, **Then** the app creates a vocabulary item for that normalized word (source language + native/target language) and attaches one media context (sentence text + media locator).
2. **Given** a successful add, **When** the lookup sheet refreshes its vocabulary state for the same selection, **Then** the control no longer offers “Add to Vocabulary” as if the word were absent (it shows an in-book state).
3. **Given** the add is in progress, **When** the learner sees the control, **Then** it shows a busy state and does not accept duplicate taps that create parallel items.
4. **Given** the learner’s native/target language preference and the lookup source language, **When** a new item is created, **Then** those languages are stored on the item so the same surface form with a different language pair remains a separate word.

---

### User Story 2 - Add another context or recognize an exact duplicate (Priority: P1)

When the same word appears again (same language pair), the learner can attach a new media context, or see that this exact appearance is already saved, without creating a duplicate word entry.

**Why this priority**: Contexts are how Enjoy ties a word back to real media. Correct merge/dedup behavior is required for sync-compatible identity later and avoids a noisy word book.

**Independent Test**: Add a word once; select the same word at a different timestamp/sentence and add again; select the same word at the exact same locator and confirm no duplicate context is created.

**Acceptance Scenarios**:

1. **Given** the word is already in the book but this media locator is new, **When** the learner chooses **Add Context**, **Then** a new context is attached to the existing item and the item’s context count increases by one.
2. **Given** the word is already in the book and the same media locator (same start and duration) already exists for that source, **When** the learner opens lookup for that selection, **Then** the control shows **Already in Vocabulary** and does not create another context or bump the count.
3. **Given** the same written form with a different source language or different target language, **When** the learner adds it, **Then** a separate vocabulary item is created (not merged with the other language pair).

---

### User Story 3 - Remove a saved word from the lookup control (Priority: P2)

From the lookup sheet, when the selection is already in the book, the learner can remove that vocabulary item entirely (all of its contexts), matching current Enjoy web behavior.

**Why this priority**: Learners need an escape hatch when they saved by mistake; delete-from-add-control is part of the add CTA contract on web and belongs in the same foundation slice as add/dedup.

**Independent Test**: Add a word with one or more contexts; from **Already in Vocabulary**, confirm delete; verify the item and all its contexts are gone and the control returns to **Add to Vocabulary**.

**Acceptance Scenarios**:

1. **Given** the selection maps to an existing item (**Already in Vocabulary**), **When** the learner confirms remove, **Then** the entire vocabulary item and all of its contexts are deleted locally.
2. **Given** remove completed, **When** the learner opens lookup for the same selection again, **Then** the control offers **Add to Vocabulary** again.
3. **Given** the learner cancels the delete confirmation, **When** they dismiss without confirming, **Then** the item and contexts remain unchanged.

---

### User Story 4 - Correct word identity and spaced-repetition defaults (Priority: P1)

Vocabulary items use stable, deterministic identity from normalized word + languages, and new items start with the same spaced-repetition defaults and rating math as Enjoy web so later review and sync do not re-key or diverge.

**Why this priority**: Foundation quality is mostly invisible, but wrong IDs or SRS math would force data migrations and break multi-device sync later. This story is validated primarily by automated contract tests against the web algorithm.

**Independent Test**: Run the vocabulary identity and SRS test suite (ported from web fixtures): normalization, item/context IDs, new-item defaults, all three rating branches, due predicate, and undo pre-image restore — without requiring a full review UI.

**Acceptance Scenarios**:

1. **Given** a word containing punctuation or mixed case, **When** it is saved, **Then** storage and existence checks use the same Unicode-safe normalization (letters, numbers, spaces; lowercased; trimmed), so Latin and non-Latin scripts do not disagree between UI state and stored identity.
2. **Given** the same normalized word, source language, and target language, **When** identity is computed on two devices (or twice locally), **Then** the vocabulary item id is identical.
3. **Given** the same item, source, text prefix, and locator fields, **When** context identity is computed, **Then** the context id is identical (stable locator serialization).
4. **Given** a newly created item, **When** it is first persisted, **Then** it starts as status `new`, ease factor `2.5`, interval `0`, reviews count `0`, next review about 24 hours from creation, and contexts count matching attached contexts.
5. **Given** an item and a rating of Don’t Know / Know / Know Well (`0` / `1` / `2`), **When** the next-review calculation runs, **Then** ease, interval, status, reviews count, and next-review timestamp match the Enjoy web spaced-repetition rules (including clamps and pre- vs post-increment status rules).
6. **Given** a completed rating write that stored an undo snapshot, **When** undo of the latest rating for that item runs, **Then** the item’s SRS fields are restored to the pre-image and the audit entry for that rating is removed.

---

### Edge Cases

- Same surface form with different target language (or source language) → separate items.
- Non-Latin words: one Unicode-safe normalizer for storage, lookup existence, and button state (do not use ASCII-only word checks).
- Exact duplicate media context (same start + duration for the same source) → no-op; no count bump.
- Delete from lookup removes the **whole item**, not a single context.
- New item has interval `0` but is first due ~24 hours out; the first successful rating path still enforces a minimum interval of 1 day.
- Offline: add / remove / local SRS math work without network; AI dictionary fill is not required for foundation capture.
- Ebook selection add is out of scope; media (audio/video) contexts only. Schema may remain ready for ebook locators without exposing ebook UI.
- Large libraries: add and existence checks remain responsive for typical personal vocabulary sizes (hundreds to low thousands of items); no full-text search index required in this phase.
- Cross-platform: the lookup CTA works on Android, iOS, macOS, Windows, and Linux with the same add/dedup/delete semantics.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Learners MUST be able to add a vocabulary item plus one media context from the existing transcript dictionary lookup sheet when the selection is not already in their book.
- **FR-002**: Learners MUST be able to append a new media context to an existing item when the word (same language pair) is already saved but the locator is new.
- **FR-003**: The system MUST detect an exact duplicate media context (same source and equal locator start/duration) and MUST NOT create another context or change counts.
- **FR-004**: The lookup vocabulary control MUST expose clear states: not in book, add context, already in vocabulary (with remove), and busy.
- **FR-005**: Removing from the lookup control MUST delete the entire vocabulary item and cascade-delete all of its contexts and local review-audit rows for that item, after confirmation.
- **FR-006**: Word identity MUST be derived from Unicode-safe normalization of the word plus source language plus target language, using the same deterministic id scheme as Enjoy web (shared Enjoy UUID namespace).
- **FR-007**: Context identity MUST be deterministic from item id, source type, source id, text prefix, and stably serialized locator fields, matching Enjoy web so future sync does not fork duplicates.
- **FR-008**: The system MUST persist vocabulary items, contexts, and local review-audit records on device with the fields needed for later review, AI cache, and sync-compatible ids (including optional sync bookkeeping fields even when sync is not enabled yet).
- **FR-009**: Adding a word with context MUST be atomic: either the item/context changes commit together or neither is left half-applied.
- **FR-010**: New items MUST use Enjoy web defaults for status, ease factor, interval, next review time, and review/context counts.
- **FR-011**: The system MUST implement Enjoy web’s three-rating spaced-repetition calculation (Don’t Know / Know / Know Well), status lifecycle, due predicate, and interval/ease clamps as a pure, testable contract — available to later review UI without reimplementation.
- **FR-012**: Mark-reviewed and undo-latest-rating MUST support atomic pre-image audit and restore (device-local; never uploaded), even if no full review screen ships in this phase.
- **FR-013**: Media context text and locator MUST come from a media-aware builder (echo span of multiple lines when applicable; otherwise sentence expansion around the active line), returning text plus source type, source id, and media locator in milliseconds — not a string-only helper.
- **FR-014**: Default target language for new items MUST be the learner’s native language preference; source language MUST follow the lookup sheet’s existing source-language resolution.
- **FR-015**: This phase MUST NOT require cloud sync, vocabulary navigation shell destination, fullscreen review UI, Anki export, home due widget, ebook add UI, tags, batch import, or marketing-only study modes.
- **FR-016**: Lookup language catalog rules MUST remain unchanged (multi-language lookup catalog stays decoupled from profile native/focus catalogs).

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason — especially SRS branches, normalize/ids, add-with-context, duplicate no-op, cascade delete, due predicate, and undo.
- **QR-003**: User-facing strings for the add/remove control states MUST follow existing localization and shared UI patterns on the lookup sheet.
- **QR-004**: Add / existence-check / delete from lookup MUST remain responsive during playback (no multi-second UI freeze for a single add on a typical personal library).
- **QR-005**: Feature behavior that lands MUST update [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (and related ADRs when schema/local-first scope is decided).

### Key Entities *(include if feature involves data)*

- **Vocabulary item**: One saved word for a language pair. Holds normalized word, source/target languages, spaced-repetition fields (status, ease, interval, next review, review counts), denormalized context count, optional cached dictionary explanation, timestamps, and sync bookkeeping placeholders.
- **Vocabulary context**: One appearance of a word in media (or, later, ebook). Holds sentence/paragraph text, source type/id, locator (media: start + duration in ms), optional cached contextual translation, timestamps, and sync bookkeeping placeholders. Many contexts per item.
- **Vocabulary review (audit)**: Local-only record of a rating used for undo. Stores rating, time, and pre-image SRS fields. Never synced.
- **Media locator**: Points back into audio/video with start and duration in milliseconds.
- **Lookup vocabulary control state**: Derived UI state for the current selection relative to the book (absent / new context / exact duplicate / busy).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a manual or automated playback scenario, a learner can save a new word from the lookup sheet in one action and see the control reflect an in-book state without restarting the app.
- **SC-002**: Repeating add for the same word at a new locator increases that item’s context count by exactly one; repeating at the exact same locator leaves count unchanged.
- **SC-003**: 100% of ported Enjoy web SRS and identity fixtures used for this phase pass (rating branches, clamps, mastery/status rules, normalize, stable ids, add/dedup, due predicate, undo restore).
- **SC-004**: After confirmed remove from the lookup control, the item and all of its contexts are gone, and the same selection can be added again as a new item.
- **SC-005**: Same normalized word + language pair always yields the same item id; same context inputs always yield the same context id (verified by tests).
- **SC-006**: Foundation scope stays bounded: no vocabulary shell page, review session, sync, or Anki export is required for this phase to be considered done.
- **SC-007**: Adding a word during playback does not stall the primary playback/transcript UI for more than about one second under normal local storage conditions on supported desktop/mobile targets.

## Assumptions

- This is **phase 1 of several** vocabulary specs; parent contract is `docs/features/vocabulary.md` P0.
- Local-first only: cloud sync of vocabulary is deferred (IDs and fields stay API-compatible for a later sync phase + ADR).
- Delete-from-lookup removes the **whole item** (web parity), not a single context.
- Ebook add UI is out of scope; media contexts only. Ebook locator shape may exist in the data model for forward compatibility.
- Full vocabulary screen, review options, flashcards, keyboard shortcuts, home due widget, and Anki export belong to later specs.
- Review-audit / undo APIs exist in the foundation data contract so P1 review UI does not redesign persistence; shipping a complete flashcard UI is not required here.
- Existing dictionary lookup sheet remains the only add entry point in this phase.
- Native language preference and lookup source-language resolution already exist and are reused.
- Enjoy web (`vocabulary-srs`, normalize, id generators, add-with-context rules) is the behavioral source of truth for parity tests.
- A schema / local-first vocabulary ADR will be recorded when implementation plans the persistence approach (do not rewrite ADR-0010).
