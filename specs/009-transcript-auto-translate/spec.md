# Feature Specification: Transcript Auto-Translate

**Feature Branch**: `009-transcript-auto-translate`

**Created**: 2026-07-09

**Status**: Draft

**Input**: User description: "We need support auto-translate for transcript. User could select the primary and the translate subtitle now. We should add an option in the translate subtitle list: `auto translate`. If select, we use the translate API to auto translate the primary transcript line by line. We need schedule the request, make lazy and gracefully retry. With the translation, user could also `re-translate`. Design the UX carefully and make it friendly."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose Auto translate as the translation track (Priority: P1)

A learner already picks a **primary** subtitle and an optional **translation**
subtitle in the subtitle picker. They want a third choice in the translation
list: **Auto translate**. Selecting it starts translating the primary transcript
into their reading language and shows those translations under each primary
line—without requiring them to import or fetch a separate caption file first.

**Why this priority**: This is the core value. Without a clear, selectable Auto
translate option that produces bilingual lines, nothing else in this feature
matters.

**Independent Test**: Open media with a primary transcript, open the subtitle
picker, select **Auto translate** in the translation section, and confirm
translated lines appear under primary cues as they become available.

**Acceptance Scenarios**:

1. **Given** a media item with a usable primary transcript and the user is
   eligible to translate, **When** they open the subtitle picker’s translation
   section, **Then** they see **Auto translate** as a distinct option alongside
   existing translation tracks and **None**.
2. **Given** Auto translate is selected, **When** the picker closes (or while
   it remains open), **Then** the transcript panel shows the primary line as
   usual and fills in the translation line progressively as lines complete—
   never waiting for the entire transcript before showing the first results.
3. **Given** Auto translate is selected, **When** the learner looks at the
   translation section summary (collapsed or selected state), **Then** the UI
   clearly indicates Auto translate is active (not confused with an imported or
   official track), including the target reading language.
4. **Given** the learner selects **None** or another translation track after
   Auto translate, **When** that selection applies, **Then** Auto translate
   stops being the active translation display and the chosen option takes over
   without deleting the learner’s ability to return to Auto translate later.

---

### User Story 2 - Lazy, scheduled translation that stays out of the way (Priority: P1)

Translating a long transcript must not freeze playback, block scrolling, or
feel like a single “please wait” spinner for the whole file. Translation work
is **scheduled lazily**: lines near what the learner is watching (and nearby
context) are preferred first; the rest fill in quietly in the background.
Failed lines **retry gracefully** without nagging the user on every failure.

**Why this priority**: Equal to P1 selection UX—without lazy scheduling and
calm retries, Auto translate feels broken on real lesson lengths.

**Independent Test**: Select Auto translate on a long transcript while playing;
confirm playback stays smooth, nearby lines translate first, distant lines
catch up later, and transient failures recover without a full-page error.

**Acceptance Scenarios**:

1. **Given** Auto translate is active on a multi-hundred-line transcript,
   **When** playback is near the middle, **Then** lines around the current
   playback position receive translation priority over far-away lines.
2. **Given** some lines are still pending, **When** the learner scrolls or
   seeks, **Then** newly relevant lines are prioritized without restarting
   already-finished lines from scratch.
3. **Given** a single line’s translation request fails transiently, **When**
   the scheduler retries, **Then** it backs off and retries a limited number of
   times without blocking other lines or interrupting playback.
4. **Given** translation is in progress, **When** the learner continues
   watching, **Then** the UI remains usable: no modal that must be dismissed,
   and no global spinner that replaces the whole transcript list.
5. **Given** the device is offline or the service is unavailable after
   retries, **When** remaining lines cannot complete, **Then** finished lines
   stay visible, unfinished lines show a calm per-line or summary status, and
   the learner can keep using primary text and playback.

---

### User Story 3 - Friendly progress, empty, and error states (Priority: P2)

The learner should always understand what Auto translate is doing: starting,
working, partially done, stuck, or finished—without technical jargon or raw
error text. Progress should feel light (subtle cues on lines or a compact
status), not alarming.

**Why this priority**: Trust and clarity; poor status UX makes a working
pipeline feel unreliable.

**Independent Test**: Exercise start, mid-progress, partial failure, and
completion; confirm copy and affordances match each state and never expose raw
exception strings as the primary message.

**Acceptance Scenarios**:

1. **Given** Auto translate was just selected and no lines are ready yet,
   **When** the transcript is visible, **Then** the learner sees a friendly
   “translating…” style cue (compact, non-blocking) rather than a blank
   secondary area with no explanation.
2. **Given** some lines are translated and others are pending, **When** viewing
   the list, **Then** completed translations appear under their primary lines
   while pending lines show a discreet waiting state (not a loud error).
3. **Given** translation cannot start (e.g. signed out, or primary language
   matches the target reading language), **When** the learner selects Auto
   translate, **Then** they get a clear, actionable explanation and next step
   (sign in, or choose a different reading language / use None)—not a silent
   no-op.
4. **Given** a permanent failure for the job as a whole, **When** the UI
   surfaces it, **Then** the message is friendly, offers **Retry** / **Re-translate**,
   and never shows raw technical exception text as the main copy.

---

### User Story 4 - Re-translate when the learner wants a fresh pass (Priority: P2)

After Auto translate has run (fully or partially), the learner can explicitly
**Re-translate**. This refreshes translations for the current primary content
and target reading language—useful after primary text changed, quality was
poor, or they want to retry after fixing connectivity or account issues.

**Why this priority**: Completes the control loop; without it, stale or bad
translations are sticky.

**Independent Test**: With Auto translate active and some/all lines filled,
invoke Re-translate and confirm translations refresh according to the
re-translate rules, with clear progress again.

**Acceptance Scenarios**:

1. **Given** Auto translate is the active translation selection, **When** the
   learner opens the subtitle picker (or the Auto translate detail affordance),
   **Then** a **Re-translate** action is available and clearly labeled.
2. **Given** the learner chooses Re-translate, **When** confirmation is
   accepted (if shown), **Then** existing auto-translated lines for this
   primary + target pair are replaced as new results arrive, and progress UX
   returns to the in-progress pattern.
3. **Given** Re-translate is running, **When** the learner keeps watching,
   **Then** playback is not blocked; lines update as new translations complete.
4. **Given** Auto translate is not selected (None or another track), **When**
   the learner views the picker, **Then** Re-translate is not offered as a
   primary action for unrelated tracks (it belongs to the Auto translate
   flow).

---

### User Story 5 - Persist and resume without surprise cost or duplicate work (Priority: P3)

Returning to the same media should feel instant when translations already
exist. The app should not re-translate every line from scratch on every open.
Switching away and back to Auto translate reuses stored results when still
valid for the same primary content and target language.

**Why this priority**: Saves time, credits, and frustration; builds on P1/P2.

**Independent Test**: Complete (or partially complete) Auto translate, leave
the media, reopen it, select Auto translate again; confirm prior lines appear
immediately and only missing/invalid lines are scheduled.

**Acceptance Scenarios**:

1. **Given** Auto translate previously completed for this media’s primary and
   target language, **When** the learner reopens the media and selects Auto
   translate, **Then** translations appear immediately without a full re-run.
2. **Given** Auto translate was only partially complete, **When** the learner
   returns later with Auto translate selected, **Then** finished lines show at
   once and only remaining lines are scheduled.
3. **Given** the primary transcript content that Auto translate was based on
   has materially changed, **When** Auto translate is active again, **Then**
   the product either refreshes outdated lines or prompts Re-translate so the
   learner is not left with mismatched translations silently forever.

---

### Edge Cases

- Primary transcript is missing, still loading, or empty: Auto translate is
  unavailable or explained; selecting it does not crash or spin forever.
- Primary language equals the target reading language: Auto translate explains
  that translation is unnecessary and does not burn translation requests.
- Learner is signed out or otherwise ineligible: friendly account / eligibility
  callout with a path to fix it (consistent with other translation surfaces).
- Very long transcripts (thousands of lines): scheduling stays lazy; UI never
  requires the full job to finish before useful bilingual reading.
- Rapid seek / scrub while translating: priority follows the new position;
  no request stampede that freezes the app.
- Switch primary track while Auto translate is active: translations tied to the
  old primary are not shown as if they matched the new primary; the product
  reschedules or asks for Re-translate as appropriate.
- Switch target reading language: prior auto-translations for another language
  are not mixed in; a new Auto translate pass (or stored track for that
  language) is used.
- Offline mid-job: keep completed lines; show calm incomplete state; resume or
  retry when connectivity returns without wiping progress.
- User deletes the auto-translated track (if deletion is offered): selection
  falls back safely (e.g. None) and session references stay consistent.
- Concurrent Re-translate while a prior job is running: the newer intent wins
  cleanly; the learner does not see interleaved conflicting text for long.
- Platform input: works on Android, iOS, macOS, and Windows with the existing
  subtitle picker presentations (sheet vs dialog) and transcript list patterns.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The translation (secondary) subtitle list MUST include an **Auto
  translate** option in addition to existing tracks and **None**.
- **FR-002**: Selecting Auto translate MUST set it as the active translation
  selection for the current media session and display auto-translated text
  under primary cues when available.
- **FR-003**: Auto translate MUST translate from the active **primary**
  transcript, line by line, into the learner’s **target reading language**
  (default: profile native language when it differs from the primary language).
- **FR-004**: Translation work MUST be **lazy and scheduled**: prefer lines
  near the current playback position and nearby viewport context; continue
  remaining lines in the background without blocking playback or list
  scrolling.
- **FR-005**: The scheduler MUST **retry failed line requests gracefully**
  (bounded retries with backoff) and MUST continue other lines while retries
  are pending.
- **FR-006**: The UI MUST show **progressive** results: each completed line
  appears under its primary cue without waiting for the entire transcript.
- **FR-007**: While Auto translate is active, the product MUST expose a
  **Re-translate** action that refreshes auto-translations for the current
  primary + target language pair.
- **FR-008**: Re-translate MUST make it obvious that a new pass is running and
  MUST update lines as new results arrive (playback remains usable).
- **FR-009**: Completed auto-translations MUST be **persisted** for the media
  so reopening or re-selecting Auto translate reuses finished lines instead of
  always starting from zero.
- **FR-010**: Partial progress MUST be retained across interruptions (app
  backgrounding, navigation away, transient network loss) so resume continues
  from unfinished lines.
- **FR-011**: When Auto translate cannot start (no primary, ineligible account,
  identical source/target language, etc.), the product MUST show a **friendly,
  actionable** explanation instead of failing silently or with raw errors.
- **FR-012**: Per-line and job-level failure copy MUST be user-friendly; raw
  exception text MUST NOT be the primary message.
- **FR-013**: Selecting **None** or another translation track MUST stop Auto
  translate from being the displayed translation without requiring the learner
  to understand internal job state.
- **FR-014**: Auto translate status in the picker MUST be visually distinct
  from imported / official / other provider tracks (label and/or badge) so
  learners know the source is generated translation.
- **FR-015**: Changing the primary transcript while Auto translate is selected
  MUST NOT leave mismatched secondary text presented as correct; the product
  MUST reschedule, clear stale pairs, or require Re-translate with clear UX.
- **FR-016**: Auto translate MUST NOT replace or remove the learner’s ability
  to choose real translation caption tracks when those exist; it is an
  additional option in the same list.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first
  architecture and avoid feature-to-feature shortcuts unless the plan documents
  an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual
  verification reason.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard
  affordances MUST follow existing localization and shared UI patterns
  (subtitle picker sheet/dialog, transcript secondary-line hierarchy, friendly
  error + Retry patterns).
- **QR-004**: Selecting Auto translate and watching with an in-progress job
  MUST keep playback and transcript scrolling responsive; translation work MUST
  not cause sustained UI jank on typical lesson lengths (hundreds of lines) on
  supported desktop and mobile targets.
- **QR-005**: Feature behavior changes MUST update the matching documentation
  under `docs/features/` (transcript feature doc; remove “auto-translate” from
  Future once shipped).
- **QR-006**: Progress and pending states MUST stay **calm and compact**—no
  full-screen blocking modal for routine translation progress; prefer inline /
  summary cues consistent with existing transcript fetch affordances.
- **QR-007**: Re-translate SHOULD confirm when it will redo a large amount of
  work (e.g. a fully completed long transcript), using a short, plain-language
  confirm so accidental taps do not surprise the learner.

### Key Entities

- **Primary transcript**: The active source cue list the learner is studying;
  Auto translate always reads from this track’s lines.
- **Auto-translate selection**: A translation-list choice (not merely a
  one-shot button) meaning “show generated translations for this media.”
- **Auto-translated line**: One primary cue’s translated text in the target
  reading language, with status such as pending, ready, or failed.
- **Translation job (logical)**: The scheduled work for a media + primary +
  target language pair, including priority order, retry state, and completion
  progress.
- **Target reading language**: Language Auto translate writes into; defaults to
  the learner’s native language when distinct from the primary language.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In usability checks, at least **90%** of participants find and
  select Auto translate from the translation list on the first try without
  help.
- **SC-002**: After selecting Auto translate on a ≥100-line transcript, the
  first translated lines near the current playback position appear within
  **10 seconds** under normal connectivity (excluding account/eligibility
  blockers).
- **SC-003**: While Auto translate is running, learners can play, pause, seek,
  and scroll the transcript without a blocking modal; subjective “UI stayed
  usable” passes for **≥90%** of test sessions on long transcripts.
- **SC-004**: After a transient single-line failure, **≥95%** of those lines
  either succeed on retry or surface a calm failed state without aborting the
  whole job.
- **SC-005**: Reopening media with a previously completed Auto translate shows
  translations **immediately** (no full re-translation) in **100%** of
  regression checks for unchanged primary + target language.
- **SC-006**: Re-translate is discoverable from the Auto translate context in
  **≤2 taps/clicks** from the subtitle picker when Auto translate is selected.
- **SC-007**: **100%** of user-visible error/empty/progress strings for this
  feature are localized and free of raw exception text as the primary message.
- **SC-008**: On supported platforms, transcript list scrolling during an
  active job remains smooth enough that test reviewers do not observe sustained
  hitching attributable to translation scheduling on a ~500-line sample.

## Assumptions

- Target reading language for Auto translate defaults to the learner’s **profile
  native language**, matching the bilingual YouTube caption intent; a dedicated
  per-job language picker is out of scope unless native language is missing or
  equals the primary language (then the product explains and guides).
- Auto translate uses the product’s existing **translation** capability (same
  family of service already used for selection lookup translation), including
  normal sign-in / eligibility / credit behavior already established for AI
  translation surfaces.
- Auto-translated results are stored as a durable translation artifact for the
  media (conceptually an AI-sourced translation track) so they can be reselected
  and resumed; exact storage shape is a planning concern.
- “Lazy” means priority by playback/viewport relevance, not “translate only on
  explicit per-line tap.” Background fill of the rest of the transcript is
  expected once Auto translate is selected.
- Re-translate refreshes the auto-translated artifact for the current primary +
  target pair; it does not delete unrelated imported caption files.
- Confirming Re-translate on a large completed job is preferred UX; tiny or
  empty jobs may skip confirm.
- This feature does not replace YouTube bilingual caption fetch when that path
  already supplies a native translation track; Auto translate remains available
  when the learner wants generated translation from the primary text instead
  (or when no suitable translation track exists).
- Export of auto-translated subtitles, multi-target-language Auto translate in
  one session, and editing individual translated lines are out of scope for
  this change.
- Web targets remain out of scope per product platform policy.
