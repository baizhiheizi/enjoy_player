# Feature Specification: Vocabulary Polish

**Feature Branch**: `025-vocabulary-polish`

**Created**: 2026-07-19

**Status**: Draft

**Input**: User description: "We're going to polish the vocabulary feature. Issues: (1) Vocabulary page layout is messy — too many stats cards take half the screen; (2) Flashcard play buttons are broken — YT clips cannot play in the global mini bar; play clip should show an inline mini player with clip timestamps; echo reading should show an inline recorder (record / playback / assess) like player echo mode; open in player should open the full (not collapsed) player at the correct timestamp; inline player and recorder must not show at the same time; flashcard layout must be mobile-responsive; (3) Local videos behave the same; (4) Multi-context words need context switching in the flashcard."

**Parent feature contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md). Builds on [021-vocabulary-foundation](../021-vocabulary-foundation/spec.md), [022-vocabulary-screen-review](../022-vocabulary-screen-review/spec.md), and [023-vocabulary-context-richness](../023-vocabulary-context-richness/spec.md). This phase **polishes and corrects** Vocabulary home layout and in-session media/practice affordances; it does not expand sync, Anki, or ebook scope.

## Clarifications

### Session 2026-07-19

- Q: Where should clip play and echo recorder live during flashcard review? → A: Shared practice bottom sheet — Play clip and Echo reading open the same sheet host; content swaps (player XOR recorder); dismiss returns to the card (review session stays active)
- Q: Can the learner use the card while the practice sheet is open? → A: Modal practice sheet — learner must dismiss before rating, flipping, or using Context tab controls on the card underneath
- Q: How should the practice sheet look on desktop / wide layouts? → A: Adaptive Enjoy sheet — bottom sheet on phone-width; centered modal sheet on wide/desktop; same modes and modal rules

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scan Vocabulary without drowning in stats (Priority: P1)

As a learner opening Vocabulary on a phone, I immediately see the words I care about (Review / All Words, search, filters, list). Progress stats remain available but no longer consume roughly half the first screen as six large cards.

**Why this priority**: The list and review entry points are the primary jobs of the page; a stats-heavy first viewport makes the book hard to use on mobile.

**Independent Test**: Open Vocabulary on a narrow viewport with a non-empty book; verify the first screen prioritizes navigation + list/search and that stats are compact (or otherwise secondary) while still showing total, due, and status breakdown somewhere reachable.

**Acceptance Scenarios**:

1. **Given** a non-empty Vocabulary book on a phone-width viewport, **When** the learner opens Vocabulary, **Then** Review / All Words (or equivalent primary navigation), search/filters, and at least the start of the word list are reachable without scrolling past a tall six-card stats grid that dominates the first viewport.
2. **Given** Vocabulary is open, **When** the learner looks for progress, **Then** they can still see or reveal at least: total count, due/to-review count, and a status breakdown (new / learning / reviewing / mastered) without leaving the Vocabulary destination.
3. **Given** a wide (desktop/tablet) viewport, **When** they open Vocabulary, **Then** the same information hierarchy remains clear: list and review actions stay primary; stats stay secondary and do not create a sparse, card-heavy wasteland above the list.
4. **Given** an empty book, **When** they open Vocabulary, **Then** the empty state remains clear and the compact stats treatment does not look broken (zeros or hidden empty metrics are acceptable if the empty guidance is obvious).

---

### User Story 2 - Play the media clip in a practice bottom sheet (Priority: P1)

As a learner on a flashcard Context surface for a YouTube or local media context, I tap play clip and hear/see that segment in a **shared practice bottom sheet** with a mini player positioned to the clip’s timestamps — without relying on the global collapsed mini-bar player (which currently fails for YouTube in this flow). The review session stays active; dismissing the sheet returns me to the card.

**Why this priority**: Hearing the original line while studying is core context richness; broken play controls block the main review value of media-sourced words. A sheet keeps the flashcard itself clean.

**Independent Test**: Seed items with one YouTube context and one local-video context that have valid locators; start review; play clip for each; confirm the practice bottom sheet opens with a mini player, seeks to the clip window, and the review session remains active after dismiss.

**Acceptance Scenarios**:

1. **Given** the card back Context surface for a YouTube context with a valid locator, **When** the learner chooses play clip, **Then** the shared practice bottom sheet opens in clip mode and playback covers that clip window (start + duration / end), without requiring the global mini-bar as the only playback chrome.
2. **Given** the card back Context surface for a local video/audio context with a valid locator, **When** the learner chooses play clip, **Then** the same practice-sheet mini-player behavior applies (seek to clip, play while review stays active).
3. **Given** clip playback is active in the sheet, **When** the clip ends or the learner dismisses the sheet, **Then** they remain in the review session on the same card with a sensible idle state.
4. **Given** media is missing, unsupported, or the locator is invalid, **When** they attempt play clip, **Then** they see a clear failure/unavailable state and stay in review — no crash, no silent no-op.
5. **Given** play clip is available, **When** playback starts, **Then** the global collapsed mini-bar is not the required or sole surface for hearing the clip (the practice bottom sheet is the intended play path).

---

### User Story 3 - Practice echo reading in the practice bottom sheet (Priority: P1)

As a learner on a flashcard Context surface, I start echo reading and get a **recorder in the shared practice bottom sheet** — record my reading, play it back, and assess — matching the spirit of player echo mode, without leaving the flashcard session for a separate screen just to practice.

**Why this priority**: Speaking practice next to the word’s media context is a core learning loop; it must work inside review, not only after abandoning the session. The sheet gives the recorder room without crowding the card.

**Independent Test**: From a media-backed context in review, start echo reading; record a short take; play it back; complete or dismiss assessment; confirm the recorder lived in the practice bottom sheet and the session can continue after dismiss.

**Acceptance Scenarios**:

1. **Given** a suitable media context in review, **When** the learner chooses echo reading, **Then** the shared practice bottom sheet opens in echo mode with record, playback, and assess affordances comparable to player echo mode.
2. **Given** the sheet recorder is showing, **When** the learner records and plays back, **Then** those actions complete without navigating away from the review session (dismissing the sheet is not required to finish a take, but leaving review is not required either).
3. **Given** echo reading is not available for the context (missing media, unsupported type, ebook-only, or permission denied), **When** they view Context actions, **Then** echo reading is hidden or disabled with a clear unavailable state.
4. **Given** microphone permission is denied or recording fails, **When** they try to record, **Then** they see a clear error and remain in review.

---

### User Story 4 - Keep clip and recorder mutually exclusive in one sheet (Priority: P1)

As a learner using media practice on a flashcard, I never see the mini player and the recorder competing at the same time; Play clip and Echo reading share one practice bottom sheet host, so choosing one replaces the other’s content (or re-opens the sheet in the other mode).

**Why this priority**: Flashcard chrome is already dense; a single sheet host makes exclusivity natural and keeps the card usable on a phone.

**Independent Test**: On one card, start play clip (sheet shows player); then start echo reading — sheet content swaps to recorder (player stops); reverse the order and confirm the same exclusivity.

**Acceptance Scenarios**:

1. **Given** the practice sheet is open in clip mode, **When** the learner starts echo reading, **Then** the sheet shows the recorder instead (clip playback stops or yields) — not a second stacked sheet with both.
2. **Given** the practice sheet is open in echo mode, **When** the learner starts play clip, **Then** the sheet shows the mini player instead and the recorder is dismissed.
3. **Given** the practice sheet is open on a phone-width viewport, **When** the learner views the review UI, **Then** the flashcard underneath remains the same review session (not a navigation push away from review), the sheet is **modal** (card rating/flip/Context controls are not usable until dismiss), and dismissing the sheet returns focus to the card.

---

### User Story 5 - Open the full player at the right moment (Priority: P1)

As a learner who wants the full player experience for a context’s source (YouTube or local), I choose Open in player and land on the **full player screen (not the collapsed mini-bar)**, at the correct media and timestamp for that context.

**Why this priority**: Deep dive into the source is the escape hatch when inline clip play is not enough; landing collapsed or at the wrong time makes the action feel broken.

**Independent Test**: From Context actions for YouTube and local contexts, confirm Open in player; verify review ends (with confirm if still required), the full player opens expanded, and position matches the context locator start.

**Acceptance Scenarios**:

1. **Given** a resolvable YouTube or local media context, **When** the learner confirms Open in player, **Then** they leave the review session and open the full player screen for that source (not merely the collapsed global mini-bar).
2. **Given** Open in player succeeds, **When** the player appears, **Then** playback position is at (or clearly near) the context’s locator start.
3. **Given** Open in player is offered, **When** the learner cancels a session-ending confirmation (if shown), **Then** they remain on the same card in review.
4. **Given** the source cannot be opened, **When** they attempt Open in player, **Then** they see a clear failure and are not left in a half-exited review with no destination.

---

### User Story 6 - Switch among multiple contexts on a card (Priority: P1)

As a learner reviewing a word that was saved with more than one context, I can navigate between those contexts on the flashcard so clip play, echo reading, open-in-player, and contextual content apply to the context I chose — not only a single default context.

**Why this priority**: The product already allows adding the same word with different contexts; showing only one without a switcher hides saved learning material.

**Independent Test**: Seed one item with three distinct contexts; open it in review; step through each context; for each, verify the displayed sentence/source and that play/echo/open targets that context’s locator.

**Acceptance Scenarios**:

1. **Given** the current vocabulary item has two or more contexts, **When** the learner views the flashcard Context surface, **Then** they see a clear context switcher (e.g. previous/next and/or position like “2 of 3”).
2. **Given** multiple contexts, **When** they switch to another context, **Then** the displayed context text, source labeling, and media actions update to that context.
3. **Given** the practice bottom sheet is open, **When** the learner would switch context, rate, flip, or advance the card, **Then** they must dismiss the modal sheet first (or the product dismisses it as part of that transition) so the wrong segment does not keep playing; exclusivity rules still apply.
4. **Given** the item has exactly one context, **When** they view the Context surface, **Then** no multi-context switcher is required (single-context chrome stays simple).
5. **Given** multiple contexts, **When** they rate the card, **Then** the rating still applies to the vocabulary item’s SRS (context switch does not create separate SRS records per context).

---

### User Story 7 - Flashcard layout stays usable on mobile (Priority: P2)

As a learner on a phone, I can flip, read context, switch contexts, open the practice bottom sheet for play or echo, and rate without a cramped or overflowing card — because practice chrome lives in the sheet rather than crowding the Context tab body.

**Why this priority**: Correct behaviors are unusable if the card cannot breathe on small screens; the sheet is the delivery vehicle for P1 media fixes.

**Independent Test**: Run a review session on a phone-width viewport with multi-context item, open practice sheet (clip then echo), switch contexts, dismiss sheet, flip/rate; verify the card stays usable and the sheet does not trap the session.

**Acceptance Scenarios**:

1. **Given** a phone-width review session with the practice bottom sheet closed, **When** the learner views the Context tab, **Then** word, active context, switcher, and rating/flip controls remain discoverable without a tall embedded player/recorder block.
2. **Given** a wider viewport, **When** the practice sheet opens, **Then** it uses the adaptive Enjoy sheet pattern (centered modal on wide/desktop; bottom sheet on compact) with the same modal rules, without looking broken or implying the learner left the review session.
3. **Given** long context text or many chips/meta rows, **When** the practice sheet is dismissed, **Then** the Context tab content remains scrollable and primary study actions stay reachable.

---

### Edge Cases

- Item with zero contexts: Context surface shows a clear empty state; Dictionary (if present) may still work; play / echo / open / switcher are unavailable.
- Very many contexts (e.g. 10+): switcher remains usable (position indicator + step controls); switching stays responsive.
- Clip shorter than a second or zero-duration locator: play is disabled or fails clearly — no infinite spinner.
- YouTube unavailable / network offline: practice-sheet play fails clearly; local media clip play still works when the file is resolvable.
- Switching cards (next/previous in session) while the practice sheet is open: sheet is dismissed and practice cleared; new card starts clean.
- Open in player after practice sheet was active: sheet closes; review exits cleanly; full player owns the experience; no stuck dual chrome.
- Microphone busy / interrupted by OS: recorder shows recoverable error; session remains.
- Desktop keyboard: when the modal practice sheet is open, Esc (or equivalent) dismisses the sheet first; a subsequent Esc exits review. Rating shortcuts apply only when the sheet is dismissed.
- Attempting to rate/flip via any path while the sheet is open is blocked until dismiss (modal).
- Cross-platform: Android, iOS, macOS, Windows, Linux — YouTube and local paths both covered where that platform already supports those media types.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Vocabulary home MUST present progress metrics in a compact, secondary treatment so that on phone-width viewports the first screen prioritizes Review / All Words, search/filter, and the word list over a six large-card stats grid.
- **FR-002**: Vocabulary home MUST still expose total, due/to-review, and status breakdown (new / learning / reviewing / mastered) on the Vocabulary destination (visible by default in compact form, or one tap/expand away — not removed from the product).
- **FR-003**: On flashcard Context actions, Play clip MUST open the **shared practice sheet** (bottom sheet on compact viewports; centered modal on wide/desktop) in clip mode with a mini player and play the active context’s locator window for both YouTube and local media when resolvable; the review session MUST remain active.
- **FR-004**: Play clip MUST NOT depend on the global collapsed mini-bar as the only way to hear the clip during review.
- **FR-005**: On flashcard Context actions, Echo reading MUST open the **same shared practice sheet** in echo mode with a recorder supporting record, playback, and assess, aligned with player echo-mode practice outcomes; the review session MUST remain active.
- **FR-006**: Clip mini player and echo recorder MUST be mutually exclusive inside that single sheet host: opening one mode replaces the other and stops the prior practice mode’s active capture or clip playback as needed (no stacked dual sheets showing both).
- **FR-006a**: The practice sheet MUST be **modal**: while it is open, the learner MUST NOT rate, flip, or operate Context-tab card controls underneath; dismiss returns to the card. Advancing cards or changing active context MUST dismiss (or equivalently close) the sheet first so practice cannot target the wrong context.
- **FR-006b**: Practice sheet presentation MUST follow the app’s existing adaptive sheet pattern: bottom sheet on phone-width / compact viewports; centered modal sheet on wide / desktop — same clip/echo modes and modal rules on all platforms.
- **FR-007**: Open in player MUST end the review session (after confirmation if the product still requires it) and open the **full** player screen for the active context’s source at the correct timestamp — not the collapsed mini-bar as the destination.
- **FR-008**: Open in player and Play clip / Echo reading behaviors MUST apply consistently to YouTube and local media contexts when each source type is resolvable on the platform.
- **FR-009**: When a vocabulary item has two or more contexts, the flashcard Context surface MUST provide navigation to switch the active context and MUST show which context is active (e.g. index of total).
- **FR-010**: All Context-tab media and AI actions (play clip, echo reading, open in player, contextual content) MUST operate on the **active** context after switching.
- **FR-011**: Switching context or advancing to another card MUST dismiss or rebind the practice bottom sheet so the wrong media segment or recording UI does not linger.
- **FR-012**: Unavailable / failed media, recording, or open-in-player cases MUST show clear user-visible states; they MUST NOT crash the review session or silently no-op.
- **FR-013**: Flashcard layout with context switcher MUST remain usable on phone-width viewports; practice chrome lives in the bottom sheet so the Context tab body is not permanently crowded by an embedded player/recorder.
- **FR-014**: Rating / skip / undo SRS behavior from prior Vocabulary review phases MUST remain intact; context switching MUST NOT invent per-context SRS scores.
- **FR-015**: User-visible strings for compact stats, context switcher, play clip, echo reading, open in player, and related empty/error states MUST be localized.
- **FR-016**: This phase MUST NOT require new cloud sync rules, Anki export changes, home due widget, ebook reader play, or Notes tab content beyond existing placeholder behavior.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason — especially compact Vocabulary home layout, practice-sheet clip play for YouTube and local, practice-sheet echo recorder exclusivity, open-in-player full-screen destination + timestamp, and multi-context switching.
- **QR-003**: User-facing strings, controls, tooltips, and confirmations MUST follow existing localization and shared UI patterns; the practice sheet MUST reuse the app’s adaptive sheet pattern (not a one-off popup); session-ending Open in player MUST remain clearly labeled.
- **QR-004**: Opening Vocabulary, switching contexts, opening/dismissing the practice sheet, and swapping clip/echo modes MUST stay responsive on ordinary devices (no multi-second UI freeze for typical context counts and clip lengths). Practice-sheet media chrome MUST NOT create a second independent media player engine outside the product’s single-player ownership rules.
- **QR-005**: Behavior that lands MUST update [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (layout, flashcard media actions, multi-context navigation) to match what users can do.

### Key Entities *(include if feature involves data)*

- **Vocabulary item**: Word-level entity with SRS state; may own many contexts; ratings still apply at item level.
- **Vocabulary context**: One appearance of the word in media (or other source) with text, source identity, and locator; becomes the **active context** when selected on the card.
- **Media locator**: Start (and duration/end) describing the playable segment for clip play and open-in-player seek.
- **Practice sheet (review)**: Shared ephemeral **modal** sheet host (adaptive Enjoy sheet — bottom sheet on compact, centered modal on wide) opened from Context actions; presents either clip mini-player mode or echo recorder mode (never both); dismiss returns to the card without ending the review session; blocks card rate/flip/Context controls while open.
- **Clip mini player (sheet mode)**: Playback chrome in the practice sheet bound to the active context’s clip window; not the global collapsed mini-bar destination for this flow.
- **Echo recorder (sheet mode)**: Record / playback / assess chrome in the practice sheet for the active context, mutually exclusive with clip mode in the same host.
- **Review session**: Existing flashcard run; continues while the practice sheet is open; ends when Open in player is confirmed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a phone-width guided pass, learners can reach the word list or Review entry within one short scroll (or none) from opening Vocabulary; stats no longer occupy ~half the first viewport as six large cards.
- **SC-002**: In a guided test, Play clip for a YouTube context opens the adaptive practice sheet and covers the locator window without requiring the global mini-bar.
- **SC-003**: In a guided test, Play clip for a local media context behaves the same as YouTube in the practice sheet.
- **SC-004**: In a guided test, Echo reading opens the same practice sheet with a recorder; the learner can record, play back, and assess without leaving the review session.
- **SC-011**: On a wide/desktop guided pass, the practice sheet appears as a centered modal (not a phone-only bottom sheet glued to the wrong edge); on phone-width it appears as a bottom sheet — both modal.
- **SC-005**: Clip player and echo recorder never appear together in usability spot-checks; switching modes swaps sheet content so exactly one mode (or a dismissed sheet) is visible.
- **SC-006**: Open in player lands on the full player screen at the correct timestamp for YouTube and local sources in a manual pass (not the collapsed mini-bar).
- **SC-007**: For an item with 3 contexts, learners can visit each context via the switcher and see play/echo/open target the selected context in a guided test.
- **SC-008**: On phone-width review, the Context tab remains usable without an embedded tall player/recorder; practice happens in the modal bottom sheet; after dismiss the learner can flip/rate without critical overflow; while the sheet is open, rate/flip are not available on the card underneath.
- **SC-010**: In a guided test, with the practice sheet open, the learner cannot successfully rate or flip until the sheet is dismissed (modal).
- **SC-009**: Scope stays bounded: no new sync/Anki/ebook/home-widget requirements for this phase to be done.

## Assumptions

- Phases **021–023** (and shipping Vocabulary screen/review/context richness) are prerequisites; this phase corrects layout and media/practice UX rather than redefining SRS or capture.
- Compact stats may collapse detail (e.g. single summary row + expandable breakdown, or a dense metric strip). Exact visual design is left to planning/UI, as long as FR-001/FR-002 and SC-001 are met.
- “Echo reading” in this spec means **practice-sheet recorder practice** comparable to player echo mode (record / playback / assess). It **supersedes** any prior review behavior that only handed off to a separate shadow/echo screen when an in-session path is feasible.
- Play clip and Echo reading share **one** practice sheet host (content swaps by mode); this is preferred over embedding player/recorder in the Context tab body for a cleaner card.
- The practice sheet is **modal** (blocks card study actions until dismissed); it does not end the review session by itself.
- Practice sheet chrome uses the app’s adaptive sheet pattern (bottom sheet compact / centered modal wide), not a one-off custom popup. Planning may map this to the existing sheet helper.
- Open in player may keep a confirm dialog (session ends) from phase 023; the destination MUST be the full player, not collapsed chrome.
- Global mini-bar may still exist elsewhere in the app; it is simply not the intended play-clip surface during flashcard review.
- YouTube playback continues to use the app’s existing YouTube playback path (not a second media engine); local media continues to use the shared local player ownership model — planning will detail how the practice-sheet video stage binds to that ownership without violating the single-player rule.
- Primary/default context when opening a card remains the existing selection rule (e.g. primary or first); the new work adds explicit switching when `contextsCount > 1`.
- Ebook-only contexts stay unavailable for play / echo / open until an ebook reader exists.
- Dictionary / Notes / AI persist behaviors from 023 remain unless a polish change necessarily touches their layout; they are not the focus of new scope here.
- Cloud sync, Anki export, and home due nudge remain out of scope for this phase.
