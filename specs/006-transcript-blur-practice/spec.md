# Feature Specification: Transcript Blur (Practice / Listening-Focus Mode)

**Feature Branch**: `[006-transcript-blur-practice]`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "We'll add a new feature for the transcript lines. User should toggle it to make all transcript blur, so that they could focus on the original video/audio and guess what they hear to practice. When user hover on the line, it should remove the blur and display clearly. And in Android/iOS, we don't have `hover`, we need to design it carefully about when to remove blur."

## Clarifications

### Session 2026-07-08

- Q: The original draft proposed an "always reveal the actively playing cue" rule (Story 3) as the bridge between desktop hover and mobile interactions. The user corrected this — the purpose of the feature is hearing-focused practice, so revealing the active line defeats the goal. The active cue must be treated like every other cue: blurred, with no auto-reveal. → A: Remove the "always reveal active line" rule and its associated preference override entirely. The active cue has no special treatment.
- Q: On mobile, when the user taps a blurred cue, what should tap do? (Existing tap-to-seek + new reveal, or a different combination?) → A: Tap = seek + reveal hold. Tap keeps the existing tap-to-seek behavior AND triggers the configured tap-reveal hold window so the user can verify what they just heard.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Toggle blur practice mode (Priority: P1)

A language learner opens a library item with a transcript, opens the transcript panel, and wants to practice listening without reading ahead. They tap a single "Blur practice" toggle (icon button + label) in the transcript panel header. All visible transcript cue text immediately becomes blurred (legible enough to know there is text, not legible enough to read). The toggle stays in its "on" state and the icon indicates that state clearly. Tapping it again restores normal rendering instantly.

**Why this priority**: This is the headline capability — without the toggle and the visual blur, none of the listening-focus behavior matters. It is the smallest slice that delivers the new practice value.

**Independent Test**: Can be fully tested by opening any library item that has a transcript, locating the toggle in the transcript panel, and asserting that toggling switches every rendered cue between blurred and clear states with no other UI regression. It delivers value on its own (listener can self-quiz without auto-reveal).

**Acceptance Scenarios**:

1. **Given** a transcript panel is showing lines and blur practice mode is off, **When** the user taps the "Blur practice" toggle, **Then** every visible cue body text becomes blurred while cue structure (timestamps, recording badges, layout) stays intact, and the toggle shows an "on" indicator.
2. **Given** blur practice mode is on, **When** the user taps the toggle again, **Then** every cue body text returns to the normal rendered state within one frame and the toggle shows an "off" indicator.
3. **Given** blur practice mode is on, **When** the user opens a different media item, **Then** the new transcript panel starts with the same on/off state the user last selected (the setting is per-user, not per-track).
4. **Given** blur practice mode is on, **When** there are zero transcript lines, **Then** the toggle is disabled with a tooltip explaining there is nothing to practice with.

---

### User Story 2 - Desktop reveal-on-hover (Priority: P1)

On macOS and Windows, a user has blur practice mode on. They move the mouse pointer over a specific cue they want to peek at; that cue's text becomes sharp and readable while the pointer stays over it. As soon as the pointer leaves the cue, it blurs again. They can hover one cue, then move to a neighboring cue, without losing focus. Tapping the cue still seeks playback (existing tap-to-seek behavior is preserved).

**Why this priority**: Hover is the desktop-native reveal primitive and is the second half of the desktop contract. Without it, blur practice mode would be unusable on macOS/Windows because the user would be locked out of any text.

**Independent Test**: Can be tested independently on desktop by enabling blur practice mode and moving a pointer in/out of a cue row, asserting the blur state changes only for the hovered row, and that tapping the row still seeks playback. Pointer-out blurs again within one frame.

**Acceptance Scenarios**:

1. **Given** blur practice mode is on and the platform exposes pointer hover (macOS, Windows), **When** the pointer enters a cue row, **Then** that cue's body text becomes sharp and readable; all other cues remain blurred.
2. **Given** a cue is currently revealed via hover, **When** the pointer leaves that cue row, **Then** the cue returns to the blurred visual state within one frame.
3. **Given** blur practice mode is on, **When** the user taps a cue while the pointer is over it, **Then** playback seeks to the cue's start time, the cue unblurs for the tap-reveal hold window, and — even if the cue becomes the active playback line during that window — it re-blurs when the timer expires.
4. **Given** blur practice mode is off, **When** the user hovers a cue, **Then** cue appearance is identical to today's hover tint (no blur/unblur animation, no behavior change).

---

### User Story 3 - Mobile / touch explicit reveal (Priority: P1)

On Android and iOS, where pointer hover is not available, the user can tap a cue to seek playback AND temporarily reveal that cue so they can verify what they just heard. The reveal is held for a short window (default: 3 seconds, configurable in settings) and then re-blurs. Tapping a different cue moves the hold to that cue and resets the timer. If the user keeps tapping cues, the hold never expires while taps are happening. The active playback cue has NO special reveal — it is blurred like every other cue, so the only way a mobile user can ever see any text is by explicitly tapping or hovering.

**Why this priority**: This is the primary reveal primitive on touch-only platforms. Without it, blur practice mode on Android/iOS would be unusable (no hover, no auto-reveal, no way to peek). It is the minimum viable touch story and is therefore P1, not P2.

**Independent Test**: Can be tested on a touch-only platform by enabling blur practice mode, starting playback, and asserting every cue stays blurred as playback crosses cue boundaries. Then tapping a cue and asserting it unblurs for the hold window while the playback head also moves to that cue's start. After expiry, the cue re-blurs even though it is now the active cue.

**Acceptance Scenarios**:

1. **Given** blur practice mode is on and the platform is touch-only (Android/iOS), **When** playback crosses a cue boundary, **Then** every cue — including the newly-active one — remains blurred; the active cue is NOT auto-revealed.
2. **Given** blur practice mode is on, **When** the user taps a blurred cue, **Then** playback seeks to the cue's start time AND the cue unblurs immediately and stays unblurred for the configured hold window (default 3 seconds).
3. **Given** a cue is held revealed by a tap, **When** the hold window expires with no further taps, **Then** the cue re-blurs within one frame, even if it is still the current active cue.
4. **Given** cue A is held revealed, **When** the user taps cue B, **Then** playback seeks to cue B's start, cue B unblurs, cue A re-blurs immediately, and the hold timer restarts.
5. **Given** blur practice mode is on and the platform exposes pointer hover (macOS/Windows), **When** the user taps a cue, **Then** the cue seeks playback AND unblurs for the same hold window (desktop still benefits from a non-hover reveal path, e.g. for users on touchscreens or with reduced hover reliability).
6. **Given** blur practice mode is off, **When** the user taps a cue, **Then** only the existing tap-to-seek behavior fires (no temporary reveal, no hold window).

---

### User Story 4 - Settings, persistence, and a11y (Priority: P2)

The toggle state and the mobile hold duration are exposed in the user-facing settings area (transcript subsection) and persisted across app restarts. The blur effect itself is purely visual and does not affect screen readers, lookup (dictionary) interactions, or text selection on revealed lines. The blur toggle is announced with a tooltip and (on touch / TalkBack / VoiceOver focus) a semantics label.

**Why this priority**: Without persistence, the user has to re-enable blur practice mode every time they open the app, which kills the practice workflow. Without a11y parity, the feature excludes visually-assisted users.

**Independent Test**: Can be tested by toggling the feature, restarting the app, and verifying state survives. Also by enabling TalkBack/VoiceOver on a cue and asserting the screen reader reads the unblurred text regardless of visual state.

**Acceptance Scenarios**:

1. **Given** the user enables blur practice mode, **When** they close and reopen the app, **Then** blur practice mode is on for the first transcript they open.
2. **Given** the user changes the hold duration in settings, **When** they next tap-reveal a cue on mobile, **Then** the cue stays unblurred for the new duration.
3. **Given** a cue is visually blurred, **When** a screen reader focuses on the line, **Then** the reader announces the cue text in full (blur is decorative, not a content gate).
4. **Given** the toggle button, **When** the user hovers or focuses it with keyboard / screen reader, **Then** a tooltip and semantics label clearly describe the on/off state and the platform-specific reveal mechanism.

---

### Edge Cases

- **No transcript loaded**: toggle is disabled with a tooltip; no blur styling is applied to the empty state or skeleton.
- **Empty / very short cues**: a one-character cue is still blurred, but the blur radius should be clamped to a minimum so the text doesn't disappear entirely; the cue must always be visually discoverable.
- **Secondary / translation track**: the blur applies to both the primary cue body and the secondary (translation) cue body so the practice mode is consistent across the row. Timestamp, recording badge, and rail styling are never blurred.
- **Echo mode**: when the transcript is rendered inside the echo region, blur practice mode continues to apply to cue bodies. Hover and tap-reveal still work on echo cues. The merged echo card and shadow-reading panel are not affected.
- **Very long libraries / many cues**: blur is applied per-widget; rendering must remain smooth while scrolling (no per-frame expensive work — see Performance).
- **Rapid hover / tap flicker**: hovering across adjacent cues, or tapping cues quickly, must not cause visible flicker or jank. Hover-out and hold-expiry should debounce at one frame.
- **Offline / sync**: blur practice mode is a local UI preference and has no cloud-sync implication. Toggling it while offline must work.
- **Platform parity**: hover is only registered on platforms that report pointer devices (macOS, Windows desktop). On Android/iOS the hover handler is inert; only tap-reveal fires. The active playback cue has NO platform-specific auto-reveal — it is blurred on every platform unless the user explicitly hovers or taps it.
- **Active playback cue during blur practice**: because no cue is ever auto-revealed, the user listening to playback in blur practice mode relies on hover (desktop) or tap-reveal (mobile) to verify any cue — including the one currently being played. After the active cue passes, the user must explicitly tap (or hover, on desktop) to peek at it. Tap-reveal on the active cue works exactly as for any other cue; the reveal does not persist just because it became the active cue.
- **Reduced motion**: the blur transition between blurred and revealed should respect the user's reduced-motion preference (no animated filter; instant on/off, or a short opacity transition only when reduced motion is off).
- **Settings reset / sign-out**: clearing app preferences resets blur practice mode to off; sign-out does not change it (it is a device-local preference).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose a "Blur practice" toggle inside the transcript panel header (or another discoverable, persistent location in the panel) that turns the visual blur of every transcript cue body on or off for the current media.
- **FR-002**: When blur practice mode is on, the system MUST render every cue body text with a visual blur effect whose strength makes the text not directly readable while leaving the line's structure (timestamp, badge, layout, color hints) intact.
- **FR-003**: When blur practice mode is off, the system MUST render cue body text identically to today's behavior; the feature MUST NOT introduce any residual blur, tint, or animation when off.
- **FR-004**: On platforms that report pointer hover (macOS, Windows), the system MUST unblur the cue currently under the pointer and re-blur it within one frame after the pointer leaves the cue's hit area. The reveal must follow the pointer from cue to cue.
- **FR-005**: On every supported platform — including when the cue is the currently active playback cue — the system MUST NOT auto-reveal any cue. The only ways to see a cue's text in blur practice mode are pointer hover (desktop) or a tap that starts a hold reveal (every platform). The active cue is treated like every other cue: blurred unless explicitly peeked.
- **FR-006**: On every platform, the system MUST unblur a tapped cue for a configurable hold window (default: 3 seconds) and then re-blur it. Tapping a cue MUST also perform the existing tap-to-seek behavior (playback seeks to the cue's start). A subsequent tap on the same or a different cue resets the timer and moves the hold to the newly tapped cue.
- **FR-007**: The system MUST persist the toggle on/off state and the hold window duration across app restarts as part of the user's transcript preferences. The setting is per-user, not per-track or per-media.
- **FR-008**: The system MUST NOT hide cue text from screen readers; semantics labels must always expose the full cue text and timestamp regardless of blur state. Lookup (dictionary) and text selection on revealed cues must continue to work.
- **FR-009**: The toggle MUST be reachable by keyboard, expose a tooltip with its on/off state, and announce its semantics label to screen readers. Icon-only affordance MUST follow the project's shared UI primitive conventions.
- **FR-010**: The system MUST apply the blur to both the primary cue body and any rendered secondary (translation) cue body. Timestamps, recording badges, left rails, and other structural chrome MUST NOT be blurred.
- **FR-011**: The system MUST clamp the blur radius so the cue remains visually discoverable (no fully invisible lines), and MUST respect the user's reduced-motion preference for the blur/unblur transition.
- **FR-012**: The system MUST keep tap-to-seek working on every cue regardless of blur state. Tapping a blurred cue on desktop MUST seek playback; on every platform it MUST seek AND trigger the tap-reveal hold from FR-006.
- **FR-013**: The system MUST disable the toggle (with a tooltip) when there are zero transcript lines to practice with, and MUST render no blur styling in the empty state, loading skeleton, or error state.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture under `lib/features/transcript/` and avoid shortcuts from other features. Reuse existing hover/active/tap plumbing where possible; do not duplicate cue rendering paths.
- **QR-002**: Behavior changes MUST have automated tests or a documented manual verification reason. Required coverage at minimum: toggle on/off, hover reveal on desktop, the rule that the active cue stays blurred, mobile tap-seek-plus-reveal with expiry, persistence, and reduced-motion behavior.
- **QR-003**: The blur effect, toggle button, and any settings entry MUST follow existing localization (`AppLocalizations`) and shared UI primitive patterns (`EnjoyTappableSurface` / `EnjoyButton` / `EnjoyTappableIcon` where they fit). Tooltips, haptics on toggle, and keyboard focus styling MUST match the rest of the transcript panel.
- **QR-004**: Blur rendering and the per-cue hover/active/tap state MUST NOT noticeably degrade transcript scrolling performance. The plan MUST include a performance expectation (e.g. smooth scroll on a 10k-line transcript on the slowest supported target) and evidence or a manual verification path.
- **QR-005**: Feature behavior MUST update `docs/features/transcript.md` (and create or extend an ADR if any of the choices below warrant one — e.g. mobile reveal strategy, blur strength, default hold duration).
- **QR-006**: Any new user preference keys MUST follow the project's Drift / settings convention and MUST NOT bypass the existing preferences repository.

### Key Entities *(include if feature involves data)*

- **TranscriptBlurPreferences**: per-user preference object holding the toggle state (on/off) and the tap-reveal hold duration (seconds, integer, default 3). Persisted through the existing settings/persistence layer.
- **TranscriptCueBlurState** (derived, not persisted): per-rendered-cue ephemeral state combining (a) the global toggle, (b) hover state, and (c) the active tap-reveal hold (cue id + expiry timestamp). Used only by the cue widget to decide whether to apply the blur filter. Playback position is NOT an input — the active cue has no privileged state.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can enable blur practice mode and immediately see every cue body blurred within one frame on Android, iOS, macOS, and Windows with no scroll, layout, or playback regression.
- **SC-002**: On macOS and Windows, hovering a cue reveals that cue within one frame and unhovering re-blurs it within one frame, with no flicker between adjacent cues.
- **SC-003**: On every platform and in every playback state (playing, paused, seeking, stopped), NO cue is ever auto-revealed by blur practice mode — including the currently active playback cue. The only ways to see a cue's text are hover (desktop) or a tap-reveal hold (every platform).
- **SC-004**: On every platform, tapping a blurred cue unblurs it immediately, seeks playback to the cue's start, and re-blurs the cue within the configured hold window (default 3 seconds) unless another tap resets the timer.
- **SC-005**: The toggle state and hold duration persist across a full app restart on every supported platform; users do not need to re-enable the feature each session.
- **SC-006**: Screen readers (TalkBack / VoiceOver) on a blurred cue still announce the full cue text and timestamp; the feature introduces zero new a11y violations.
- **SC-007**: Transcript scrolling with blur practice mode on remains smooth (no dropped frames beyond the existing baseline) on the slowest supported target for the largest expected transcript in the user's library.

## Assumptions

- The "blur" effect is a CSS-style filter (`ImageFilter.blur` in Flutter) applied to the cue body widget only; it is decorative and never affects semantics, lookup, or text selection on revealed lines.
- Hover is treated as a desktop-only concept. On Android and iOS the hover handler is wired but inert; only tap-reveal is user-facing on those platforms.
- The default tap-reveal hold duration is **3 seconds**, configurable in transcript preferences. A future revision may add per-platform defaults (e.g. slightly longer for TV / iPad).
- The feature's purpose is hearing-focused practice; the active playback cue is deliberately treated like every other cue and is never auto-revealed. There is no preference override that changes this.
- The toggle is a panel-level control that does not require a separate settings page entry to be useful, but the hold duration lives in the existing transcript settings area for discoverability.
- The blur strength is a fixed visual constant in v1 (no user-facing strength slider); the value is chosen so text is unreadable but line boundaries and punctuation hints remain visible. Strength tuning is owned by the design / UX pass during planning and may be captured in an ADR.
- The feature does not introduce a new network or sync surface. Cloud sync of the user's listening-progress or quiz outcomes is explicitly out of scope for this spec.
- The "Blur practice" toggle does not affect the on-video subtitle overlay (which is disabled by default today) — only the transcript panel rendering.
- Reduced-motion users get an instant on/off; users without reduced-motion get a short, capped opacity transition only (no animated filter, which is expensive on lower-end Android devices).
