# Feature Specification: Vocabulary Screen & Review

**Feature Branch**: `022-vocabulary-screen-review`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "Let's continue to implement the vocabulary feature docs/features/vocabulary.md. Pick up a reasonable tasks that include this spec, defer the others in follow-ups."

**Parent feature contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (**P1** — Vocabulary screen + review). Builds on foundation capture / local SRS from [021-vocabulary-foundation](../021-vocabulary-foundation/spec.md). Follow-ups cover context richness (clip play, AI persist on review tabs), cloud sync, Anki export, and home due nudge.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open Vocabulary and see progress at a glance (Priority: P1)

As a learner who has saved words from media, I open a dedicated Vocabulary destination and immediately see how many words I have, how many are due, and a breakdown by learning status (new / learning / reviewing / mastered), with tabs for **Review** and **All Words**.

**Why this priority**: Without a browsable Vocabulary home, saved words stay invisible after capture. Stats and navigation are the entry point for every review and manage flow.

**Independent Test**: With a known set of local vocabulary items (including some due and some in each status), open Vocabulary and verify totals, due count, status counts, and both tabs are available.

**Acceptance Scenarios**:

1. **Given** the learner has local vocabulary items, **When** they open Vocabulary, **Then** they see a stats strip with at least: total, due, new, learning, reviewing, mastered.
2. **Given** Vocabulary is open, **When** they view the main structure, **Then** they can switch between **Review** and **All Words**.
3. **Given** the book is empty, **When** they open Vocabulary, **Then** they see a clear empty state (no words) with guidance that they can save words from transcript lookup — not a blank or broken screen.
4. **Given** there are words but none are due, **When** they are on the Review tab, **Then** they see a no-due empty state that still allows starting a custom review (all / filters / random).

---

### User Story 2 - Start a review session with selection options (Priority: P1)

As a learner, from the Review tab I choose what to study (due items, all words, by status, by language, or a random subset), then start a fullscreen/modal flashcard session.

**Why this priority**: Selection options are how Enjoy web avoids forcing only “due” study; they make the review surface useful even when nothing is due.

**Independent Test**: Open Review options, pick each mode with a prepared book, start review, and confirm the session queue matches the chosen filter (including random N and empty-queue messaging).

**Acceptance Scenarios**:

1. **Given** the learner opens review options, **When** they choose **Due** and start, **Then** the session includes only items that match the due rules (due now and not in an invalid due/last-reviewed state).
2. **Given** review options, **When** they choose **All** and start, **Then** the session includes the entire local vocabulary (subject to any empty-book guard).
3. **Given** review options, **When** they filter by a single status or a single source language and start, **Then** only matching items appear in the session.
4. **Given** review options, **When** they choose **Random** with a count N (default 20 when enough words exist), **Then** the session contains up to N items drawn without obvious always-the-same order bias (fair shuffle).
5. **Given** a mode that yields zero items, **When** they try to start, **Then** they stay on options / Review with a clear message and no empty flashcard session.

---

### User Story 3 - Study with flip, rate, skip, and undo (Priority: P1)

As a learner in a review session, I see progress, flip each card to reveal the back, rate how well I know the word (Don’t Know / Know / Know Well), skip cards I want to leave alone, and undo my last rating when I mis-tap — then finish with a session-complete state.

**Why this priority**: This is the core learning loop; SRS advancement only happens when ratings land correctly.

**Independent Test**: Start a small session (e.g. 3 items), flip, apply each rating type, skip one, undo the last rating, exit, and verify item SRS fields and session progress match expectations.

**Acceptance Scenarios**:

1. **Given** a review session has started, **When** the learner views a card front, **Then** they see the word and a primary context preview, plus progress (current / total).
2. **Given** the card front is showing, **When** they flip (tap or Space on desktop), **Then** the card back appears and rating actions become available.
3. **Given** the card back is showing, **When** they rate Don’t Know / Know / Know Well, **Then** the item’s spaced-repetition state updates per the shared foundation rules, the session advances, and rating controls are blocked while that update is in flight.
4. **Given** a card (front or back), **When** they skip, **Then** the session advances without writing a rating for that item.
5. **Given** they just rated a card, **When** they undo, **Then** the last rating’s SRS change is restored and they can continue the session stack in a sensible order.
6. **Given** all cards are done (rated or skipped through the queue), **When** the session ends, **Then** they see a review-complete state and can leave the session cleanly.
7. **Given** a review session is active, **When** they exit (e.g. Esc / close), **Then** they return to Vocabulary without leaving half-applied UI state; already-committed ratings remain saved.

---

### User Story 4 - Desktop keyboard control during review (Priority: P2)

As a desktop learner, I can drive the flashcard session with keyboard shortcuts without leaving the review surface.

**Why this priority**: Parity with Enjoy web desktop review and faster study; secondary to touch/mouse rating working first.

**Independent Test**: On desktop, start a session and exercise Space (flip), 1/2/3 (rate), arrow keys (previous/skip), and Esc (exit) while focus is in the review UI.

**Acceptance Scenarios**:

1. **Given** a review session is active on desktop, **When** the learner presses Space, **Then** the current card flips (or behaves as flip when already appropriate).
2. **Given** the card back is showing, **When** they press `1` / `2` / `3`, **Then** that maps to Don’t Know / Know / Know Well respectively.
3. **Given** a session stack, **When** they press ← / →, **Then** previous (session stack) / skip occur as defined for review.
4. **Given** a session is active, **When** they press Esc, **Then** they exit review.
5. **Given** a rating mutation is in flight, **When** they press a rating key, **Then** the input does not apply a second concurrent rating.

---

### User Story 5 - Browse, search, filter, and delete words (Priority: P1)

As a learner on **All Words**, I can find items by search and status/language filters, see next-review relative labels and counts, and delete a word after confirmation.

**Why this priority**: Learners need to manage a growing book without starting a review session; delete is required for mistakes and cleanup.

**Independent Test**: Seed a mixed-language book; filter by status and language; search by substring; delete one item with confirm/cancel; verify list and stats update.

**Acceptance Scenarios**:

1. **Given** All Words with multiple items, **When** the learner applies status and/or language filters, **Then** the list shows only matching items.
2. **Given** a filtered list, **When** they type a search string, **Then** the visible list further narrows by case-insensitive contains on word (and language label as on web), without requiring a separate search index.
3. **Given** a list row, **When** they view it, **Then** they see at least status, contexts count, reviews count, and a relative next-review label (overdue / today / tomorrow / in N days as applicable).
4. **Given** they choose delete on an item, **When** they confirm, **Then** the entire item and its contexts are removed and stats/list refresh.
5. **Given** they open delete confirmation, **When** they cancel, **Then** the item remains unchanged.

---

### Edge Cases

- Empty book vs words-but-none-due: distinct empty states; custom review still reachable when words exist.
- Random N larger than book size: session uses all available matching items (no crash, no padding with duplicates).
- Undo with empty undo stack: no-op or disabled control; no corrupt SRS state.
- Double-submit rating / rapid key repeat: only one rating applied per card advance.
- Large personal books (hundreds to low thousands): list filter/search and starting a session remain usable; search stays on the already-filtered in-memory set for this phase.
- Offline: Vocabulary screen, list, delete, and full review/SRS work without network.
- Cross-platform: touch/mouse review on mobile and desktop; keyboard shortcuts apply on desktop review session (in-session), not required as global app hotkeys in this phase.
- Opening rich context actions (play clip, open in player, shadow, AI fetch/persist) is out of scope for this phase — card back may show available text/placeholder tabs without those actions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The product MUST provide a dedicated Vocabulary destination where learners can open Review and All Words after words have been saved locally.
- **FR-002**: Vocabulary MUST show a stats strip: total, due, new, learning, reviewing, mastered — derived from local vocabulary data.
- **FR-003**: The Review tab MUST let learners choose session membership: due, all, by status, by language, or random N (default N = 20 when enough items exist).
- **FR-004**: Starting a review MUST open a focused fullscreen or modal session with progress (current / total), flip, skip, undo (when available), and exit.
- **FR-005**: Card front MUST show the word and a primary context preview; learners MUST flip before rating (or ratings appear only after flip).
- **FR-006**: Rating actions MUST be Don’t Know / Know / Know Well (`0` / `1` / `2`) and MUST advance SRS using the same foundation spaced-repetition rules as Enjoy web / phase 021.
- **FR-007**: Skip MUST advance without writing a rating; undo MUST restore the latest rating’s pre-image for the session’s undo stack.
- **FR-008**: Rating controls (and equivalent shortcuts) MUST be disabled or ignored while a rating write is in progress.
- **FR-009**: Desktop review MUST support in-session shortcuts: Space flip; `1`/`2`/`3` rate; ← previous; → skip; Esc exit.
- **FR-010**: All Words MUST support status filter, language filter, client-side search, delete-with-confirm, and relative next-review labels.
- **FR-011**: Delete from All Words MUST remove the whole vocabulary item and cascade its contexts and local review audits (same semantics as foundation remove).
- **FR-012**: Empty states MUST cover no words and no due items, and MUST not block custom review when words exist.
- **FR-013**: User-visible Vocabulary strings (stats, modes, ratings, empty states, list/delete copy, review chrome) MUST be localized.
- **FR-014**: This phase MUST NOT require: cloud sync, Anki export, Pro gating, home due widget, ebook add, clip playback from review, open-in-player from review, shadow reading from review, or write-through of dictionary/contextual AI onto entities from review tabs (those belong to follow-up phases). Card back may show Context / Dictionary / Notes structure with Notes as placeholder and Context/Dictionary as text/cached-only when available.
- **FR-015**: Navigation IA MUST record a durable decision (shell vs secondary route entry) when implementing the Vocabulary destination; default for this spec is a dedicated secondary route (similar to other non-primary destinations), reachable from Profile (and optionally another clear entry), not a new primary shell tab.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason — especially review selection, flip/rate/skip/undo session flow, list filters/search/delete, and stats/due counts.
- **QR-003**: User-facing strings, controls, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns; desktop shortcuts SHOULD be discoverable in the review UI.
- **QR-004**: Opening Vocabulary, switching tabs, filtering/searching a typical personal book, and advancing a flashcard MUST stay responsive (no multi-second freezes on ordinary device storage).
- **QR-005**: Feature behavior that lands MUST update [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (P1 checklist / status) and any navigation ADR decided for the Vocabulary destination.

### Key Entities *(include if feature involves data)*

- **Vocabulary item / context / review audit**: Existing foundation entities; this phase consumes them for stats, list, session queue, rating, undo, and delete — it does not redefine identity or SRS math.
- **Review session**: Ephemeral queue of items for the current study run, plus progress index, flip state, and undo stack of recently rated item ids.
- **Review selection options**: Mode (due / all / status / language / random), optional status or language filter, optional random count N.
- **Vocabulary stats**: Aggregated counts for the stats strip and empty-state decisions.
- **Word list row presentation**: Item summary for All Words (status, counts, relative next-review label).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A learner with saved words can open Vocabulary and see correct total/due/status counts without restarting the app.
- **SC-002**: A learner can start a due review and complete at least one flip + rating cycle end-to-end in under two minutes in a guided test.
- **SC-003**: In a prepared 5-card session, skip, all three ratings, and one undo each behave correctly (SRS restored on undo; skip leaves SRS unchanged) — verified by automated or scripted checks.
- **SC-004**: All Words search + status/language filters correctly reduce a seeded mixed list; confirmed delete removes the item from list and stats.
- **SC-005**: Distinct empty states appear for empty book vs no due items; custom review remains available when words exist.
- **SC-006**: Desktop in-session shortcuts for flip, rate, skip, and exit work in a manual desktop pass.
- **SC-007**: Scope stays bounded: sync, Anki export, home due widget, and review-context media/AI richness are not required for this phase to be done.

## Assumptions

- Phase **021 foundation** (local items/contexts, add from lookup, SRS + undo data contract) is the prerequisite; this spec assumes that contract is available or lands first if not yet merged.
- Parent phased plan P1 is in scope; P2 (context richness), P3 (sync), P4 (Anki), and home due widget are follow-ups.
- Navigation default: dedicated secondary Vocabulary route (not a new primary shell tab), entered from Profile (and optionally another clear link). Exact chrome can be refined in a short navigation ADR during planning/implementation.
- Review keyboard shortcuts are **in-session only** for this phase (not global hotkey registration), to avoid conflicting with playback shortcuts.
- Random review uses a proper fair shuffle (not a weak always-biased order).
- Delete whole item from All Words matches foundation / web semantics.
- Card back may present Context / Dictionary / Notes tabs for layout parity, but Notes remains placeholder; clip play, open-in-player, shadow, and AI persist are deferred.
- Pro / Anki export entry points are deferred with P4 (not shown as a half-working Export button unless explicitly gated as “coming soon” — prefer omit until export ships).
- Enjoy web Vocabulary Review / All Words behavior remains the UX and SRS behavioral reference for parity testing.
