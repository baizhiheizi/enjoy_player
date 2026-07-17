# Feature Specification: Vocabulary Context Richness

**Feature Branch**: `023-vocabulary-context-richness`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "continue the implement the vocabulary feature in doc docs/features/vocabulary.md."

**Parent feature contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (**P2** — Context richness). Builds on local capture / SRS from [021-vocabulary-foundation](../021-vocabulary-foundation/spec.md) and Vocabulary screen / flashcard session from [022-vocabulary-screen-review](../022-vocabulary-screen-review/spec.md). Follow-ups cover cloud sync (P3), Anki export (P4), and home due nudge.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use dictionary on the card back and keep the result (Priority: P1)

As a learner reviewing a flashcard, I open the Dictionary tab on the card back, see a dictionary explanation when one is already saved or after I fetch one (when signed in / credits allow), and that explanation stays on the word for later reviews and offline re-open.

**Why this priority**: Without write-through, every review re-fetches or shows empty dictionary content; caching on the item is core web parity and unlocks richer offline study.

**Independent Test**: Start a review on an item with no saved explanation; open Dictionary; fetch (or use a stubbed successful fetch); leave and reopen the same item’s Dictionary tab offline — explanation still appears.

**Acceptance Scenarios**:

1. **Given** the card back is showing and the item already has a saved dictionary explanation, **When** the learner opens the Dictionary tab, **Then** they see that explanation without needing a network call.
2. **Given** Dictionary has no saved explanation and the learner is allowed to use dictionary lookup, **When** they request a dictionary result, **Then** a successful result is shown and persisted on that vocabulary item.
3. **Given** Dictionary has no saved explanation and the learner is offline or not allowed to fetch, **When** they open Dictionary, **Then** they see a clear unavailable / empty state (not a crash or blank broken tab).
4. **Given** a dictionary result was just persisted, **When** they advance cards and later return to the same word (same or later session), **Then** the saved explanation is still available.

---

### User Story 2 - Use contextual translation on a context and keep the result (Priority: P1)

As a learner on the Context tab, I can view or request a contextual translation for the current sentence/context; a successful result is saved on that context so offline re-open and later export readiness work.

**Why this priority**: Contextual meaning is how learners connect the word to the media sentence; persistence matches Enjoy web and avoids repeat AI cost.

**Independent Test**: Open Context tab for an item with a media context and no cached translation; fetch successfully; reopen offline and confirm the translation is still shown for that context.

**Acceptance Scenarios**:

1. **Given** the Context tab and a context with a saved contextual translation, **When** the learner views it, **Then** the translation is shown without requiring a network call.
2. **Given** no saved contextual translation and the learner is allowed to use contextual AI, **When** they request translation, **Then** a successful result is shown and persisted on that vocabulary context.
3. **Given** no saved translation and fetch is unavailable (offline / auth / credits), **When** they open or request contextual translation, **Then** they see a clear unavailable / empty state.
4. **Given** multiple contexts on one item, **When** a translation is saved for one context, **Then** other contexts are unchanged.

---

### User Story 3 - Hear the media clip for the current context (Priority: P1)

As a learner on the Context tab for a media-backed context, I can play the short segment defined by the context locator (start + duration) without leaving the review session and without starting a second independent media player engine.

**Why this priority**: Hearing the original line while studying is the main “context richness” value of media-sourced vocabulary.

**Independent Test**: Seed an item with a media context locator; start review; from Context tab play the clip; confirm audible/seek behavior covers the locator window and review session remains active.

**Acceptance Scenarios**:

1. **Given** a media context with a valid locator (start and duration), **When** the learner chooses play segment, **Then** playback covers that segment using the existing shared player (no second player instance).
2. **Given** clip playback is running, **When** the segment ends (or the product’s clip-complete behavior fires), **Then** the learner remains in the review session with a sensible idle state (not forced out of review).
3. **Given** a context without a playable media locator (missing source, unsupported type, or ebook-only), **When** they view Context actions, **Then** play segment is unavailable or clearly disabled with an understandable empty/unavailable state — not a crash.
4. **Given** the source media is missing or cannot open, **When** they attempt play segment, **Then** they see a clear failure message and stay in review.

---

### User Story 4 - Open the full player from review (with confirm) (Priority: P2)

As a learner who wants the full player experience for a context’s source, I can choose Open in player; I am warned that this ends the review session; on confirm I leave review and land in the player at the relevant media/position; on cancel I stay in review.

**Why this priority**: Web parity for deep dive into the source; secondary to in-session clip play because it intentionally interrupts study.

**Independent Test**: From Context tab choose Open in player; cancel once (session continues); confirm once and verify review ends and player opens at the expected media/position.

**Acceptance Scenarios**:

1. **Given** a media context with a resolvable source, **When** the learner chooses Open in player, **Then** they see a confirmation that opening the player will end the review session.
2. **Given** that confirmation, **When** they cancel, **Then** they remain in the review session on the same card.
3. **Given** that confirmation, **When** they confirm, **Then** the review session ends and they open the player for that source near the context’s locator start.
4. **Given** the source cannot be opened, **When** they confirm Open in player, **Then** they see a clear failure and are not left in a half-exited review with no destination.

---

### User Story 5 - Start shadow reading from the context (Priority: P2)

As a learner on the Context tab, I can enter shadow reading for the current media context using the same patterns as elsewhere in the app, without inventing a second player.

**Why this priority**: Web review Context tab offers shadow as a practice affordance; valuable for speaking practice but secondary to clip play and AI persist.

**Independent Test**: From a media-backed context in review, start shadow reading; verify the flow matches existing shadow-reading entry expectations for that media span and does not create a second player.

**Acceptance Scenarios**:

1. **Given** a media context suitable for shadow reading, **When** the learner chooses shadow reading from the Context tab, **Then** they enter the existing shadow-reading experience for that span (or the product’s confirmed exit/hand-off if shadow cannot run inside the review chrome).
2. **Given** shadow reading is not available for the context (ebook-only, missing media, or unsupported), **When** they view Context actions, **Then** shadow reading is hidden or disabled with a clear unavailable state.
3. **Given** starting shadow reading requires leaving fullscreen review, **When** that hand-off occurs, **Then** the transition is intentional (confirm if it ends review) and does not corrupt SRS state already saved in the session.

---

### Edge Cases

- Card back with no contexts: Context tab shows a clear no-context state; Dictionary may still work from the item alone.
- Multiple contexts: primary/default context drives preview and default actions; learner can still access the context used for the card (same selection rule as current review UI).
- Offline: previously persisted dictionary / contextual explanations remain readable; new AI fetches fail gracefully; local clip play still works when media is local and resolvable.
- Network / auth / credits failures for AI: user-visible messages consistent with dictionary-lookup / AI elsewhere; no silent failure that looks like success.
- Concurrent rate vs AI fetch: rating still blocked while a rating mutation is in flight; AI fetch MUST NOT corrupt SRS fields.
- Open in player / shadow hand-off mid-session: already-committed ratings remain saved; unrated current card is not falsely marked reviewed.
- Ebook locators: schema may exist, but ebook play / open / shadow remain unavailable until ebook reader exists — show unavailable, do not pretend.
- Cross-platform: touch and desktop; clip and open-in-player must not require a second media engine on any supported platform.
- Large explanation payloads: Dictionary / Context tabs remain usable (scrollable content; no multi-second UI freeze on ordinary device storage when opening a cached explanation).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On the flashcard back, Context / Dictionary / Notes tabs MUST remain; Notes MAY stay a “coming soon” placeholder in this phase.
- **FR-002**: Dictionary tab MUST display a persisted item-level dictionary explanation when present, and MUST allow fetching one when allowed by existing dictionary / AI auth and credit rules, then persist the successful result on the vocabulary item.
- **FR-003**: Context tab MUST display context text, source identity/title when available, and locator-relevant labeling for the active context.
- **FR-004**: Context tab MUST allow requesting contextual translation when allowed by existing AI rules, and MUST persist a successful result on that vocabulary context.
- **FR-005**: When AI fetch is unavailable or fails, Dictionary and contextual translation MUST show clear empty/error states; empty cache MUST NOT invent offline AI results.
- **FR-006**: For media contexts with a valid media locator, Context tab MUST offer play-segment that plays the locator window through the app’s existing shared player ownership rules (never a second independent media player).
- **FR-007**: Context tab MUST offer Open in player for resolvable media sources, with a confirmation that continuing ends the review session; cancel keeps the session; confirm exits review and opens the player near the locator start.
- **FR-008**: Context tab MUST offer shadow reading for suitable media contexts, reusing existing shadow-reading patterns; unavailable cases MUST be hidden or disabled clearly. If starting shadow reading ends or leaves review, the product MUST confirm or otherwise make that hand-off intentional, and MUST NOT alter already-saved ratings incorrectly.
- **FR-009**: Ebook-only contexts remain schema-compatible but MUST NOT claim play / open-in-player / shadow success until ebook reading exists.
- **FR-010**: Persisted dictionary and contextual explanation shapes MUST remain compatible with the parent feature’s documented dictionary / contextual translation payloads so later Anki export and sync can consume them without re-keying.
- **FR-011**: User-visible strings for Context / Dictionary / Notes actions, open-in-player confirmation, shadow, contextual translation, and unavailable states MUST be localized.
- **FR-012**: This phase MUST NOT require: cloud sync of vocabulary entities, Anki CSV export, Pro gating, home due widget, ebook add-from-reader, tags/batch import, or Notes content beyond placeholder.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason — especially explanation persist, clip play hand-off, open-in-player confirm/exit, and shadow entry availability.
- **QR-003**: User-facing strings, controls, tooltips, and confirmations MUST follow existing localization and shared UI patterns; destructive or session-ending actions (Open in player, and shadow if it ends review) MUST use clear confirm copy.
- **QR-004**: Opening Dictionary/Context with cached explanations, starting clip playback, and advancing cards MUST stay responsive (no multi-second freezes on ordinary device storage for typical explanation sizes). Clip playback MUST NOT introduce a second media player instance.
- **QR-005**: Feature behavior that lands MUST update [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (P2 checklist / status) and related docs (e.g. shadow-reading cross-links) when behavior changes.

### Key Entities *(include if feature involves data)*

- **Vocabulary item**: Existing word-level entity; gains write-through of cached dictionary explanation from review Dictionary tab.
- **Vocabulary context**: Existing appearance-in-media entity; gains write-through of cached contextual translation; carries media/ebook locator used for clip play and open-in-player.
- **Media locator**: Start + duration (milliseconds) describing the playable segment for a media context.
- **Review session**: Existing ephemeral study run; may end when Open in player (or shadow hand-off) is confirmed; already-committed ratings remain authoritative.
- **Dictionary explanation / contextual translation**: Cached AI payloads stored on item / context respectively; readable offline once saved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a guided test, a learner can fetch a dictionary explanation during review and see the same explanation again after restarting the app offline.
- **SC-002**: In a guided test, a learner can fetch a contextual translation for a media context and see it again offline on that same context.
- **SC-003**: From Context tab, play segment starts within a few seconds for a local resolvable media file and covers the locator window without ending the review session.
- **SC-004**: Open in player shows confirm; cancel keeps review; confirm ends review and opens the correct source near the context start in a manual pass.
- **SC-005**: Shadow reading is reachable from a suitable media context (or clearly unavailable when not), without creating a second media player.
- **SC-006**: Scope stays bounded: sync, Anki export, home due widget, and ebook add are not required for this phase to be done.
- **SC-007**: Failure and empty states for offline/unavailable AI and missing media are understandable without support intervention in usability spot-checks.

## Assumptions

- Phases **021** (foundation) and **022** (screen + review session with Context/Dictionary/Notes chrome) are prerequisites; this phase enriches the card-back actions those surfaces already expose or stub.
- Parent phased plan **P2** is in scope; **P3** (sync), **P4** (Anki), and home due widget remain follow-ups.
- Shadow reading is included for Enjoy web Context-tab parity; if product later drops it, the story can be deferred without blocking AI persist or clip play.
- Open in player always ends the review session after confirm (web parity).
- Clip playback keeps the learner in review when possible; it uses the single shared player ownership model already required by the product constitution.
- Dictionary and contextual AI reuse existing lookup/AI eligibility (signed-in, credits / BYOK as elsewhere) — this phase does not invent a new entitlement model.
- Notes tab remains placeholder unless product expands scope.
- Enjoy web Vocabulary review Context / Dictionary behavior remains the UX reference for parity testing.
- Primary context selection for the flashcard continues the rule already used in phase 022 (no redesign of multi-context picker required unless needed for play/translate accuracy).
