---

description: "Task list for Linux Desktop Platform Support"

---

# Tasks: Linux Desktop Platform Support

**Input**: Design documents from `/specs/014-linux-platform-support/`
**Spec**: `specs/014-linux-platform-support/spec.md` (4 user stories, FR-001..FR-020, SC-001..SC-009)
**Plan**: `specs/014-linux-platform-support/plan.md` (Constitution Check PASS on all five principles; platform-conditional audit table in plan.md)
**Research**: `specs/014-linux-platform-support/research.md` (R1..R15 resolved)
**Data model**: `specs/014-linux-platform-support/data-model.md` (no Drift schema changes; new `LinuxPlatformAvailability` module + extended `ReleaseManifestEntry` + extended `LandingPageCard`)
**Contracts**: `specs/014-linux-platform-support/contracts/release-manifest-linux.md` (manifest schema for the `linux` entry)
**Quickstart**: `specs/014-linux-platform-support/quickstart.md` (9 end-to-end validation scenarios)

**Tests**: This change has both automated and documented manual verification. Automated tests cover the new `LinuxPlatformAvailability` predicates (FR-020), the `auth_platform_support.dart` Linux cases, the `recordingClientPlatformValue()` Linux branch, and the unchanged `distribution_channel` Linux cases. Manual verification covers cold-start on a clean Ubuntu 22.04 LTS VM (no CI runner has a desktop GUI session for smoke) and AppImage production (one-time, by the release engineer).

**Organization**: Tasks are grouped by user story. Foundational work (constitution amendment, ADR, new platform-predicate module) is in Phase 2 and is the only work that is blocked behind Setup. The four user stories are independent of each other (US2 only depends on US1 having the `linux/` folder; US3 and US4 only depend on the foundational `LinuxPlatformAvailability` module).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (e.g., [US1], [US2], [US3], [US4])
- Include exact file paths in descriptions

## Path Conventions

- **Linux Flutter desktop scaffold**: `linux/`
- **Linux release scripts**: `.github/scripts/release_linux.sh`, `linux/packaging/make_appimage.sh`
- **CI workflow**: `.github/workflows/build_linux.yml`
- **Shared code**: `lib/core/`, `lib/data/`, `lib/features/`
- **Tests**: `test/core/`, `test/data/`, `test/features/`
- **Feature docs**: `docs/features/linux-platform.md`
- **ADR**: `docs/decisions/0048-linux-platform-support.md` (originally filed as `0044-linux-platform-support.md`)
- **Constitution**: `.specify/memory/constitution.md`
- **Agent / README**: `AGENTS.md`, `README.md`
- **Landing page**: `landing/index.html`, `landing/i18n.js`, `landing/main.js`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization for the Linux desktop target. No new Dart code yet — just the `linux/` Flutter desktop scaffold and the apt-package list audit.

- [x] T001 [P] Run `flutter create --platforms=linux --org ai.enjoy.player --project-name enjoy_player .` to generate the `linux/` Flutter desktop scaffold; commit the generated `linux/CMakeLists.txt`, `linux/main.cc`, `linux/my_application.{cc,h}`, `linux/flutter/`, and the standard `.gitignore` additions
- [x] T002 [P] Audit `.github/scripts/ensure_linux_tooling.sh` and confirm the package list (clang cmake curl git jq ninja-build pkg-config unzip xz-utils zip libgtk-3-dev liblzma-dev libsqlite3-dev) is sufficient for `flutter build linux` on Ubuntu 22.04 LTS; no new packages are required
- [x] T003 [P] Verify `flutter pub get` resolves `flutter_inappwebview_linux` and `flutter_secure_storage_linux` transitively for the new Linux target by running `flutter pub deps --no-dev | grep -E 'linux'` and committing any newly-resolved entries in `pubspec.lock`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Constitutional amendment, ADR, and the new platform-predicate module that every user story depends on. **No user story work can begin until this phase is complete.**

- [x] T004 Create the new ADR at `docs/decisions/0048-linux-platform-support.md` (originally filed as `0044-linux-platform-support.md`) documenting the decision to promote Linux from "experimental / may follow" to a first-class supported desktop platform, the v1 distribution format (AppImage), the YouTube opt-out decision (R6), the direct-download update model (R7), the constitutional version bump 1.1.0 → 1.2.0, and the consequences for signing, store distribution, and landing-page publishing
- [x] T005 Amend `.specify/memory/constitution.md`: bump the Sync Impact Report from `1.0.0 -> 1.1.0` to `1.0.0 -> 1.2.0`, update the `**Version**` line to `1.2.0`, update the `Last Amended` date, and change the "Supported targets" sentence in the Flutter Quality Gates section from "Android, iOS, macOS, and Windows" to "Android, iOS, macOS, Windows, and Linux"
- [x] T006 Update `AGENTS.md`: change the "Supported platforms" line from "Android, iOS, macOS, Windows (Linux may follow)" to "Android, iOS, macOS, Windows, Linux" (no parenthetical), and add `linux/**` to the platform-folder enumerations where `windows/**`, `macos/**`, `ios/**`, `android/**` are listed
- [x] T007 [P] Update `README.md`: replace "Linux experimental" with full support, add a Linux setup subsection that lists the apt packages from `.github/scripts/ensure_linux_tooling.sh` plus `ffmpeg`, and add a row for the new `build_linux.yml` workflow badge
- [x] T008 [P] Create the new platform-predicate module at `lib/core/platform/linux_platform_availability.dart` exposing the constants `isLinux`, `isLinuxDesktop`, `youtubeEngineAvailableOnLinux = false` (per R6), `googleSignInAvailableOnLinux = true` (per R10), `autoUpdaterAvailableOnLinux = false` (per R7), `echoRecordingAvailableOnLinux = true` (per R8), and `nativeLinuxAsrAvailable = true` (per plan.md audit)
- [x] T009 [P] Create the new `test/core/platform/linux_platform_availability_test.dart` covering all six predicates under `debugDefaultTargetPlatformOverride` for `TargetPlatform.linux` and the other four targets, ensuring every constant returns the expected value and the predicates are total (no throws) on every supported platform
- [x] T010 [P] Update `test/data/api/recording_client_platform_test.dart` (new file) to assert `recordingClientPlatformValue()` returns `'linux'` for `Platform.isLinux` (and only `'linux'`); the existing test coverage at `test/data/api/recording_client_platform_io.dart` is supplemented, not replaced
- [x] T011 [P] Update `test/features/auth/domain/auth_platform_support_test.dart` (new file) covering `nativeGoogleSignInSupported`, `nativeAppleSignInSupported`, and `authGooglePlatformParam()` for `TargetPlatform.linux`; the tests document the contract that the audit in plan.md establishes (per FR-013, per FR-020)
- [x] T012 [P] Verify the existing `test/core/release/distribution_channel_test.dart` Linux cases (lines 71–75, 116–119) remain green; no new test, but a run during this phase ensures the contract is preserved through the rest of the change

**Checkpoint**: Foundation ready — `lib/core/platform/linux_platform_availability.dart` exists and is tested, the constitution is amended, the ADR is on disk, and the agent / README are aligned. User story implementation can now begin.

---

## Phase 3: User Story 1 — Linux desktop user can install and run Enjoy Player (Priority: P1) 🎯 MVP

**Goal**: A Linux user can build, install, and launch Enjoy Player on a clean Ubuntu 22.04 LTS VM without developer tools beyond the apt package list. The app starts cold, the library loads, and a local media file plays back with transcript tracking. The build is reproducible on the self-hosted Linux runner.

**Independent Test**: Download the AppImage from `dl.enjoy.bot/player/v<version>/enjoy-player-<version>-x86_64.AppImage`, `chmod +x` it, run it on a clean Ubuntu 22.04 LTS VM, import a local `.mp4`, start playback, close the app, reopen it, and confirm the library + position are preserved.

### Tests for User Story 1

- [x] T013 [P] [US1] Add a smoke test in `test/features/player/application/media_kit_player_engine_linux_test.dart` that asserts `MediaKitPlayerEngine._videoControllerConfiguration` (made package-visible for testing) returns a non-null `VideoControllerConfiguration` with `enableHardwareAcceleration: false` and `hwdec: 'auto-safe'` when `Platform.isLinux`; this prevents the green-screen / EGL_BAD_DISPLAY regression on Linux + Wayland
- [x] T014 [P] [US1] Add a widget test in `test/app_loading_branch_test.dart` (extend existing) that asserts the `EnjoyApp` builds without throwing on `debugDefaultTargetPlatformOverride = TargetPlatform.linux`; documents that the bootstrap path on Linux is the same as on Windows/macOS

### Implementation for User Story 1

- [x] T015 [P] [US1] Add an explicit `Platform.isLinux` branch to `MediaKitPlayerEngine._videoControllerConfiguration` in `lib/features/player/application/player_engine.dart` returning `const VideoControllerConfiguration(width: kVideoControllerWidth, height: kVideoControllerHeight, hwdec: 'auto-safe', enableHardwareAcceleration: false)`; mirrors the macOS branch (R2)
- [x] T016 [US1] Run `flutter build linux --debug` locally and confirm the binary is produced at `build/linux/x64/debug/bundle/enjoy_player`; document any warnings introduced by the Linux build (none expected, but record and fix in this task if they appear)
- [x] T017 [US1] Run `flutter build linux --release` locally and confirm the binary is produced at `build/linux/x64/release/bundle/enjoy_player`; record the release-binary size for the docs page (T019)
- [x] T018 [US1] Manual smoke on a clean Ubuntu 22.04 LTS VM: download the AppImage from a local `flutter build linux --release` output, `chmod +x`, run it, confirm cold-start to window in ≤ 6 s (median), import a local `.mp4`, start playback, close + reopen, confirm library and playback position are preserved; this is the SC-003 verification (no CI has a desktop GUI session)
- [x] T019 [P] [US1] Create the new feature page at `docs/features/linux-platform.md` documenting: minimum supported distro (Ubuntu 22.04 LTS / Fedora 39 / Debian 12), package format (AppImage), install commands, what's supported (local media, transcripts, echo mode, library, sync, dictionary lookup, recording uploads), what's not yet supported (YouTube — coming soon, in-app auto-update — direct download only), and the measured cold-start budget from T018
- [x] T020 [US1] Verify the existing `lib/core/window/desktop_window.dart:11` `isDesktop` predicate returns `true` for `TargetPlatform.linux` (no code change; explicit read-through to confirm US1's "window opens" claim is correct)

**Checkpoint**: User Story 1 is fully functional — the Linux build compiles, the binary starts cold, the library loads, a local media file plays, and the persistence story matches Windows/macOS. This is the **MVP** (a Linux user can install and run the app).

---

## Phase 4: User Story 2 — CI verifies Linux on every change to native or shared code (Priority: P1)

**Goal**: A new GitHub Actions workflow `.github/workflows/build_linux.yml` runs the Linux desktop build on every PR and push to `main` that touches `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `linux/**`, or the Linux CI setup files. The workflow uses the same self-hosted Linux runner pool (`baizhiheizi`), the same Flutter SDK pin (`.github/flutter-version`), and the same apt-package set (`.github/scripts/ensure_linux_tooling.sh`) as the existing CI and Android smoke workflows.

**Independent Test**: Open a PR that touches only `lib/foo.dart` and observe that the new `build_linux.yml` workflow runs and succeeds; open a second PR that touches only `docs/some-doc.md` and observe that the workflow is correctly skipped.

### Tests for User Story 2

- [x] T021 [P] [US2] Verify the workflow YAML is valid by running `gh workflow view build_linux.yml` (or, if `gh` is unavailable locally, `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build_linux.yml'))"`); record the validation result on the PR

### Implementation for User Story 2

- [x] T022 [US2] Create `.github/workflows/build_linux.yml` mirroring the structure of `.github/workflows/build_windows.yml` and `.github/workflows/ci.yml`: `name: Build Linux`; `on.pull_request.paths` includes `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `linux/**`, `.github/flutter-version`, `.github/actions/setup-flutter/**`, `.github/scripts/ensure_linux_tooling.sh`, `.github/workflows/build_linux.yml`; `on.push.branches` is `main`; `on.workflow_dispatch` is enabled; `concurrency` is `${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true`; `permissions.contents: read`; `jobs.build-linux.runs-on: [self-hosted, Linux]`; the steps are `actions/checkout@v6`, `bash .github/scripts/ensure_linux_tooling.sh`, `./.github/actions/setup-flutter`, `flutter pub get`, `flutter build linux --debug`, `flutter build linux --release`, and an `actions/upload-artifact@v4` step that uploads the debug bundle (release bundle is NOT uploaded to keep storage cost predictable per the self-hosted-runner policy)
- [x] T023 [P] [US2] Update `docs/ci-self-hosted-runners.md` workflow table: add a new row for `build_linux.yml` with `Runner: Linux`, `Trigger: PR/push touching lib/, packages/, linux/, pubspec, or CI setup + manual`, and `Notes: Linux desktop build smoke (debug + release)`; add a one-line note in the Linux runner checklist section that the workflow targets the same gh-sr pool the other Linux workflows use
- [x] T024 [P] [US2] Update `README.md` to add the new `build_linux.yml` workflow badge under the existing CI badges section (per FR-017); use the same badge style as the other build-workflow badges
- [x] T025 [US2] Open a draft PR (or run `workflow_dispatch` from the Actions tab) to verify the new `build_linux.yml` workflow runs end-to-end on the self-hosted Linux runner; record the run time on the PR (target: ≤ 15 min per SC-002)

**Checkpoint**: User Story 2 is fully functional — every PR that touches shared code is automatically verified by a Linux desktop build workflow that runs in ≤ 15 min and is a merge gate. The workflow is wired to the same self-hosted runner pool and the same Flutter SDK pin as the other workflows.

---

## Phase 5: User Story 3 — Native Linux packaging, signing, and updates follow documented policy (Priority: P2)

**Goal**: The Linux build emits a single AppImage that runs on a clean Ubuntu 22.04 LTS / Fedora 39 / Debian 12 without `apt install` of project-specific dependencies. The release manifest `dl.enjoy.bot/player/latest.json` exposes a `linux` entry with a real URL. The public landing page (`landing/index.html`, `landing/i18n.js`, `landing/main.js`) shows a Linux download card with localized strings (en + zh), detects Linux via `navigator.userAgent`, and reads the manifest's `linux.url` to update the download link. The release-script dispatcher `.github/scripts/release.sh` routes `--platform linux` to a new `.github/scripts/release_linux.sh`.

**Independent Test**: Run `bash .github/scripts/release.sh --platform linux --skip-checks` on a Linux host with the apt packages installed; confirm a single AppImage is produced; upload it to `dl.enjoy.bot`; open `https://get.enjoy.bot/` on a Linux browser and confirm the Linux card shows a working download link to the new artifact.

### Tests for User Story 3

- [x] T026 [P] [US3] Add a JSON-Schema validation test in `test/landing/landing_manifest_linux_test.dart` (new file, or piggyback on an existing landing test file) that asserts the schema in `specs/014-linux-platform-support/contracts/release-manifest-linux.md` is satisfied by a representative v1 manifest; documents the manifest contract
- [x] T027 [P] [US3] Add a JS unit test for `landing/main.js → detectOS()` (extract the function to `landing/main.test.mjs` and run with `node --test`) asserting that `navigator.userAgent = 'Mozilla/5.0 (X11; Linux x86_64) ...'` returns `'linux'`; documents the OS-detection contract
- [x] T028 [P] [US3] Add a JS unit test for `landing/main.js → applyManifest(manifest)` (same `landing/main.test.mjs` file) asserting that when `manifest.assets.linux.url` is set, `#btn-linux.href` is updated and the `download` attribute is added; documents the manifest-application contract

### Implementation for User Story 3

- [x] T029 [P] [US3] Create the AppImage packaging script at `linux/packaging/make_appimage.sh`; it downloads `appimagetool` (a single static binary) from AppImageKit's official GitHub release on first run (cache under `~/.cache/appimagetool/`), runs it against `build/linux/x64/release/bundle/`, and produces `enjoy-player-<version>-x86_64.AppImage`; the script is idempotent, exits non-zero on any failure, and prints the SHA-256 of the produced AppImage at the end
- [x] T030 [P] [US3] Create the new release script at `.github/scripts/release_linux.sh`; it accepts the same flags as `release_windows.sh` (`--publish`, `--publish-only`, `--skip-checks`), runs `flutter build linux --release` (unless `--publish-only`), then runs `make_appimage.sh`, then computes the SHA-256, then merges the new `linux` entry into `dl.enjoy.bot/player/latest.json`, then uploads the AppImage to `dl.enjoy.bot/player/v<version>/` via the existing S3 publisher
- [x] T031 [US3] Update `.github/scripts/release.sh` to add a `linux)` case in the `case "${PLATFORM}" in` block that delegates to `release_linux.sh`; update the help text in the same file to document `--platform linux`; this is FR-018
- [x] T032 [US3] Update `docs/packaging.md`: add a "Linux" row to the host matrix table, add a "Linux AppImage" subsection under the release model that documents the format, the bundle path, and the publishing path, and add a "Linux" row to the GitHub Actions table at the bottom
- [x] T033 [P] [US3] Update `landing/index.html`: add a new `<article class="card" id="card-linux" aria-label="Linux">` block to the `.platform-grid` section, between `#card-ios` and the closing `</div>`, following the same pattern as the other cards (SVG icon, `data-i18n` attributes, `#btn-linux` anchor with `class="btn btn--primary"`); the SVG icon is the standard Tux / Linux glyph, similar in style to the existing platform icons
- [x] T034 [P] [US3] Update `landing/i18n.js`: add `download.linux.title`, `download.linux.subtitle`, `download.linux.btn`, and `download.linux.note` under both `en` and `zh` (per [data-model.md](data-model.md) "Localization" section)
- [x] T035 [P] [US3] Update `landing/main.js`: add `'linux'` to the `detectOS()` function (return `'linux'` when `/linux/i.test(ua)` is true); add `'btn-linux': assets.linux?.url,` to the `urlMap` in `applyManifest()` so the button's `href` and `download` attribute are set from the manifest
- [x] T036 [US3] Run a full end-to-end release dry-run: `bash .github/scripts/release.sh --platform linux --skip-checks` on a Linux dev machine; confirm the AppImage is produced, the manifest is updated, the script prints the SHA-256, and the artifact can be uploaded by the S3 publisher; this is the US3 manual verification gate

**Checkpoint**: User Story 3 is fully functional — Linux is a first-class packaging + publishing target with documented format, dispatcher integration, manifest contract, and landing-page card. The release flow is reproducible by any maintainer with the apt packages installed.

---

## Phase 6: User Story 4 — Linux behaves correctly under every platform-conditional in shared code (Priority: P2)

**Goal**: Every shared piece of code that today branches on `Platform.isWindows`, `Platform.isMacOS`, `TargetPlatform.windows`, `TargetPlatform.macOS`, `TargetPlatform.android`, or `TargetPlatform.iOS` is reviewed and adjusted where needed so the Linux branch produces a sensible result instead of falling through to a default that may not be valid. The audit table in `plan.md` is the source of truth; every row in that table has an action taken (EDIT / REVIEW / no-change).

**Independent Test**: Run `flutter test` on the Linux self-hosted runner (existing `ci.yml`) and confirm all the new tests from this phase and Phase 2 are green; manually exercise local media import, transcript import, echo practice, recording, settings change, and crash recovery on Linux; confirm no `UnsupportedError` / `MissingPluginException` is raised.

### Tests for User Story 4

- [x] T037 [P] [US4] Add a unit test in `test/features/player/application/player_engine_linux_test.dart` (or extend the existing `MediaKitPlayerEngine` test) that asserts the explicit Linux branch in `_videoControllerConfiguration` is selected when `Platform.isLinux`, mirroring the macOS branch's `enableHardwareAcceleration: false` and `hwdec: 'auto-safe'`
- [x] T038 [P] [US4] Add a unit test in `test/data/subtitle/embedded_subtitle_service_linux_test.dart` (new file) that asserts the FFmpeg lookup falls through to the system `ffmpeg` on Linux (the same way it does on macOS) and does not require a Windows-style bundled binary
- [x] T039 [P] [US4] Add a unit test in `test/features/player/application/engines/youtube/youtube_engine_availability_linux_test.dart` (new file) that asserts `youtubeEngineAvailableOnLinux == false` and that the YouTube engine's `open()` method throws an `UnsupportedError` with the localized "coming soon on Linux" message when invoked on `TargetPlatform.linux`

### Implementation for User Story 4

- [x] T040 [P] [US4] Update `lib/features/auth/domain/auth_platform_support.dart`: add explicit `TargetPlatform.linux` cases to `nativeGoogleSignInSupported` (returns `googleSignInAvailableOnLinux` from the new module), `nativeAppleSignInSupported` (already returns `false` for Linux; document with explicit case), and `authGooglePlatformParam()` (return `null` on Linux, mirroring the `_ => null` fallthrough but with a documented reason)
- [x] T041 [P] [US4] Update `lib/features/auth/data/google_sign_in_service.dart:14-32` to gate the `google_sign_in` initialization behind `googleSignInAvailableOnLinux` (or the equivalent `nativeGoogleSignInSupported`); this prevents a crash on Linux if the OAuth client is not configured for the Linux redirect URI
- [x] T042 [P] [US4] Update `lib/features/player/application/engines/youtube/youtube_player_engine.dart` (or the equivalent entry point) to throw an `UnsupportedError` with a localized "YouTube is not yet available on Linux — coming soon" message when `defaultTargetPlatform == TargetPlatform.linux`; this is the YouTube opt-out (R6) and ensures the app shows a clean message instead of crashing
- [x] T043 [P] [US4] Update `lib/features/asr/data/asr_audio_extractor.dart:153` to add a `Platform.isLinux` branch that mirrors the macOS / default FFmpeg-on-PATH flow; the new branch uses `nativeLinuxAsrAvailable` from the new module so it can be flipped to false if first smoke shows a regression
- [x] T044 [P] [US4] Update `lib/features/shadow_reading/data/echo_segment_pcm_extractor.dart:190, 240` to add `Platform.isLinux` branches that use the system `ffmpeg` on PATH; same flipping-via-module pattern as T043
- [x] T045 [P] [US4] Update `lib/features/ai/data/azure_assessment_wav_normalizer.dart:132` to add a `Platform.isLinux` branch
- [x] T046 [P] [US4] Update `lib/data/files/video_poster_extract.dart:98` to add a `Platform.isLinux` branch that uses the system `ffmpeg` on PATH (mirrors the existing Windows and macOS branches)
- [x] T047 [P] [US4] Update `lib/data/subtitle/embedded_subtitle_service.dart:54, 78, 101, 169, 183, 231, 296` to generalize the FFmpeg lookup so the Windows-specific bundled-binary path is one option and the system-PATH path is the default for non-Windows (including Linux and macOS); the file's existing logic mostly already does this; the change is a small refactor for clarity and testability
- [x] T048 [US4] Run `flutter analyze` and confirm the audit is clean (no new warnings introduced by the platform-conditional changes); fix any warnings in this task

**Checkpoint**: User Story 4 is fully functional — every platform-conditional site in the audit table has been reviewed, the Linux case is explicit and graceful, and the new tests prove the contract. The Linux app is no longer a "may follow" experiment; it is a first-class desktop target.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final documentation, gates, and cross-platform consistency.

- [x] T049 [P] Update `CHANGELOG.md`: add a `## Unreleased` entry (or the versioned entry for the next release) describing the Linux platform GA, the new AppImage format, and the constitutional amendment; link to the new ADR
- [x] T050 [P] Update `docs/packaging.md` "Quick start" section to mention `bash .github/scripts/release.sh --platform linux` for maintainers; cross-link to the new `docs/features/linux-platform.md` for users
- [x] T051 [P] Update `landing/index.html` `<meta name="description">`, `<meta property="og:description">`, and `<meta name="twitter:description">` to include "Linux" in the supported-platforms list
- [x] T052 [P] Update `landing/i18n.js` `meta.desc` for both `en` and `zh` to include "Linux" in the supported-platforms list
- [x] T053 [P] Update `specs/014-linux-platform-support/spec.md` "Status" line from "Draft" to "Implemented" once the change lands; cross-link to the PR
- [x] T054 [P] Update `specs/014-linux-platform-support/checklists/requirements.md` to mark every item as `[x]` (all items already pass in the spec phase; this is a sanity check that the implementation matched the spec)
- [x] T055 Run `bash .github/scripts/check_dart_format.sh` and fix any new format drift
- [x] T056 Run `bash .github/scripts/check_codegen_drift.sh` and regenerate if any Drift / Riverpod / Freezed annotations changed (expected: not in this change, but the gate must pass)
- [x] T057 Run `flutter analyze` and confirm zero new warnings; fix any in this task
- [x] T058 Run `flutter test` and confirm all tests pass; the new tests in Phase 2 (T009, T010, T011, T012) and Phase 6 (T037, T038, T039) are the headline new coverage
- [x] T059 Run `bash .github/scripts/validate_ci_gates.sh` and confirm all gates pass
- [x] T060 Run `bash .github/scripts/validate_ci_gates.sh --all` (or, if `--all` is not available in this script, run the underlying `flutter analyze && flutter test && check_dart_format && check_codegen_drift`) and confirm the full mirror of CI passes locally
- [x] T061 Run the scenarios in `specs/014-linux-platform-support/quickstart.md` end-to-end (or, for the ones that require a real Linux VM, record the manual verification result in the PR description); the new `build_linux.yml` workflow is the automated proxy for scenarios 1, 7, 8

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately. T001, T002, T003 are independent and parallel.
- **Foundational (Phase 2)**: Depends on Setup completion (T001 must have produced `linux/` for any subsequent code that imports it; the others can run in parallel with T001). **BLOCKS all user stories.**
  - T004 (ADR) must come first because the rest of the constitutional amendment (T005, T006, T007) references it.
  - T005, T006, T007 (constitution, AGENTS, README) can run in parallel after T004.
  - T008 (new module) is independent of T004..T007 and can run in parallel.
  - T009, T010, T011, T012 (tests for the new module and existing predicates) can run in parallel after T008.
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion (T008 must exist for T013; T001 must exist for T016, T017, T018). No dependencies on other user stories.
- **User Story 2 (Phase 4)**: Depends on Phase 2 completion (workflow is in `.github/workflows/`, which is independent of the new module but the path filter references `linux/**` which is from T001). No dependencies on US1, US3, US4.
- **User Story 3 (Phase 5)**: Depends on Phase 2 completion (T008 must exist for the dispatcher branch to be documented; the manifest contract already exists from the plan phase). No dependencies on US1, US2, US4.
- **User Story 4 (Phase 6)**: Depends on Phase 2 completion (T008 must exist for the new module's getters to be referenced). No dependencies on US1, US2, US3.
- **Polish (Phase 7)**: Depends on all four user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2). No dependencies on other stories. **This is the MVP.**
- **User Story 2 (P1)**: Can start after Foundational (Phase 2). Integrates with US1 only in that the workflow exercises the `linux/` folder produced by T001, but US2 is independently testable (the workflow can run before any app code is changed, and it will fail loudly if `linux/` is missing).
- **User Story 3 (P2)**: Can start after Foundational (Phase 2). Integrates with US1 only in that the AppImage is built from the `linux/` folder produced by T001, but US3 is independently testable (the release script can be exercised end-to-end before any in-app Linux behavior change).
- **User Story 4 (P2)**: Can start after Foundational (Phase 2). Independently testable; the new platform-conditional sites and their tests are self-contained.

### Within Each User Story

- Tests are written FIRST (T013/T014 before T015..T020 in US1; T021 before T022..T025 in US2; T026/T027/T028 before T029..T036 in US3; T037/T038/T039 before T040..T048 in US4). The tests should fail or be inapplicable before the implementation lands.
- Models / modules before services (T008 before anything that imports `linux_platform_availability.dart`).
- Implementation before integration (T015..T018 before T019 in US1; T022 before T023/T024 in US2; T029/T030 before T031/T032 in US3; T040..T047 before T048 in US4).
- Each story complete before moving to the next priority.

### Parallel Opportunities

- All Setup tasks (T001, T002, T003) can run in parallel.
- All Foundational tasks marked [P] (T007, T008, T009, T010, T011, T012) can run in parallel within Phase 2 after T004 / T005 / T006 land.
- All tests for a user story marked [P] can run in parallel.
- All platform-conditional implementation tasks in US4 (T040, T041, T042, T043, T044, T045, T046, T047) can run in parallel — they touch different files.
- All landing-page tasks in US3 (T033, T034, T035) can run in parallel — they touch different files.
- Different user stories can be worked on in parallel by different team members once Phase 2 is done.
- All Polish tasks marked [P] (T049, T050, T051, T052, T053, T054) can run in parallel.

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Add smoke test in test/features/player/application/media_kit_player_engine_linux_test.dart"
Task: "Add widget test in test/app_loading_branch_test.dart (extend existing)"

# Launch all model / module + cold-start work together:
Task: "Add explicit Platform.isLinux branch to lib/features/player/application/player_engine.dart"
Task: "Run flutter build linux --debug locally"
Task: "Run flutter build linux --release locally"
Task: "Manual smoke on Ubuntu 22.04 LTS VM"
```

## Parallel Example: User Story 4

```bash
# Launch all platform-conditional implementation work together (different files):
Task: "Update lib/features/auth/domain/auth_platform_support.dart"
Task: "Update lib/features/auth/data/google_sign_in_service.dart"
Task: "Update lib/features/player/application/engines/youtube/youtube_player_engine.dart"
Task: "Update lib/features/asr/data/asr_audio_extractor.dart"
Task: "Update lib/features/shadow_reading/data/echo_segment_pcm_extractor.dart"
Task: "Update lib/features/ai/data/azure_assessment_wav_normalizer.dart"
Task: "Update lib/data/files/video_poster_extract.dart"
Task: "Update lib/data/subtitle/embedded_subtitle_service.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: A maintainer builds the Linux AppImage on their Linux dev machine, manually installs it on a clean Ubuntu 22.04 LTS VM, and confirms the app starts cold, the library loads, and a local media file plays.
5. If the MVP is good enough to ship (it is — US1 delivers the headline Linux support), the work is shippable as a "Linux experimental" release even before US2..US4 land.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (T001..T012)
2. Add User Story 1 → Test independently → Ship a "Linux experimental" release
3. Add User Story 2 → CI gate is now in place → subsequent PRs are protected
4. Add User Story 3 → Linux is now a first-class packaging + publishing target
5. Add User Story 4 → Linux is now graceful in every platform-conditional site; US4 is the "polish" that makes the rest of the project Linux-safe
6. Polish (Phase 7) → final docs, gates, and CHANGELOG entry
7. Ship a "Linux GA" release

### Parallel Team Strategy

With multiple developers:

1. Team completes Phase 1 + Phase 2 together (small, mostly independent tasks).
2. Once Phase 2 is done:
   - Developer A: User Story 1 (build + smoke + cold-start documentation)
   - Developer B: User Story 2 (CI workflow + docs update)
   - Developer C: User Story 3 (release script + landing page) — this requires the AppImage from US1, so it can start in parallel but its end-to-end verification (T036) needs US1 to have produced the `linux/` folder
   - Developer D: User Story 4 (platform-conditional audit) — fully parallel, touches the most files
3. All four stories complete in parallel; the final Polish phase is a small cleanup.

---

## Notes

- The new ADR `0048-linux-platform-support.md` (originally filed as `0044-linux-platform-support.md`) is the documentation contract for the constitutional amendment (T004 → T005). Reviewers should read the ADR first.
- The platform-conditional audit table in `plan.md` is the source of truth for US4. Every row in that table has a corresponding task in Phase 6 (T040..T047) or is explicitly a "no change" in the table.
- Tasks T015 (the new Linux branch in `MediaKitPlayerEngine._videoControllerConfiguration`) and T040..T047 (the platform-conditional changes) are the only Dart code changes. Everything else is platform enablement, distribution, CI, docs, and one constitutional amendment.
- The test tasks assume the new tests are written to fail before the corresponding implementation lands. If a test cannot be written first (e.g. because the implementation needs to be present to even compile the test), the test is written immediately after the implementation and is run in the same task.
- Commit after each task or logical group; the PR description should link to `specs/014-linux-platform-support/quickstart.md` and reference the four user stories by their `US1`..`US4` labels.
- Stop at any checkpoint to validate the corresponding user story independently.
- Avoid: vague tasks, same-file conflicts (e.g. landing-page tasks T033/T034/T035 all touch the same `landing/` folder — coordinate by completing them in series within Phase 5, not in parallel), cross-story dependencies that break independence.
