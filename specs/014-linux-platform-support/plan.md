# Implementation Plan: Linux Desktop Platform Support

**Branch**: `014-linux-platform-support` | **Date**: 2026-07-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/014-linux-platform-support/spec.md`

## Summary

Promote Linux from "experimental / may follow" to a first-class supported desktop platform equal in status to Windows and macOS. The change adds the standard `flutter create --platforms=linux .` Linux desktop folder, introduces a new self-hosted-runner Linux desktop build workflow (`.github/workflows/build_linux.yml`) that mirrors the existing Windows/macOS/Android build smoke workflows, audits every shared `Platform.isX` / `TargetPlatform.x` site in `lib/` so the Linux branch is explicit and graceful, ships an AppImage as the v1 distribution format, updates the public landing page (`landing/index.html`, `landing/i18n.js`, `landing/main.js`) to add a Linux download card backed by a new `linux` entry in the existing release manifest, amends the constitution + AGENTS.md + README.md to reflect Linux as a first-class supported platform, and records the change in a new ADR (`0044-linux-platform-support`) that supersedes the constitution's current platform-support clause. No new Dart features ship in this change; the work is platform enablement, distribution, CI, docs, and one constitutional amendment.

## Technical Context

**Language/Version**: Dart `^3.12.0` (per `pubspec.yaml`) on the Flutter stable channel pinned in `.github/flutter-version`. No language version bump is required.

**Primary Dependencies** (no changes; verifying Linux compatibility of every direct + transitive package that touches native code):

- `media_kit: ^1.2.2` + `media_kit_video: ^2.0.0` + `media_kit_libs_video: ^1.0.7` — Linux supported via `libmpv` + system `ffmpeg`; already the cross-platform engine chosen in ADR-0003.
- `flutter_inappwebview: ^6.1.5` — Linux supported via WebViewGTK; the `flutter_inappwebview_linux` plugin is published and resolved transitively on `flutter pub get` for Linux targets. Decision on whether to enable the YouTube engine on Linux is captured in R6 / the new ADR.
- `auto_updater: 0.2.1` (exact pin) — already gated to `Platform.isWindows || Platform.isMacOS` in `lib/features/update/application/direct_update_strategy.dart:50`; Linux is correctly excluded. No change required.
- `sign_in_with_apple: ^7.0.1` — macOS/iOS only; `nativeAppleSignInSupported` in `lib/features/auth/domain/auth_platform_support.dart:27` already returns `false` for Linux.
- `google_sign_in: ^6.3.0` — Linux supported but optional; the auth provider predicate will be reviewed in FR-013.
- `flutter_secure_storage: ^10.2.0` — Linux supported via `flutter_secure_storage_linux: 3.0.1` (already transitively resolved per `pubspec.lock`), backed by libsecret / GNOME Keyring / KWallet. Graceful degradation when no keyring is installed is the existing behavior.
- `record: ^7.0.0` — Linux support varies; tested at smoke time. If it does not run on the Linux build smoke job, echo recording on Linux is gracefully disabled with a localized error (FR-013).
- `audioplayers: ^6.1.0` — Linux supported via PulseAudio/PipeWire.
- `share_plus: ^13.1.0` — Linux supported (xdg-open fallback).
- `app_links: ^6.4.0` — Linux supported.
- `sqlite3_flutter_libs: ^0.5.28` + `drift: ^2.31.0` + `drift_flutter: ^0.2.8` — Linux supported; same `.sqlite` files on disk as Windows/macOS via `getApplicationDocumentsDirectory()`.
- `window_manager: ^0.5.1` — already initialized in `lib/main.dart:48-57` for `windows | macOS | linux`; no change required.

**Storage**: Unchanged. The same Drift `AppDatabase` files on `getApplicationDocumentsDirectory()` work on Linux (FR-014 of the spec explicitly verifies close-and-reopen preserves library, transcripts, and player position).

**Testing**: `flutter test` (host VM) + the new `build_linux.yml` workflow (Linux build smoke). No new test framework. Coverage gate (`check_coverage_gate.sh`) and Dart format gate (`check_dart_format.sh`) are inherited from `ci.yml` and apply unchanged.

**Target Platform**: Android, iOS, macOS, Windows, **Linux** (after this change). No Flutter web. The constitution's supported-targets clause is amended in the same change (FR-006, FR-007).

**Project Type**: Flutter native mobile/desktop app — no new project type.

**Performance Goals** (per FR/SC in the spec):

- Cold-start to window on the documented test VM: **≤ 6 s** (median) on Ubuntu 22.04 LTS x86_64. Recorded in `docs/features/linux-platform.md`.
- Playback / scrolling / transcript rendering budgets: **identical to Windows/macOS** (the same engine, the same widget tree, the same Drift queries). No new budget is introduced; the existing evidence on the other desktops is reused.
- CI Linux build wall time: **≤ 15 min** on the self-hosted runner, per FR-019 and SC-002.

**Constraints**:

- Local-first, offline-capable (no Linux-specific change; inherited).
- No `print()`, no `kIsWeb` branches, no new `media_kit` `Player()` (AGENTS.md hard rules, inherited).
- Drift DAOs are the only SQLite path (AGENTS.md hard rule, inherited).
- Self-hosted Linux runner pool (`baizhiheizi`) is the only target; no GitHub-hosted runners, no `actions/cache`, no `actions/upload-artifact` for long-term storage (existing self-hosted-runner policy in `docs/ci-self-hosted-runners.md`, enforced by code review).
- FFmpeg on Linux: rely on system `ffmpeg` (no separate fetch script like the Windows `windows/scripts/fetch_ffmpeg.ps1`). The AppImage bundles ffmpeg alongside the binary when produced by `appimage` packaging; for the first CI smoke, system ffmpeg is sufficient.
- Linux build MUST be reproducible on a clean Ubuntu 22.04 LTS container; the `baizhiheizi` runner image already bakes the apt packages listed in `ensure_linux_tooling.sh`.

**Scale/Scope**: One new platform target (x86_64 Linux, Ubuntu 22.04 LTS minimum). No new feature surface area; no new Dart packages. Touched surface area:

- 1 new folder: `linux/` (Flutter desktop template + small customizations).
- 1 new workflow: `.github/workflows/build_linux.yml`.
- 1 new release-script dispatcher branch: `linux)` in `.github/scripts/release.sh` + a new `.github/scripts/release_linux.sh`.
- 1 new ADR: `docs/decisions/0044-linux-platform-support.md`.
- 1 new docs page: `docs/features/linux-platform.md`.
- Amendments: `.specify/memory/constitution.md` (version bump 1.1.0 → 1.2.0), `AGENTS.md`, `README.md`, `landing/index.html`, `landing/i18n.js`, `landing/main.js`, `docs/ci-self-hosted-runners.md`, `docs/packaging.md`.
- Code-level review: ~14 platform-conditional sites in `lib/` (catalogued in the audit table in this plan).
- Tests: FR-020's four new test cases (or augmentations) in `test/core/release/`, `test/features/auth/`, and any new `test/core/platform/` predicates.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- All Linux work is local to the existing layout: `lib/features/`, `lib/core/`, `lib/data/`, plus the auto-generated `linux/` folder. No new top-level folders.
- No new domain models; no new persistence paths. The Linux folder is a Flutter desktop scaffold, identical in role to `windows/`, `macos/`, `ios/`, `android/`.
- Riverpod is the only state mechanism touched. No new mutable global singletons. The existing `MediaKitPlayerEngine` / `PlayerController` ownership rule (ADR-0003) is unchanged on Linux.
- No `print()`, no new `kIsWeb` branches, no new direct `media_kit` `Player()` instantiation. Verified by the platform-conditional audit (see Project Structure → "Platform-conditional audit" below).

**Verdict: PASS.** The change is platform enablement, not new architecture.

### II. Testing Defines the Contract

Required tests, per FR-020 and the spec:

| Test | File | Type | Rationale |
|------|------|------|-----------|
| `recordingClientPlatformValue()` returns `linux` for `Platform.isLinux` | `test/data/api/recording_client_platform_test.dart` (new) | unit | Locks the `client_platform` contract that the backend classifies. |
| `resolveDistributionChannel()` returns `direct` for `TargetPlatform.linux` | already covered in `test/core/release/distribution_channel_test.dart` (lines 71–75, 116–119) — must remain green | unit | Distribution channel is a compile-time decision; Linux must stay on the direct channel. |
| `nativeGoogleSignInSupported` is graceful (non-throwing) for `TargetPlatform.linux` | `test/features/auth/domain/auth_platform_support_test.dart` (new) | unit | Today returns `true`; FR-013 review may flip it to `false` with a tooltip. |
| `nativeAppleSignInSupported` is `false` for `TargetPlatform.linux` | same file (new) | unit | Defensive: today it returns `false`; if anyone adds Linux to the iOS/macOS branch, this test fires. |
| `authGooglePlatformParam()` returns `null` for `TargetPlatform.linux` (the current behavior) | same file (new) | unit | Backend classifies by this string; `null` is a valid answer. |
| Any new shared `isLinux` / Linux-aware predicate is covered | `test/core/platform/` (new) | unit | Catches regressions in the audit's new predicates. |
| Linux desktop build compiles in CI | `.github/workflows/build_linux.yml` | integration | The headline acceptance gate of the whole change. |
| Manual verification on a clean Ubuntu 22.04 LTS VM | `docs/features/linux-platform.md` (new) | manual | Documented in the new docs page; first Linux release is a one-time manual gate because no CI runner has a desktop GUI session for smoke. |

Codegen: no Drift / Riverpod / Freezed annotation changes are expected in this change. If a code-review pass reveals a needed annotation (e.g. a new Riverpod provider for the platform predicate), `dart run build_runner build` runs as part of the change.

**Verdict: PASS.** The change has both automated and documented manual verification.

### III. User Experience Consistency

- New Linux download card uses the same `card` / `card-header` / `card-actions` / `btn` class structure as the existing Windows/macOS/Android/iOS cards (`landing/styles.css`).
- New user-facing strings are added to `landing/i18n.js` under both `en` and `zh`, referenced via `data-i18n` attributes in `landing/index.html`. The existing `setLanguage()` and `initI18n()` flow picks them up automatically.
- The Linux platform icon follows the same inline-SVG + `aria-hidden="true"` pattern as the other cards.
- `EnjoyTappableSurface` / `EnjoyTappableIcon` / `EnjoyButton` (ADR-0018) are not affected — the new Linux card is HTML/CSS in the landing page, not a Flutter widget.
- The new docs page `docs/features/linux-platform.md` is added to `docs/features/` and will be linked from the README's "Docs" table.
- The Linux in-app surfaces (settings, about, recovery) inherit all existing strings and patterns. No new in-app strings are required for v1.

**Verdict: PASS.** The change reuses established UI patterns.

### IV. Performance Is a Requirement

- Cold-start budget: **≤ 6 s** (median) on the test VM. Recorded in `docs/features/linux-platform.md` after the first release.
- Playback / scrolling / transcript rendering budgets: identical to Windows/macOS — same engine, same widget tree, same Drift queries. Reused evidence; no new measurement required for v1.
- Build smoke budget: **≤ 15 min** on the self-hosted Linux runner, enforced by FR-019 and SC-002.
- The `MediaKitPlayerEngine` already falls through to the default `VideoControllerConfiguration()` for non-Windows/non-macOS (see `lib/features/player/application/player_engine.dart:103-119`), so Linux will use libmpv's default hwdec path. If first-build smoke shows a green-screen or hwdec issue, the platform-specific `VideoControllerConfiguration` gets a Linux branch mirroring the macOS one (`hwdec: 'auto-safe'`, `enableHardwareAcceleration: false`).
- Heavy file / image / database / transcript work is already cached / streamed / paged on the other platforms; no new hot path is introduced by this change.

**Verdict: PASS.** Performance budgets are inherited and one new budget (cold-start) is recorded.

### V. Documentation and Traceability

Required documentation updates:

| Doc | Action | Why |
|-----|--------|-----|
| `docs/decisions/0044-linux-platform-support.md` | **new** | Required by FR-006; supersedes the constitution's platform-support clause and the "may follow" / "experimental" language in AGENTS.md and README.md. |
| `.specify/memory/constitution.md` | **amend** | Add Linux to the supported-targets list; bump version 1.1.0 → 1.2.0 with rationale; per FR-007 and the constitution's own versioning policy (MINOR = adds a principle or materially expands governance). |
| `AGENTS.md` | **amend** | Replace "Linux may follow" with "Linux is supported"; add `linux/**` to any platform-folder enumerations. Per FR-008. |
| `README.md` | **amend** | Replace "Linux experimental" with full support; add a Linux setup section; update the supported-platforms line. Per FR-009. |
| `docs/features/linux-platform.md` | **new** | New feature page covering install path, package format, update model, supported distros, what's not yet supported (YouTube on Linux if the ADR opts out, app auto-update, etc.). Linked from `docs/features/` and the README. Per FR-014. |
| `docs/ci-self-hosted-runners.md` | **amend** | Add the new `build_linux.yml` row to the workflow table; add a "Linux desktop smoke" line under the workflow descriptions. Per FR-016. |
| `docs/packaging.md` | **amend** | Add a "Linux" row to the host matrix; add a "Linux AppImage" section under release model; document the publishing path to `dl.enjoy.bot/player/`. |

Constitution exception: **none.** The change is fully consistent with the constitution; the constitution is amended (not violated) in the same change. The amendment is part of the same PR/feature so reviewers see both at once. Follow-up owner for the amendment is the repo owner (per the constitution's "Amendments require a documented diff" rule).

**Verdict: PASS.** All docs/ADR work is part of the change.

## Project Structure

### Documentation (this feature)

```text
specs/014-linux-platform-support/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── release-manifest-linux.md
└── tasks.md             # Phase 2 output (/speckit-tasks, NOT this command)
```

### Source Code (repository root)

```text
linux/                                       # NEW — flutter create --platforms=linux output
├── CMakeLists.txt                            # standard Flutter Linux template, customized for app name + icon
├── main.cc                                   # standard
├── my_application.cc                         # standard
├── my_application.h                          # standard
├── packaging/                                # NEW — AppImage builder + assets
│   └── make_appimage.sh                      # bundles build/linux/x64/release/bundle into an AppImage
└── flutter/
    └── (generated)

.github/
├── workflows/
│   └── build_linux.yml                       # NEW — Linux desktop smoke (PR + push to main + manual)
├── scripts/
│   ├── release_linux.sh                      # NEW — local + CI Linux release entry
│   └── ensure_linux_tooling.sh               # EXISTING — already adequate; no change required
├── actions/
│   └── setup-flutter/                        # EXISTING — no change
└── PULL_REQUEST_TEMPLATE.md                  # EXISTING — already lists Linux in "Platform tested"

landing/
├── index.html                                # EDIT — add Linux card, Linux SVG icon, btn-linux
├── i18n.js                                   # EDIT — add download.linux.* strings in en + zh
├── main.js                                   # EDIT — add 'linux' to detectOS(), add btn-linux to urlMap
├── config.js                                 # EXISTING — Linux manifest url already flows through latest.json
├── styles.css                                # EXISTING — reuses .card, .btn, .platform-icon
└── (og-image, screenshot, etc. unchanged)

lib/
├── main.dart                                 # EDIT (review only) — TargetPlatform.linux already in windowManager init
├── core/
│   ├── window/desktop_window.dart            # EXISTING — isDesktop already includes Linux; no change
│   ├── webview/
│   │   └── platform_webview_environment.dart # EDIT — add a Linux stub returning null + a guard
│   ├── recovery/recovery_actions.dart        # EXISTING — already handles Linux via xdg-open
│   └── utils/local_thumbnail.dart            # EXISTING — already includes Linux
├── data/
│   ├── files/
│   │   ├── ffmpeg_media_probe.dart           # EXISTING — already falls through to PATH
│   │   └── video_poster_extract.dart         # EDIT — add a Linux branch (analogous to macOS)
│   ├── subtitle/embedded_subtitle_service.dart # REVIEW — already has Windows-specific FFmpeg lookup; Linux uses PATH
│   └── api/recording_client_platform_io.dart # EXISTING — already returns 'linux'
├── features/
│   ├── auth/
│   │   ├── data/google_sign_in_service.dart  # REVIEW — google_sign_in Linux support varies
│   │   └── domain/auth_platform_support.dart # EDIT — add explicit Linux case (graceful)
│   ├── player/
│   │   ├── application/
│   │   │   ├── player_engine.dart            # EDIT — add Linux branch to _videoControllerConfiguration
│   │   │   ├── player_open_coordinator.dart  # REVIEW
│   │   │   └── engines/youtube/              # EDIT — add explicit opt-in or opt-out on Linux
│   │   └── presentation/widgets/app_sidebar.dart  # REVIEW
│   ├── update/application/direct_update_strategy.dart  # EXISTING — Linux correctly excluded
│   ├── asr/data/asr_audio_extractor.dart     # EDIT — add Linux branch
│   ├── shadow_reading/data/echo_segment_pcm_extractor.dart  # EDIT — add Linux branch
│   └── ai/data/azure_assessment_wav_normalizer.dart  # EDIT — add Linux branch
├── core/platform/                            # NEW (or expanded) — Linux-aware predicates live here
│   ├── mobile_platform.dart                  # EXISTING — unchanged (iOS + Android)
│   ├── desktop_platform.dart                 # NEW — centralizes isDesktop / isLinuxDesktop predicates
│   └── youtube_engine_availability.dart      # NEW — single source of truth for "is YouTube available here?"
└── (everything else unchanged)

test/
├── core/
│   ├── platform/                             # NEW
│   │   ├── desktop_platform_test.dart        # NEW
│   │   └── youtube_engine_availability_test.dart  # NEW
│   └── release/distribution_channel_test.dart  # EXISTING — Linux cases already green
├── data/
│   └── api/recording_client_platform_test.dart  # NEW
└── features/auth/domain/
    └── auth_platform_support_test.dart       # NEW

docs/
├── features/
│   └── linux-platform.md                     # NEW
├── decisions/
│   └── 0044-linux-platform-support.md        # NEW
├── ci-self-hosted-runners.md                 # EDIT — add build_linux row + Linux desktop smoke line
├── packaging.md                              # EDIT — add Linux row to host matrix, AppImage section
└── (others unchanged)

.specify/memory/constitution.md               # EDIT — version 1.1.0 → 1.2.0, add Linux to supported targets
AGENTS.md                                     # EDIT — "Linux may follow" → "Linux is supported"
README.md                                     # EDIT — replace "Linux experimental" + add Linux setup section
CHANGELOG.md                                  # EDIT — Linux GA entry under "Unreleased"
```

**Structure Decision**: This change uses the existing Flutter desktop folder layout (`linux/` is a sibling of `windows/`, `macos/`, etc.) and the existing feature-first Dart layout under `lib/`. The new docs page follows `docs/features/`, the new ADR follows `docs/decisions/`. The only new top-level folder is the auto-generated `linux/` Flutter desktop scaffold, which is identical in role to the existing `windows/`, `macos/`, `ios/`, `android/` folders. No monorepo split is needed.

### Platform-conditional audit (FR-013)

The following Dart sites were enumerated from `rg -n "Platform\.is|M|TargetPlatform\." lib/`. Each row is the action this change takes.

| File | Site | Current Linux behavior | Action |
|------|------|------------------------|--------|
| `lib/main.dart:50` | `windowManager.ensureInitialized()` for desktop | **Already in** the desktop branch. | No change. |
| `lib/core/window/desktop_window.dart:11` | `isDesktop` getter | **Already true** for Linux. | No change. |
| `lib/core/utils/local_thumbnail.dart:8` | Local thumbnail support | **Already true** for Linux. | No change. |
| `lib/core/recovery/recovery_actions.dart:113` | Reveal in file manager | **Already uses xdg-open** on Linux. | No change. |
| `lib/data/api/recording_client_platform_io.dart:9` | `client_platform=linux` | **Already returns `linux`**. | No change (test-only). |
| `lib/data/files/ffmpeg_media_probe.dart:29` | `ffmpeg` lookup | **Already falls through to PATH** for non-Windows. | No change. |
| `lib/features/player/application/player_engine.dart:103-119` | `VideoControllerConfiguration` | **Falls through to default** on Linux. | EDIT — add an explicit `Platform.isLinux` branch mirroring macOS to avoid green-screen / hwdec issues. |
| `lib/features/player/application/player_open_coordinator.dart:93` | Platform check for an unrelated path | **Returns false** on Linux (no special handling). | REVIEW — confirm no Linux crash path. |
| `lib/features/player/application/engines/youtube/*.dart` | YouTube WebView engine | **Untried on Linux** (no `linux/` folder until this change). | EDIT — add explicit Linux case: either opt-in (WebViewGTK works) or opt-out (clear "YouTube coming soon on Linux" message). The ADR picks one. |
| `lib/features/auth/data/google_sign_in_service.dart:14-32` | `google_sign_in` initialization | **Falls through to default** on Linux. | EDIT — gate behind a new `googleSignInAvailableOnLinux` flag in the auth-platform-support module; default to enabled, flip to disabled if first smoke shows a crash. |
| `lib/features/auth/domain/auth_platform_support.dart:16-50` | Auth provider predicates | **Returns `true` for Google, `false` for Apple** on Linux. | EDIT — add an explicit `TargetPlatform.linux` case in each switch so the behavior is documented and tested. |
| `lib/features/update/application/direct_update_strategy.dart:50` | `auto_updater` call | **Linux correctly excluded** with a warning. | No change. |
| `lib/features/asr/data/asr_audio_extractor.dart:153` | FFmpeg-based audio extraction | **No Linux branch**; uses default ffmpeg path. | EDIT — add an explicit Linux branch and a test that exercises it. |
| `lib/features/shadow_reading/data/echo_segment_pcm_extractor.dart:190, 240` | FFmpeg-based PCM extraction | **No Linux branch**. | EDIT — same as above. |
| `lib/features/ai/data/azure_assessment_wav_normalizer.dart:132` | WAV normalization | **No Linux branch**. | EDIT — add an explicit Linux branch. |
| `lib/core/webview/platform_webview_environment.dart:14` | `appWebViewEnvironment` getter | **Windows-only today**. | EDIT — generalize to also expose a Linux `WebViewEnvironment` if the YouTube engine opts in; keep Windows-only if the engine opts out. |
| `lib/core/theme/app_theme.dart:293` | Page transitions | **Already lists Linux**. | No change. |
| `lib/core/theme/widgets/glass_surface.dart` | Theme widget | Inherits. | REVIEW only. |
| `lib/features/player/presentation/widgets/app_sidebar.dart:115` | macOS-specific UI | **Hidden on Linux** (macOS-only). | No change. |
| `lib/data/files/video_poster_extract.dart:98` | Video poster extraction | **Windows branch**; default for others. | EDIT — add Linux branch if `ffmpeg` is in PATH. |
| `lib/data/subtitle/embedded_subtitle_service.dart:54, 78, 101, 169, 183, 231, 296` | Embedded subtitle extraction | **No Linux branch** (Windows-specific paths). | EDIT — generalize to "Windows: bundled exe; else: PATH" so Linux just works. |
| `lib/core/logging/log_redaction.dart:41` | Comment only | Comment mentions Linux/macOS. | No change. |

Every row above either has an action ("EDIT" / "REVIEW") or is a no-change. The audit table is the source of truth for the platform-conditional review and is included in the spec for accountability.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations. The constitution is amended in the same change to add Linux to the supported-targets list — the amendment is part of the change, not a violation that needs justification. The plan delivers:

- The constitutional amendment (FR-006, FR-007).
- A new ADR that records the decision and the consequences (FR-006, FR-008, FR-009, FR-014, FR-016).
- All FR-001..FR-020 as testable requirements.
- All SC-001..SC-009 as measurable outcomes.
- The platform-conditional audit (above) as the source of truth for FR-013.

The plan does NOT introduce a 4th project, a repository pattern, or any other architecture change. It is platform enablement, distribution, CI, docs, and one constitutional amendment.
