# Implementation Plan: YouTube Playback on Linux

**Branch**: `047-youtube-linux-playback` | **Date**: 2026-10-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/047-youtube-linux-playback/spec.md`

## Summary

Enable YouTube playback on Linux (currently opted out via a single build-time
constant) by upgrading the shared embedded-browser dependency to the release
line that ships a Linux backend (WPE WebKit), bundling the WPE + GStreamer
runtime into the self-contained AppImage, converting the build-time opt-out
into a runtime capability decision, and gating rollout on a documented
clean-VM verification plus a zero-regression smoke pass on the four existing
platforms. Full route rationale lives in [research.md](./research.md).

## Technical Context

**Language/Version**: Dart ^3.12.0 / Flutter 3.44.0 (mise pin, `.github/flutter-version` path kept in sync)

**Primary Dependencies**:
- `flutter_inappwebview` `6.2.0-beta.3` (upgraded from `^6.1.5`; exact pin, ADR-0029 precedent) — first line with a Linux backend
- `flutter_inappwebview_linux` `0.1.0-beta.1` (endorsed impl, resolves transitively)
- WPE WebKit 2.40+ runtime (bundled by the plugin's CMake via `flutter_inappwebview_linux_bundled_libraries`, `$ORIGIN` RPATH; WPEPlatform API preferred, WPEBackend-FDO fallback, software-rendering fallback)
- GStreamer runtime + plugin set (bundled at AppImage level — NOT covered by the plugin's bundling; see research D3)
- Untouched: `media_kit` stack (constitution: YouTube stays on the WebView engine), ffmpeg CLI pattern

**Storage**: N/A — no new persistence. Existing Drift stores keep their YouTube rows; playback surfaces are engine-internal.

**Testing**: `flutter analyze`, `flutter test` (unit + widget for the availability decision and gate call sites), `bash .github/scripts/validate_ci_gates.sh`, Linux CI build job, clean-VM manual matrix per [quickstart.md](./quickstart.md)

**Target Platform**: Linux x86_64 desktop (Ubuntu 22.04 LTS / Debian 12 / Fedora 40 / Arch baseline; Wayland and X11) as the enablement target; Android, iOS, macOS, Windows as zero-regression targets.

**Project Type**: Flutter desktop/mobile app (feature-first layout, Riverpod orchestration)

**Performance Goals**: cold-start-to-window regression ≤ 2 s; transport actions take effect ≤ 300 ms; open-to-first-frame ≤ 5 s on broadband (parity with Windows/macOS ±2 s); 24 h mixed session with flat memory and no leaked surfaces

**Constraints**: AppImage stays fully self-contained (+≤ 150 MB download budget, zero system packages); exactly one runtime availability decision consulted by every YouTube entry point; rollback posture = turn the availability decision off (one line)

**Scale/Scope**: one platform enablement; ~10 files under `lib/` (mostly gate plumbing), `linux/` packaging + `pubspec.yaml` upgrade, one ADR, two feature docs, localization additions, spike/verification evidence.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Architecture & Code Quality | ✅ Pass | Change lives in the existing `lib/features/player/application/engines/youtube/` module and `lib/core/platform/`; no new top-level folders; Riverpod providers for the availability decision; no feature-to-feature shortcuts. `media_kit` single-owner rule untouched (YouTube remains on the WebView engine per constitution). |
| II. Testing Defines the Contract | ✅ Pass (with documented manual path) | Runtime availability decision, gate call sites, and unavailable-state UI get unit/widget tests. Native browser behavior on real Linux systems cannot be proven in the Dart test suite — covered by the documented clean-VM verification (quickstart.md → FR-009 evidence), which the constitution explicitly allows ("or a documented manual verification reason"). |
| III. UX Consistency | ✅ Pass | Unavailable message reuses the existing `YouTubePlaybackUnavailableException` surfacing path; new strings go into ARB files for all locales; no new custom controls. |
| IV. Performance Is a Requirement | ✅ Pass | Spec states budgets (SC-002/003/004/005); cold-start and memory measurements are part of rollout evidence; no new hot paths in `build` methods (poll loop and bridge are unchanged code). |
| V. Documentation & Traceability | ✅ Pass | New ADR superseding the ADR-0048 opt-out clause (FR-011), `docs/features/linux-platform.md` + `docs/features/youtube.md` updated in the same change; packaging docs record the bundled runtime. |
| Flutter Quality Gates | ✅ Pass | `validate_ci_gates.sh` (format/codegen/analyze/test) before push; Linux build CI already exists (spec 014); per-platform compile smoke via the existing build workflows; no codegen annotations touched (Drift/Freezed/Riverpod codegen unaffected — plain provider code only). |

**Gate result**: no violations. Post-design re-check: unchanged — Phase 1 design introduces no new complexity beyond what is tracked here; the single testing exception (native behavior manual verification) is named above with its justification.

## Project Structure

### Documentation (this feature)

```text
specs/047-youtube-linux-playback/
├── plan.md              # This file
├── research.md          # Phase 0 output — route + dependency decisions
├── data-model.md        # Phase 1 output — availability decision model
├── quickstart.md        # Phase 1 output — spike + rollout validation guide
├── contracts/           # Phase 1 output — interface & artifact contracts
│   ├── runtime-availability.md
│   ├── release-artifact.md
│   └── platform-smoke-checklist.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/core/platform/
└── linux_platform_availability.dart        # MODIFIED: build-time const → runtime capability decision (single decision point, same call sites)

lib/core/webview/
├── windows_webview_environment.dart        # reference pattern
└── linux_webview_environment.dart          # NEW: Linux WebViewEnvironment bootstrap (mirrors Windows pattern)

lib/features/player/application/engines/youtube/
├── youtube_player_engine.dart              # MODIFIED: remove Linux mount no-ops, consult runtime decision
├── youtube_webview_host.dart               # MODIFIED: mount WebView on Linux (surface/texture)
├── youtube_webview_bridge.dart             # UNCHANGED invariants: poll loop, JS bridge calls
├── youtube_webview_controller.dart         # MODIFIED: environment/handler wiring for Linux
└── youtube_js_channel.dart                 # verify evaluateJavascript path on Linux backend

lib/features/player/application/
├── player_open_coordinator.dart            # gate call site — unchanged logic, new decision source
├── engine_swap_coordinator.dart            # gate call site
└── player_controller.dart                  # warmYoutubeSurface gate call site

lib/features/player/presentation/
├── youtube_login_screen.dart               # gate call site (deferred per spec — stays hidden until available)
└── widgets/youtube_video_stage.dart        # mount gate call site

lib/features/player/domain/
└── youtube_playback_unavailable_exception.dart  # reason taxonomy gains runtime-init failure

linux/
├── CMakeLists.txt                          # pkg-config deps for dev builds (wpewebkit, epoxy, libsecret…)
└── packaging/make_appimage.sh              # GStreamer runtime + plugin bundling, GST_PLUGIN_PATH in AppRun

pubspec.yaml / pubspec.lock                 # dependency upgrade, exact pin

test/
├── core/platform/linux_platform_availability_test.dart   # NEW
└── features/player/…                                     # gate call-site + unavailable-UI tests

docs/
├── decisions/00XX-youtube-linux-playback.md              # NEW ADR (supersedes ADR-0048 opt-out clause)
├── features/linux-platform.md
└── features/youtube.md

.github/workflows/release_linux.yml        # packaging path exercised in release build
```

**Structure Decision**: Feature-first layout preserved; the only new module file is the Linux webview environment bootstrap beside its Windows sibling, and the availability decision stays in its existing single home (`linux_platform_availability.dart`) so every gate call site keeps its shape. AppImage bundling extends the existing packaging script rather than introducing a second packaging path.

## Complexity Tracking

> No Constitution Check violations to justify — table intentionally empty.
