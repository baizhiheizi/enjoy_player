# Feature Specification: Phone / Tablet Orientation & Player Layout Polish

**Feature Branch**: `026-orientation-layout-polish`

**Created**: 2026-07-20

**Status**: Draft

**Input**: User description: "Let's polish the auto rotate of the app. in phone screen, we should not auto rotate. in tablet, like pad, the auto rotate is reasonable. But in player screen, the layout of video and transcript should depend on the device of horizontal of veritall, not depend on the screen witdth."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Phones stay upright; tablets may rotate (Priority: P1)

A learner using Enjoy Player on a **phone** keeps the app in a stable upright orientation while they browse the library, discover content, open settings, or practice. Tilting or flipping the phone does **not** re-layout the whole app into landscape. On a **tablet** (pad-class device), rotating the device *does* change the app orientation in the normal system way, so landscape and portrait both remain useful for reading and browsing.

**Why this priority**: Accidental phone rotation is a common distraction during language practice and navigation. Tablets are large enough that landscape browsing is expected. Getting the device-class policy right is the foundation for every other orientation-related behavior.

**Independent Test**: On a phone-class device with system auto-rotate enabled, open any non-player screen, rotate the device, and confirm the app UI stays in the locked upright orientation. On a tablet-class device with system auto-rotate enabled, rotate and confirm the app follows the new orientation.

**Acceptance Scenarios**:

1. **Given** the app is running on a phone-class device and the OS allows rotation, **When** the user rotates the device while on a browsing or settings screen, **Then** the app remains in the upright (portrait) orientation and does not switch to landscape.
2. **Given** the app is running on a tablet-class device and the OS allows rotation, **When** the user rotates the device on a browsing or settings screen, **Then** the app follows the device orientation (portrait and landscape both usable).
3. **Given** the OS itself has auto-rotate disabled, **When** the user tilts a tablet, **Then** the app respects the OS lock and does not force a rotation the system forbids.
4. **Given** a desktop (windowed) environment, **When** the user resizes or moves the window, **Then** orientation-lock rules for phones/tablets do not apply; the window remains freely resizable as today.

---

### User Story 2 - Player video + transcript follow orientation, not a width breakpoint (Priority: P1)

In the **player** screen, whether video and transcript appear **stacked** (video above transcript) or **side-by-side** depends on whether the device/window is in a **portrait** or **landscape** orientation — not on whether the available width crosses a fixed pixel threshold. Landscape uses the side-by-side learning layout; portrait uses the stacked layout. A wide tablet held in portrait therefore stacks (even if it is wider than today’s side-by-side width cutoff), and a landscape orientation uses side-by-side even when the window is only moderately wide.

**Why this priority**: Today’s width-based rule makes portrait tablets look like “desktop” side-by-side layouts and can mismatch how learners hold the device. Orientation matches physical posture and reading intent.

**Independent Test**: Open a video with a transcript on a tablet (or a resizable window). Force or rotate into portrait and confirm stacked layout; switch to landscape and confirm side-by-side — regardless of whether width is above or below the previous side-by-side width threshold.

**Acceptance Scenarios**:

1. **Given** the player is open with video and transcript in a **landscape** orientation, **When** the layout settles, **Then** video and transcript appear **side-by-side**.
2. **Given** the player is open with video and transcript in a **portrait** orientation, **When** the layout settles, **Then** video and transcript appear **stacked** (video above transcript), even if the available width would previously have triggered side-by-side.
3. **Given** a tablet in portrait showing the stacked player layout, **When** the user rotates to landscape, **Then** the layout switches to side-by-side without losing the current media position or transcript focus.
4. **Given** a tablet in landscape showing side-by-side, **When** the user rotates to portrait, **Then** the layout switches to stacked without losing the current media position or transcript focus.
5. **Given** a phone-class device (orientation locked upright per User Story 1), **When** the player is open, **Then** the player uses the **stacked** portrait layout consistently.
6. **Given** a desktop window that is wider than it is tall, **When** the player is open, **Then** video and transcript use the **side-by-side** layout; when the window is taller than it is wide, they use the **stacked** layout.

---

### User Story 3 - Orientation changes stay calm and usable (Priority: P2)

When rotation is allowed (tablets and freely resized desktop windows), switching between portrait and landscape during playback keeps transport controls, transcript scrolling, and practice affordances usable. The transition does not blank the media, jump progress unexpectedly, or leave the transcript panel in an unusable size.

**Why this priority**: Orientation polish fails if rotation “works” but breaks the practice loop. Stability during the transition is secondary to the policy itself but still required for ship quality.

**Independent Test**: On a tablet, start playback with a transcript, rotate several times between portrait and landscape, and confirm media keeps playing (or resumes cleanly), progress stays coherent, and both layouts remain operable.

**Acceptance Scenarios**:

1. **Given** media is playing on a tablet, **When** the user rotates between portrait and landscape, **Then** playback position remains continuous (no unexpected reset to the start) and the active transcript cue remains findable.
2. **Given** the side-by-side layout is showing with a user-adjusted transcript split width, **When** the user rotates away and back to landscape, **Then** a sensible transcript column width is restored (persisted preference when still valid, otherwise a safe default within existing min/max bounds).
3. **Given** the player chrome (controls, title, practice tools) is visible before rotation, **When** orientation changes, **Then** those controls remain reachable in the new layout without requiring the user to leave the player.

---

### Edge Cases

- **Foldables / dual-posture devices**: Classify using the same phone-vs-tablet form-factor rules as the rest of the app; if the device presents as phone-class, keep upright lock; if tablet-class, allow rotation. Player layout still follows current portrait vs landscape of the app window.
- **Split-screen / multi-window on tablets**: Player layout follows the app window’s portrait vs landscape (height vs width), not the physical hinge alone.
- **Audio-only or transcript-less media**: Orientation lock policy still applies; when there is no video+transcript pair, do not invent a new split — keep the existing single-pane player presentation for that media type.
- **YouTube vs local video**: Same orientation and stack/side-by-side rules for both player engines.
- **System rotation lock**: Never override an OS-level rotation lock to force landscape or portrait against the user’s system setting.
- **Very short landscape windows on desktop**: Side-by-side must remain usable (transcript column still within existing minimum usability bounds); if space is pathological, prefer keeping both panes reachable over clipping critical controls.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On phone-class devices, the app MUST keep a fixed upright (portrait) orientation and MUST NOT auto-rotate into landscape when the user tilts the device.
- **FR-002**: On tablet-class devices, the app MUST allow normal auto-rotation between portrait and landscape when the OS permits it.
- **FR-003**: Desktop / windowed environments MUST remain freely resizable; phone/tablet orientation locks MUST NOT constrain desktop windows.
- **FR-004**: In the player screen, the choice between stacked video+transcript and side-by-side video+transcript MUST be driven by whether the current app window is in **portrait** or **landscape** orientation (taller-than-wide vs wider-than-tall), not by a fixed width breakpoint.
- **FR-005**: Landscape player orientation MUST present video and transcript **side-by-side**.
- **FR-006**: Portrait player orientation MUST present video and transcript **stacked** (video above transcript).
- **FR-007**: Rotating a tablet (or reshaping a desktop window) between portrait and landscape while in the player MUST update the layout per FR-005/FR-006 without clearing the current media session or discarding the user’s place in the transcript.
- **FR-008**: Phone-class devices in the player MUST consistently show the stacked portrait layout (as a consequence of FR-001 and FR-006).
- **FR-009**: Existing player capabilities that are independent of orientation (playback, transcript interaction, echo/blur/practice tools, split-width preference when side-by-side) MUST remain available in both layouts, subject to each layout’s space.
- **FR-010**: Classification of phone vs tablet for orientation policy MUST use a stable, documented form-factor rule consistent with common mobile conventions (see Assumptions), and MUST apply app-wide — not only inside the player.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason (device-class orientation policy and player portrait/landscape layout selection are both in scope for coverage).
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns. This feature SHOULD NOT introduce new user-facing settings copy unless a later clarification adds an override preference.
- **QR-004**: Orientation transitions on tablet/desktop MUST complete without sustained jank: layout should settle within one interactive frame budget after the orientation metrics update, and playback chrome must remain operable without a full player restart.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/` (at least player layout and any app-wide UI orientation notes).

### Key Entities

- **Device form factor**: Logical class of the running device for orientation policy — **phone** (rotation locked upright) vs **tablet** (rotation allowed) vs **desktop** (no mobile orientation lock).
- **App window orientation**: Whether the current app window is **portrait** (height ≥ width) or **landscape** (width > height); this is the sole driver of player stack vs side-by-side.
- **Player content layout**: The arrangement of the video stage and transcript panel — **stacked** or **side-by-side**.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On phone-class devices with OS auto-rotate enabled, 100% of sampled non-player and player sessions remain in upright orientation when the device is tilted to landscape (no unintended landscape app chrome).
- **SC-002**: On tablet-class devices with OS auto-rotate enabled, rotating to landscape and back succeeds in both directions on browsing screens and in the player within one continuous session.
- **SC-003**: In the player, landscape orientation yields side-by-side video+transcript and portrait orientation yields stacked video+transcript in 100% of verification cases, including tablets whose portrait width exceeds the former side-by-side width threshold.
- **SC-004**: After an allowed orientation change during playback, media position remains within 1 second of the pre-rotation position and the previously active transcript cue remains visible or one tap away.
- **SC-005**: Manual verification on at least one phone-class and one tablet-class device (or faithful simulator/emulator equivalents) plus one desktop window reshape passes without layout overflow that blocks playback or transcript reading.
- **SC-006**: Orientation/layout transitions do not require the user to leave and re-enter the player to recover a usable layout.

## Assumptions

- **Phone vs tablet cutoff**: A device is treated as tablet-class when its smallest screen side meets a common pad threshold (approximately 600 logical pixels shortest side); otherwise it is phone-class. Desktop platforms are never subject to the phone upright lock.
- **Upright means portrait**: “Do not auto-rotate” on phones means locking to portrait orientations only (not landscape-left/right), matching typical reading apps.
- **No new user setting in v1**: Learners do not get a Settings toggle to override phone lock or tablet rotate; OS rotation lock remains the user escape hatch on tablets.
- **Replaces width-breakpoint layout rule for player split**: The previous “width above ~720 → side-by-side” rule for video+transcript arrangement is superseded by orientation for that decision. Other width-based UI (transport control packing, rails, page gutters) may continue to use width where appropriate.
- **Equal aspect (square) windows**: If width equals height, treat as portrait (stacked) for a stable default.
- **Scope**: Applies to Android and iOS phone/tablet form factors; desktop (Windows, macOS, Linux) keeps free window sizing with orientation-based player layout only. No Flutter web.
- **Audio-only sessions**: Orientation policy still applies; stack/side-by-side rules apply only when the player presents both a video stage and a transcript panel.
