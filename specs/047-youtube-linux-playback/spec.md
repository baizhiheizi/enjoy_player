# Feature Specification: YouTube Playback on Linux

**Feature Branch**: `047-youtube-linux-playback`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Let's go A" — adopt Route A from the 2026-10-02 Linux YouTube research: bring YouTube playback to Linux through the same embedded-browser playback engine the other desktop platforms use (upgraded to the release line that ships a Linux backend), bundle the browser runtime into the self-contained Linux artifact, and lift the current Linux opt-out.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A Linux user can watch a YouTube video inside Enjoy Player (Priority: P1)

A Linux user pastes a YouTube URL, taps a video from the Discover feed, or opens a previously saved YouTube item from the library. The video renders inside the player, starts playing, and the standard transport controls (play/pause, seek, playback speed, volume) work exactly as they do on Windows and macOS today. If the user has a transcript open for that video, the transcript highlights and tracks along with the audio.

**Why this priority**: This is the feature. Every other story polishes or protects it; without this slice, YouTube on Linux remains a dead end for users. It is also the slice that the research spike must prove before rollout.

**Independent Test**: Can be fully tested by launching the Linux app, pasting a known public YouTube URL, and observing video playback with working transport controls and transcript tracking — no other story needs to exist for this to deliver value.

**Acceptance Scenarios**:

1. **Given** a Linux user on a supported distribution with network access, **When** they paste a public YouTube URL and open it, **Then** the video plays inside the app player with both audio and video rendering.
2. **Given** playback has started, **When** the user taps play/pause, drags the seek bar, changes playback speed, or adjusts volume, **Then** each action takes effect within the same responsiveness the user gets on Windows/macOS.
3. **Given** a transcript exists for the video, **When** playback proceeds, **Then** the active transcript line highlights and auto-scrolls in sync with the audio, indistinguishable from the same video on Windows/macOS.
4. **Given** the user opens a YouTube item from the Discover feed or library on Linux, **When** playback starts, **Then** metadata (title, channel, poster image) displays as on other desktop platforms.
5. **Given** the user closes the player and reopens the same video, **When** playback resumes, **Then** the remembered position is restored as on other desktop platforms.

---

### User Story 2 - YouTube unavailability on Linux degrades gracefully, never crashes (Priority: P1)

On any Linux system where the YouTube playback engine cannot initialize (missing or broken browser runtime, engine startup failure), every YouTube entry point — URL open, Discover tile, library item, background warm-up, sign-in screen — shows a clear, localized "YouTube is not available on this device" state with an action to open the video in the system browser. Nothing crashes, nothing hangs, and the rest of the app is unaffected.

**Why this priority**: The current Linux build opts YouTube out at build time precisely because the runtime could not be guaranteed. Turning the opt-out into a runtime capability decision means the failure mode users hit must be as polished as the success mode; a crash on a minority of systems would cost more trust than not shipping the feature.

**Independent Test**: Can be tested on a Linux environment where the browser runtime is deliberately absent or broken: every YouTube entry point shows the localized unavailable message with the browser fallback action, and no unhandled exception reaches the user.

**Acceptance Scenarios**:

1. **Given** a Linux system where the playback engine for YouTube cannot initialize, **When** the user opens a YouTube URL, **Then** a localized unavailable message appears with an "open in browser" action, and the app returns to a working state afterwards.
2. **Given** the same system, **When** a Discover feed tile or library item for a YouTube video is tapped, **Then** the same unavailable state is shown instead of a spinner that never resolves.
3. **Given** the same system, **When** the app pre-warms the YouTube player surface at startup or on hover, **Then** the warm-up no-ops silently without errors surfacing to the user.
4. **Given** a healthy Linux system, **When** any YouTube flow runs, **Then** availability was determined by an actual runtime capability check, not by a hard-coded platform exclusion — i.e., a system that can support playback is never told it cannot.

---

### User Story 3 - YouTube surfaces on Linux reach parity with other desktop platforms (Priority: P2)

Everything in the app that involves YouTube behaves on Linux the way it does on Windows/macOS: the Discover feed opens YouTube videos, language-aware caption selection works, bilingual transcripts render, the player's YouTube-specific chrome (poster capture, subtitle disabling behavior) matches, and in-player navigation away to Google sign-in continues to be cancelled so anonymous playback keeps working.

**Why this priority**: A half-parity experience (plays but no transcripts, or tiles that open to errors) would read as broken rather than new. Parity is what makes the feature feel finished — but it only matters once Story 1 works, so it ranks below it.

**Independent Test**: Can be tested by walking the full YouTube journey on Linux — Discover → open → captions → bilingual transcript → seek around → second video — and comparing each step side-by-side with the same journey on Windows.

**Acceptance Scenarios**:

1. **Given** a YouTube video with captions on Linux, **When** the user opens the transcript panel, **Then** captions are fetched and rendered with the same language-aware selection as on Windows/macOS.
2. **Given** the Discover feed shows a YouTube tile, **When** the user taps it on Linux, **Then** the video opens in the player without an intermediate unavailable state.
3. **Given** playback is running, **When** the embedded page attempts to navigate to Google sign-in, **Then** the navigation is cancelled and playback continues anonymously, matching the cross-platform policy.
4. **Given** the user opens the YouTube sign-in screen on Linux, **When** sign-in via the embedded browser is unavailable, **Then** the screen is hidden or explains its unavailability clearly — it never opens to a blank or broken page.
5. **Given** the user switches rapidly between a local file and a YouTube video (in both directions, repeatedly), **When** the player swaps engines, **Then** no playback surface leaks, no ghost audio continues, and the second open succeeds.

---

### User Story 4 - The Linux release stays self-contained (Priority: P2)

The Linux artifact the landing page distributes remains a single file that runs on a clean, supported distribution without installing system packages. The browser runtime needed for YouTube playback ships inside the artifact. The download size increase and any cold-start cost are measured, bounded, and recorded in the packaging documentation before rollout.

**Why this priority**: Users chose the AppImage because "download and run" works. If YouTube silently turns the app into something that needs `apt install`, the platform regresses for everyone — including users who never touch YouTube. But this is a constraint on how Story 1 ships, not value by itself.

**Independent Test**: Can be tested by taking the release artifact to a clean VM image of each supported baseline (Ubuntu 22.04 LTS, Debian 12, Fedora 40, current Arch), launching it without installing anything, and verifying both local playback and YouTube playback work; artifact size and cold-start time are compared against the previous release's recorded numbers.

**Acceptance Scenarios**:

1. **Given** a clean Ubuntu 22.04 LTS VM with no developer packages installed, **When** the new AppImage is launched, **Then** local media playback and YouTube playback both work with no `apt install` step.
2. **Given** the new artifact, **When** its download size is compared with the previous release, **Then** the increase is within the documented budget (assumption: no more than +150 MB) or the excess is explicitly justified in the packaging docs.
3. **Given** the new artifact on the documented test VM, **When** cold-start time is measured, **Then** it regresses by no more than 2 seconds versus the previous release's recorded median.
4. **Given** the packaging documentation, **When** a maintainer reads it, **Then** it explains what browser runtime is bundled, why, its license implications, and how it is updated across releases.

---

### User Story 5 - Shipping Linux YouTube does not regress the other four platforms (Priority: P2)

The shared playback code and shared browser-engine dependency that this feature upgrades are used by Android, iOS, macOS, and Windows. Every one of those platforms keeps YouTube playback working exactly as before, verified by CI and a per-platform smoke checklist before the change merges.

**Why this priority**: The route chosen explicitly trades a shared-dependency upgrade for Linux support. An unnoticed regression on four healthy platforms to add one platform is a bad trade — this story is the insurance that the trade stays good. It ranks P2 because it gates merge rather than shipping user value by itself.

**Independent Test**: Can be tested by running the full CI matrix plus a documented manual smoke (open a known YouTube video, exercise transport controls, confirm caption fetch) on Android, iOS, macOS, and Windows builds from the feature branch, and confirming zero behavioral differences.

**Acceptance Scenarios**:

1. **Given** the feature branch, **When** CI runs, **Then** the Android, iOS, macOS, and Windows build/test workflows are all green.
2. **Given** the feature branch installed on each of the four platforms, **When** the documented YouTube smoke checklist is executed, **Then** every step passes with behavior identical to the previous release.
3. **Given** a regression is found on any platform, **When** the change cannot be fixed without blocking Linux, **Then** the release proceeds only after an explicit decision records which platform accepts which risk (no silent trades).

---

### Edge Cases

- What happens on a Linux system where the browser runtime initializes but YouTube's page fails inside it (codec support missing, GPU/driver issues under Wayland or X11)? The user gets the app's standard playback error state with a retry action — never a frozen player or a silent black screen.
- What happens with DRM-protected YouTube content (rented/purchased titles)? The player shows the same "cannot play this video" handling as other platforms rather than an endless spinner; regular (non-DRM) videos are unaffected.
- What happens with live streams and premieres? Behavior matches the other desktop platforms — if they are unsupported there, Linux shows the same unsupported handling; if supported, they play.
- What happens when YouTube changes its page and the in-page control bridge breaks? The failure surfaces through the existing unavailable/error UX with diagnostics logging attached (session banner correlation), and users can still fall back to the browser — the app does not hang.
- What happens when the machine is offline or the network drops mid-playback? Standard connectivity error handling applies, identical to other platforms, with recovery when the network returns.
- What happens when the user pastes a malformed or non-video YouTube URL? The same invalid-URL handling as other desktop platforms.
- What happens on the boundary of the supported baseline (older glibc, missing GPU drivers)? The app must still start and local playback must work; YouTube shows the graceful unavailable state of Story 2 rather than crashing the whole app.
- What happens when two YouTube opens race (double-tap a tile, rapid paste-then-open)? The existing open-coordination logic resolves it without duplicate surfaces; the last requested video wins, as on Windows/macOS.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On Linux, the system MUST play YouTube videos opened via URL paste, Discover feed tiles, and library items, with working play/pause, seek, playback speed, and volume controls.
- **FR-002**: On Linux, the YouTube player MUST report position, duration, playing, buffering, and completion states with the same behavior contract the other desktop platforms expose, so transcript tracking, resume, and queue flows work unchanged.
- **FR-003**: YouTube transcripts and captions (including language-aware selection) MUST continue to work on Linux exactly as they do on other platforms; the existing fetch pipeline is reused and its behavior is frozen as a tested contract.
- **FR-004**: YouTube availability on Linux MUST be determined at runtime by an actual capability check (engine present and initializable), replacing the current build-time platform exclusion; every YouTube entry point (open, warm-up, engine swap, player surface, sign-in screen) MUST consult this single decision point.
- **FR-005**: When YouTube is unavailable on a Linux system, the system MUST show a localized unavailable message with an "open in browser" action at every YouTube entry point, MUST NOT crash or hang, and MUST keep the rest of the app fully functional.
- **FR-006**: In-player navigation to Google sign-in MUST be cancelled on Linux, matching the cross-platform anonymous-playback policy.
- **FR-007**: The YouTube sign-in screen on Linux MUST either work through the embedded browser or be hidden with a clear explanation; it MUST NOT open into a broken page. (Default assumption: deferred, see Assumptions.)
- **FR-008**: The Linux release artifact MUST remain fully self-contained: YouTube playback works on a clean supported distribution with zero system package installation, with the required browser runtime bundled inside the artifact.
- **FR-009**: Before general rollout, the feature MUST pass a documented manual verification on a clean Linux VM covering: cold open of a YouTube video, playback of standard video, transport controls, navigation cancellation, unavailable-state simulation, and AppImage launch without system dependencies — with results recorded as release evidence.
- **FR-010**: The shared playback dependency upgrade MUST NOT regress YouTube playback on Android, iOS, macOS, or Windows; CI matrix green plus a documented per-platform smoke checklist is the merge gate.
- **FR-011**: The project MUST record the decision (route chosen, alternatives rejected, runtime-availability policy, bundling and update implications) in a new ADR that supersedes the Linux YouTube opt-out clause in ADR-0048, and MUST update `docs/features/linux-platform.md` and `docs/features/youtube.md` in the same change.
- **FR-012**: New user-facing strings (unavailable message, fallback action, sign-in deferral notice) MUST be added to the localization files for all supported locales.
- **FR-013**: Any capability-check failure or in-page bridge failure MUST be logged through the standard diagnostic logging facility (never console output) so field reports can be triaged via the session banner.

### Key Entities

- **YouTube availability decision**: the single runtime answer to "can this device play YouTube right now?" — attributes: available (yes/no), reason (engine absent / engine failed to initialize / fully available); consulted by every YouTube entry point; replaces the current compile-time platform exclusion.
- **Linux release artifact**: the self-contained single-file distribution; new attributes: bundled browser runtime (identity + version), updated size budget, unchanged "runs without system packages" guarantee.
- **Per-platform smoke checklist**: the documented, repeatable verification list for YouTube on Android/iOS/macOS/Windows used as the regression gate for shared-playability changes.
- **Playback evidence record**: the documented manual verification results from FR-009 (clean-VM scenarios, artifact sizes, cold-start timings), stored with the release/docs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a clean supported Linux VM, a user goes from app launch to watching a YouTube video in under 60 seconds (paste URL → first frame), with zero system configuration beyond installing nothing (artifact runs as-is).
- **SC-002**: On broadband, time from "open YouTube video" to first frame is under 5 seconds (median of 5 runs), matching Windows/macOS on equivalent hardware within ±2 seconds.
- **SC-003**: Transport actions (play/pause, seek, speed change) take visible effect within 300 ms; transcript highlight stays in sync with audio through a 10-minute video with no visible drift compared side-by-side with Windows/macOS.
- **SC-004**: A 24-hour mixed local+YouTube usage session on Linux completes with no crashes, no leaked playback surfaces (audio never continues after close), and no unbounded memory growth (flat memory over the final hour).
- **SC-005**: Artifact download size increases by no more than 150 MB over the previous release (or an explicit documented justification), and cold-start-to-window regresses by no more than 2 seconds on the documented test VM.
- **SC-006**: 100% of YouTube entry points show the graceful unavailable state (never a crash, never an infinite spinner) in the simulated-unavailable environment, verified scenario-by-scenario.
- **SC-007**: The Android, iOS, macOS, and Windows CI workflows and per-platform smoke checklists all pass with zero YouTube behavior changes — measured as zero failed checklist items across the four platforms.
- **SC-008**: The ADR, both feature docs, and localization files land in the same change set as the behavior; a reviewer can trace the route decision, the runtime-availability policy, and the rollback posture (flip the availability decision back to off) from the docs alone.

## Assumptions

- **Route**: The embedded-browser playback engine approach (Route A from the 2026-10-02 research) is chosen; the direct-stream-extraction route (Route B, bundling external download/resolve tooling into the player) is the documented fallback if the feasibility spike fails its criteria. The spike pass criteria from the research — page loads and plays, the in-page control bridge works on the Linux backend (script evaluation, event callbacks, navigation interception), bundling succeeds within budget, resource use acceptable, other platforms unaffected — are exactly FR-009, FR-008, FR-010 and SC-005 of this spec.
- **Minimum platform**: The Linux support baseline stays as defined by spec 014 (x86_64, glibc 2.35 / Ubuntu 22.04 LTS equivalent, Wayland or X11). Bundling the browser runtime means no new system-level library requirement is introduced for users; the distro floor is unchanged.
- **Bundling budget**: +150 MB download size and ≤ 2 s cold-start regression are accepted defaults for bundling the browser runtime; they may be tuned during planning but must be recorded before rollout (FR-008, SC-005).
- **YouTube sign-in on Linux is deferred** (FR-007 default): in-player anonymous playback remains the supported path, consistent with the existing policy of cancelling sign-in navigation inside the player; enabling the sign-in screen on Linux is a follow-up, not part of this feature.
- **Live streams, premieres, DRM titles**: parity with other desktop platforms is the requirement — no Linux-specific support beyond whatever they do today.
- **Content ToS posture**: rendering YouTube's own playback surface in an embedded browser is the same posture the app already has on the other four platforms; the Linux addition does not change what content is accessed or how, and this is recorded in the ADR (FR-011).
- **Rollout**: once the verification evidence of FR-009 exists, the feature ships enabled for all Linux users — no experimental flag — because the runtime availability decision (FR-004) already provides the per-device safety switch and the rollback posture is documented (SC-008).
