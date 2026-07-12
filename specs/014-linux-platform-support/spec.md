# Feature Specification: Linux Desktop Platform Support

**Feature Branch**: `014-linux-platform-support`

**Created**: 2026-07-12

**Status**: Draft

**Input**: User description: "Let's make this project support linux platform too. Add a CI for linux building, update the landing page, ensure everything works in linux platform."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Linux desktop user can install and run Enjoy Player (Priority: P1)

A Linux user (Ubuntu, Fedora, Debian, Arch, or other mainstream distribution) can download Enjoy Player as an AppImage or a `.deb` / `.rpm` / `.tar.gz` archive from the public landing page, make the file executable when required, and launch the app from their desktop environment or the command line. The app starts, the window opens, the library loads, and the user can play local audio/video files the same way a Windows or macOS user does today.

**Why this priority**: Without a real install path and a successful cold-start on Linux, none of the other Linux work is visible to users. This is the only user-visible proof that Linux is a first-class platform; it is the headline deliverable of the whole change.

**Independent Test**: Can be tested end-to-end by downloading the published Linux artifact for the current `main` revision, installing it on a clean Ubuntu 22.04 LTS VM, launching the app, importing a local media file, and observing that playback, transcript rendering, and the mini/expanded player controls all work without a developer shell.

**Acceptance Scenarios**:

1. **Given** a Linux user opens the public download page on a Linux browser, **When** the page renders, **Then** a Linux download card is visible alongside Windows, macOS, Android, and iOS, and the page highlights the Linux card as the recommended pick (mirroring today's behavior for the matching OS).
2. **Given** the user downloads the Linux artifact and launches it on a supported distribution, **When** the app starts cold, **Then** the main window opens, the local library page is reachable, and no first-frame error dialog appears.
3. **Given** a local audio or video file is imported on Linux, **When** the user starts playback, **Then** audio plays through PulseAudio/PipeWire and video renders inside the player, with transcript tracking and play/pause/speed controls working.
4. **Given** the Linux user closes and reopens the app, **When** the app starts again, **Then** previously imported media, transcript associations, and player position resume correctly — persistence behaves identically to Windows/macOS.
5. **Given** a user previously running on a different OS signs into their Enjoy account on Linux, **When** the client-side sync handshake runs, **Then** the platform is reported as `linux` and the server-side product surfaces that classify by `client_platform` still receive a recognized value (no empty / unsupported bucket).

---

### User Story 2 - CI verifies Linux on every change to native or shared code (Priority: P1)

Every pull request and push to `main` that touches shared code (Dart sources, packages, `pubspec.yaml`, CI scripts, or the new `linux/` desktop folder) is automatically verified by a Linux desktop smoke workflow on a self-hosted Linux runner. The workflow installs the same Flutter toolchain the other workflows use, runs `flutter build linux --debug` and `flutter build linux --release`, and fails the PR if either build does not compile. This keeps Linux from regressing silently as the project evolves.

**Why this priority**: A new platform without CI becomes a hidden platform — the day a shared `Platform.isWindows` check is tightened or a dependency drops Linux support, the build breaks for every user. CI is the contract that proves the rest of the spec is kept.

**Independent Test**: Can be tested by opening a PR that touches only `lib/` and observing that the new `build_linux.yml` workflow runs, succeeds, and reports a green status; conversely, by intentionally adding a Linux-incompatible statement (e.g. a wrong conditional import) and observing that the workflow fails with a build error attributed to the Linux job.

**Acceptance Scenarios**:

1. **Given** a pull request modifies `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `linux/**`, or the Linux CI setup files, **When** the PR is opened, **Then** the Linux desktop build workflow runs automatically and is required to pass before merge.
2. **Given** the workflow runs, **When** the job installs dependencies and runs the Linux build, **Then** it uses the same Flutter SDK pin as the other workflows (`.github/flutter-version`) and the same Linux apt-package set already used by `ensure_linux_tooling.sh`, so dependency drift between workflows is impossible.
3. **Given** the workflow runs, **When** the build completes, **Then** a debug and a release Linux executable are produced; the debug build is uploaded as a workflow artifact so reviewers can reproduce a failure locally.
4. **Given** a pull request only changes documentation, ADRs, or the landing page (no Dart, native, or CI files), **When** the PR is opened, **Then** the Linux build workflow is correctly skipped and the PR does not waste runner minutes.
5. **Given** the maintainer wants to run the Linux build outside of a PR, **When** they trigger the workflow from the Actions tab, **Then** `workflow_dispatch` runs the same job and produces the same artifact.

---

### User Story 3 - Native Linux packaging, signing, and updates follow documented policy (Priority: P2)

The Linux build emits a single, predictable distribution format that users can install without developer tools, and the project documents how that format is produced, where it is published, and how future auto-update / signing / notarization (the Linux equivalent) will work. The current deliverable ships a release artifact that is the same artifact the landing page links to; the documentation describes the publishing path even if automated publishing is not yet wired up.

**Why this priority**: Users can already install and run the app with Story 1 alone, but without a stable packaging and publishing story the platform is fragile: every release requires the maintainer to remember the right output, the right CDN path, and the right manifest entry. Documenting and standardizing this now keeps Story 1 from rotting.

**Independent Test**: Can be tested by reading `docs/packaging.md` and the new ADR to confirm the Linux packaging format, output paths, publishing story, and auto-update story are all described; by following the documented steps to build a release locally; and by confirming the manifest entry shape on the CDN matches the link the landing page emits.

**Acceptance Scenarios**:

1. **Given** the release workflow produces a Linux artifact, **When** the maintainer inspects `build/linux/x64/release/bundle/`, **Then** the artifact is an AppImage (or a clearly documented alternative single-file format) that runs on a clean Ubuntu 22.04 LTS VM without `apt install` of project-specific dependencies.
2. **Given** the artifact is published, **When** a user opens the download page on Linux, **Then** the download link resolves to a real file on the existing download host (`dl.enjoy.bot`) and the version displayed matches the artifact's `pubspec.yaml` version.
3. **Given** a release ships, **When** the manifest (`dl.enjoy.bot/player/latest.json`) is updated, **Then** it includes a `linux` entry with a stable schema (version, url, sha256 where supported) that the landing-page JS can read and display.
4. **Given** the project does not yet ship signed Linux binaries, **When** the user opens the download page, **Then** a note explains that Linux is currently an AppImage / direct download (no store equivalent) and points them to the GitHub Releases page for checksums.
5. **Given** a future change wants to add Linux auto-update, **When** the team reads the new ADR, **Then** the decision clearly states that Linux uses a direct-download update flow (no Sparkle/AppUpdater equivalent yet) and lists the future options (AppImageUpdate, Flatpak, snap) as out of scope for the first release.

---

### User Story 4 - Linux behaves correctly under every platform-conditional in shared code (Priority: P2)

Every shared piece of code that today branches on `Platform.isWindows`, `Platform.isMacOS`, `TargetPlatform.windows`, `TargetPlatform.macOS`, `TargetPlatform.android`, or `TargetPlatform.iOS` is reviewed and adjusted where needed so the Linux branch produces a sensible result instead of falling through to a default that may not be valid. The review covers: window management, the YouTube WebView engine, the native auth provider, the auto-updater, the recording client, the local thumbnail helper, the embedded-subtitle service, the recovery actions, the FFmpeg probe, the ASR audio extractor, the echo segment PCM extractor, and the app theme page transitions. The result is that no flow crashes, no-ops silently, or shows a Windows-specific control on Linux.

**Why this priority**: This is the work that turns "the app launches" into "the app is actually usable." A user who can launch but cannot import, cannot sign in, or sees a YouTube error every time will write the platform off. The fix is small, surface-area-wide, and entirely predictable.

**Independent Test**: Can be tested by exercising the same flows on Linux that the existing widget and integration tests exercise on Windows/macOS — local media import, transcript import, echo practice, recording, settings change, and crash recovery — and asserting no platform-specific exception is raised; complementarily, by reading the platform-conditional code and asserting that the `linux` case is at least as graceful as the `windows`/`macos` case.

**Acceptance Scenarios**:

1. **Given** a Linux user opens a local audio or video file, **When** the file picker and import path run, **Then** the same code path used for Windows/macOS handles the file and a media item appears in the library.
2. **Given** a Linux user enables the YouTube import feature, **When** the user pastes a YouTube URL, **Then** the WebView engine either plays the video (WebViewGTK) or, if the YouTube engine explicitly opts out of Linux, the UI shows a clear "YouTube is not yet available on Linux" message rather than a generic crash.
3. **Given** a Linux user opens the sign-in sheet, **When** the available native providers are listed, **Then** no Apple/Windows-only provider is offered; if Google native sign-in is not configured for Linux, the sheet hides the button or shows a tooltip instead of crashing when the user taps it.
4. **Given** a Linux user views a media item with a transcript, **When** the transcript renders, **Then** subtitle and theme styles match the rest of the app (no fallback to a Windows-specific page transition or a Windows-only recovery button).
5. **Given** a Linux user records themselves in echo mode, **When** the recording uploads, **Then** `client_platform=linux` is sent and the upload endpoint accepts it (no "unsupported platform" rejection).
6. **Given** a Linux user triggers the in-app recovery flow, **When** the recovery actions menu lists options, **Then** every action either runs or is gracefully hidden — none throws an unhandled `UnsupportedError` or `MissingPluginException`.

---

### Edge Cases

- What happens on a Linux distribution that ships a GTK version older than what the build assumes (e.g. GTK 3.16 vs. the newer versions CI installs)? The CI job must use a stable, supported base image (Ubuntu 22.04 LTS or the gh-sr agentic image) and the docs must state the minimum supported GTK version.
- How does the system behave when a Linux user has no PulseAudio/PipeWire available (e.g. minimal server install with only ALSA)? Playback should fail with a clear error message rather than silently dropping audio.
- What happens when the WebViewGTK native libraries are not present on a target Linux machine? The app must detect the missing WebView runtime and either show a one-time setup hint or disable the YouTube engine with a clear message, instead of crashing the first time the user opens a YouTube import.
- What happens when the user runs the AppImage on a Wayland session? The app must still open, prefer Wayland when available, and fall back to XWayland when not, without an `EGL_BAD_DISPLAY` error.
- What happens if the Linux build script is run on a non-Linux host? The script should refuse to start (not produce a broken cross-built artifact) with a clear error.
- How does the app behave when the user denies microphone permission on Linux (PipeWire/PulseAudio privacy settings)? Echo mode recording must surface a localized "microphone permission denied" error, mirroring the iOS/Android behavior.
- What happens when an existing user on Windows/macOS signs in on Linux and their synced data includes Linux-incompatible paths? The sync layer must classify such items as "synced, but not playable on Linux" with a clear UI message — never silently corrupt the data.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST contain a `linux/` Flutter desktop folder generated by `flutter create --platforms=linux .` and committed, with a working `linux/CMakeLists.txt`, `linux/main.cc`, and `linux/my_application.cc` that follow the upstream Flutter Linux template, customized only as required (e.g. application name, icon).
- **FR-002**: The Flutter project MUST build on Linux with the standard toolchain (Flutter SDK, clang, cmake, ninja, GTK 3 headers, libsqlite3) using `flutter build linux --debug` and `flutter build linux --release` without errors or warnings introduced by platform-conditionals.
- **FR-003**: A new GitHub Actions workflow `.github/workflows/build_linux.yml` MUST be added that runs the Linux build on every PR and push to `main` that touches `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `linux/**`, or the Linux CI setup files, and that can also be triggered manually via `workflow_dispatch`.
- **FR-004**: The Linux build workflow MUST reuse `.github/scripts/ensure_linux_tooling.sh` (or an equivalent script) and the existing `setup-flutter` action so the toolchain is identical to the one used by `ci.yml` and the agentic workflows.
- **FR-005**: The Linux build workflow MUST produce a debug build (uploaded as an artifact) and a release build, and MUST fail the PR if either step fails. Release artifacts MAY be uploaded as artifacts as well when produced by `workflow_dispatch`.
- **FR-006**: The project MUST introduce an ADR (placed under `docs/decisions/`) that supersedes the platform-support clause in `.specify/memory/constitution.md` and AGENTS.md, promoting Linux from "may follow / experimental" to a first-class supported desktop platform, and clearly enumerating the consequences for signing, auto-update, store distribution, and landing-page publishing.
- **FR-007**: The constitution `.specify/memory/constitution.md` MUST be amended (version bump with rationale) to add Linux to the supported-target list, and the Flutter Quality Gates section MUST explicitly include Linux in the supported-targets enumeration.
- **FR-008**: `AGENTS.md` MUST be updated so the supported-platforms list reads "Android, iOS, macOS, Windows, Linux" (no parenthetical "may follow") and the Linux build folder reference (`linux/**`) is added to the path lists in any place where the other platform folders are enumerated.
- **FR-009**: `README.md` MUST be updated to reflect Linux as a fully supported platform, replacing the "Linux experimental" wording, and MUST add a Linux setup section that lists the apt packages a developer needs to install on Ubuntu/Fedora to build from source.
- **FR-010**: The public landing page (`landing/index.html`, `landing/i18n.js`, and `landing/main.js`) MUST add a Linux download card that follows the existing platform-card pattern, with localized strings for English and Chinese, a Linux icon, and a download button whose target is set from the existing release manifest (`dl.enjoy.bot/player/latest.json`).
- **FR-011**: The release manifest schema used by the landing page (`dl.enjoy.bot/player/latest.json`) MUST be extended to include a `linux` asset entry (version, url, optional sha256, optional format hint such as `appimage`), and the landing-page JS MUST read it and update the Linux button's `href` and `download` attributes the same way it does for Windows, macOS, and Android.
- **FR-012**: The `recordingClientPlatformValue()` function and any other platform-string sentinels that the backend classifies by `client_platform` MUST already return `linux` for Linux (this is true today and is verified by tests; the spec requires that this property is preserved and tested for every shared platform string).
- **FR-013**: Every shared Dart branch that today handles only Windows/macOS/Android/iOS MUST be reviewed and adjusted so that the Linux case is explicit and graceful. At minimum: `MediaKitPlayerEngine` / `PlayerController` instantiation (already shared), `windowManager` initialization (already shared), the YouTube WebView engine (must opt-in or opt-out explicitly per platform), the native auth providers (must hide the buttons or show a tooltip on Linux), the in-app auto-updater (must be disabled with a clear "Linux uses direct downloads" status on Linux), the embedded-subtitle service (FFmpeg lookup), the recovery actions menu, the local thumbnail helper, the ASR audio extractor, and the echo segment PCM extractor.
- **FR-014**: A new docs page `docs/features/linux-platform.md` (or equivalent) MUST be created and linked from `docs/features/` and the `Features` section of the README, describing what works on Linux, what does not, the install path, the package format, the update model, and the supported distributions.
- **FR-015**: The landing-page `landing/main.js` OS-detection function MUST classify Linux correctly so that `highlightPlatform('linux')` runs when the user is on Linux, and the `urlMap` in `applyManifest()` MUST include a `btn-linux` entry that is updated from the manifest's `linux.url` field.
- **FR-016**: The PULL_REQUEST template's `Platform tested` checklist MUST remain as-is (it already lists Linux), but the new workflow MUST be discoverable in `docs/ci-self-hosted-runners.md` with the same table format used for the other build workflows.
- **FR-017**: The CI badges in `README.md` (if any reference build workflows by name) MUST include the new `build_linux.yml` workflow.
- **FR-018**: The `--platform linux` flag MUST be added to the existing `release.sh` dispatcher in `.github/scripts/release.sh` (and any related release scripts) so that future manual release runs can produce a Linux AppImage from the same dispatcher the other platforms use.
- **FR-019**: The new Linux build workflow MUST be wired into the same self-hosted Linux runner pool the existing CI and Android smoke workflows use (the `baizhiheizi` gh-sr pool), and MUST use the same Flutter SDK pin from `.github/flutter-version` so the toolchain stays in lock-step.
- **FR-020**: Tests MUST be added or updated to cover: (a) `recordingClientPlatformValue()` returns `linux` for `Platform.isLinux`; (b) `resolveDistributionChannel()` still returns `direct` for `TargetPlatform.linux` (already covered, must remain green); (c) the auth provider predicates return graceful (non-throwing) values for `TargetPlatform.linux`; (d) any new shared `isLinux` predicates are covered.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception. The Linux scaffolding lives under the existing `lib/features/` and `lib/core/` layout — no new top-level folders are introduced.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason. The new `linux/` folder, the new workflow, and every platform-conditional adjustment MUST be covered either by an automated test or by a clearly written manual verification step in the new docs page.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns. The new Linux download card and Linux-specific UI strings MUST be added to both `landing/index.html` (via `data-i18n`) and `landing/i18n.js` (under both `en` and `zh`).
- **QR-004**: User-visible flows MUST define measurable performance expectations for playback, startup, scrolling, transcript rendering, sync, import, or other affected paths. The Linux cold-start budget (time-to-window on the documented test VM) MUST be measured and recorded in the new docs page.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/`. The new Linux support MUST add `docs/features/linux-platform.md` and reference it from the README, the constitution (via the amendment), and the new ADR.
- **QR-006**: The new build workflow MUST NOT introduce a parallel `actions/cache` or `actions/upload-artifact` pattern that the existing self-hosted-runner policy forbids; it MUST follow the established "self-hosted, no GitHub cache, store on dl.enjoy.bot when publishing" model.
- **QR-007**: The constitution's quality-gate enforcement (`bash .github/scripts/validate_ci_gates.sh`) MUST remain valid; if the `check_dart_format.sh` or `check_codegen_drift.sh` path lists need a Linux entry (e.g. a `linux/` check), it MUST be added in the same change.

### Key Entities

- **Linux build artifact**: the single distributable file (AppImage, or a clearly documented alternative) produced by `flutter build linux --release` and published to `dl.enjoy.bot/player/`. Attributes: `version` (matches `pubspec.yaml`), `url` (download link), `format` (`appimage` | `tar.gz` | `deb` | `rpm`), optional `sha256`.
- **Release manifest `latest.json`**: the JSON document at `dl.enjoy.bot/player/latest.json` that the landing page reads. Today it has `windows`, `macos`, `android_arm64_v8a`; after this change it gains a `linux` entry with the same shape.
- **Platform predicate `isDesktop`**: the existing helper in `lib/core/window/desktop_window.dart` that already includes Linux. The spec relies on this predicate being correct and on `isMobilePlatform` explicitly excluding Linux (so Linux is classified as a desktop platform everywhere it is checked).
- **Platform string `client_platform`**: the string sent to recording uploads and other backend endpoints. Today already supports `linux`; the spec freezes this as a tested contract.
- **ADR `0042-linux-platform-support`** (placeholder number): the new decision record that supersedes the platform-support clause in the constitution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user on Ubuntu 22.04 LTS can download the Linux artifact from the public download page, make it executable, launch it, import a local media file, and start playback in under 3 minutes from page load to first frame of video.
- **SC-002**: A pull request that changes any of `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `linux/**`, or the Linux CI setup files is automatically verified by a Linux desktop build workflow that runs in under 15 minutes on the self-hosted runner, and the workflow is a merge gate.
- **SC-003**: The Linux app reaches cold-start-to-window on the documented test VM in under 6 seconds (median), and the value is recorded in `docs/features/linux-platform.md`.
- **SC-004**: The landing page, when loaded on a Linux browser, shows the Linux card as the recommended platform with a working download link to a real file on `dl.enjoy.bot`, in both English and Chinese, and the page's classification of the OS matches `navigator.userAgent` 100% of the time on the test matrix.
- **SC-005**: 100% of the platform-conditional sites audited under FR-013 have an explicit Linux branch (or a documented graceful no-op) — no flow that previously assumed Windows/macOS only crashes, throws `UnsupportedError`, or shows a Windows-specific control on Linux.
- **SC-006**: All existing unit and widget tests continue to pass on the Linux self-hosted runner (the existing CI matrix already runs on Linux), and the new tests added under FR-020 are green.
- **SC-007**: The release manifest `dl.enjoy.bot/player/latest.json` exposes a `linux` entry with a real `url` and `version` for at least one release, and the landing page reads and renders it.
- **SC-008**: The constitution, AGENTS.md, and README.md are all updated to reflect Linux as a first-class supported platform, and the change is tracked in a new ADR whose number matches the existing ADR sequence.
- **SC-009**: After release, the Linux app survives a close-and-reopen cycle with library, transcript associations, and player position all preserved identically to Windows/macOS (i.e. the same Drift database, same `path_provider` paths, same `flutter_secure_storage` backend, with no platform-specific regression).

## Assumptions

- Linux is promoted from "experimental / may follow" to a **first-class supported desktop platform**, equal in status to Windows and macOS for distribution, build, and CI purposes. This requires amending the constitution's platform-support clause; the amendment is part of this change and is recorded in a new ADR.
- The first Linux distribution format is **AppImage** (single-file, runs on Ubuntu 22.04 LTS / Fedora 39 / Debian 12 without `apt install` of project-specific dependencies). `.deb` / `.rpm` / Flatpak / snap are out of scope for v1 and may be added in a follow-up ADR.
- The first Linux release uses the **direct-download update model** (no auto-updater inside the app). The user downloads a new AppImage manually from the landing page, the same way Windows/macOS users download a new installer today. Sparkle-equivalent auto-update for Linux is out of scope.
- The Linux build is verified on a **self-hosted Linux runner** (the same `baizhiheizi` gh-sr pool used by CI and Android smoke). The runner already has the Linux apt packages needed for `flutter build linux` baked into its container image (see `container_runner_image.extra_apt_packages` in `runners.yml` and the existing `ensure_linux_tooling.sh`).
- The minimum supported Linux desktop is **Ubuntu 22.04 LTS** (or an equivalent: glibc 2.35, GTK 3, PulseAudio or PipeWire, x86_64). Other architectures (aarch64) are out of scope for v1; if added later they require a separate ADR.
- The YouTube WebView engine MAY be available on Linux via WebViewGTK (the underlying `flutter_inappwebview` Linux implementation). If the engine is judged too unstable or its native dependencies are too heavy for v1, the engine must opt out cleanly on Linux (no crash) and the landing page / docs must state that YouTube is "coming soon on Linux" rather than imply it works. The decision between "supported on Linux" and "graceful opt-out" is captured in the new ADR.
- Native Apple Sign-In is **not** available on Linux (it is not on Windows either, so the existing `nativeAppleSignInSupported` predicate already returns `false` outside iOS/macOS). Native Google Sign-In MAY be available on Linux (it depends on `google_sign_in`'s Linux support and the OAuth client configuration); the new ADR will record which providers are available on Linux.
- `auto_updater` does not run on Linux for v1 — the auto-updater is already gated to Windows/macOS direct builds, and the existing predicate already excludes Linux. The spec freezes this as a tested contract.
- `flutter_secure_storage` on Linux uses `libsecret` / GNOME Keyring (or KWallet); if no keyring is installed the secure storage degrades gracefully (existing behavior) and the spec does not require a different backend.
- FFmpeg on Linux is provided by the system (`ffmpeg` package) or by an AppImage-bundled binary; the spec does not require a separate FFmpeg fetch script like the Windows build does.
- Linux is in-scope for recording uploads (`client_platform=linux`), subscription backend classification, and analytics, because the backend already classifies `linux` as a valid value.
