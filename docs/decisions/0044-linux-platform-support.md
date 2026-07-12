# ADR-0044: Linux as a first-class supported desktop platform

## Status

Accepted

## Context

Since the project's inception, the supported platform list has been Android, iOS, macOS, and Windows. The AGENTS.md described Linux as "(Linux may follow)" and the README called it "Linux experimental." The codebase already had Linux fallbacks in several platform-conditional sites (`recovery_actions.dart` uses `xdg-open`, `desktop_window.dart` includes `TargetPlatform.linux` in `isDesktop`, `recording_client_platform_io.dart` returns `'linux'`, the `distribution_channel` and `distribution_channel_test` tests cover Linux), but there was no `linux/` Flutter desktop folder, no CI build workflow, no landing-page card, and no release packaging path.

On 2026-07-12, a feature spec (`specs/014-linux-platform-support/spec.md`) was accepted to promote Linux to a first-class supported desktop platform equal in status to Windows and macOS.

## Decision

### Platform status

Linux is promoted from "experimental / may follow" to a **first-class supported desktop platform**, equal in status to Windows and macOS for distribution, build, CI, and documentation purposes.

### Scope

**In scope for v1 (this ADR / feature)**:

| Item | Decision |
|------|----------|
| **`linux/` Flutter desktop scaffold** | Generated via `flutter create --platforms=linux .` and committed. Follows the upstream Flutter Linux template with minimal customizations. |
| **CI Linux build** | New `.github/workflows/build_linux.yml` workflow on the self-hosted `baizhiheizi` Linux runner pool (same pool as `ci.yml` and `android_apk_smoke.yml`). Runs on every PR touching `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `linux/**`, or CI setup files. |
| **Distribution format** | **AppImage** (single-file, runs on Ubuntu 22.04 LTS / Fedora 39 / Debian 12 without `apt install` of project-specific dependencies). `.deb`, `.rpm`, Flatpak, snap are out of scope for v1 and require their own ADR. |
| **Release pipeline** | New `.github/scripts/release_linux.sh` + `linux/packaging/make_appimage.sh`. Wired into the existing `.github/scripts/release.sh` dispatcher via `--platform linux`. |
| **Manifest** | The existing `dl.enjoy.bot/player/latest.json` manifest gains a `linux` entry (url, optional sha256, optional format). |
| **Landing page** | New `#card-linux` in `landing/index.html` with localized strings in `landing/i18n.js` (en + zh) and a `detectOS()` Linux case in `landing/main.js`. |
| **Documentation** | New `docs/features/linux-platform.md` page. `docs/packaging.md` updated with Linux rows. `docs/ci-self-hosted-runners.md` updated with the new workflow. |
| **Platform-conditional audit** | Every shared `Platform.isX` / `TargetPlatform.x` site in `lib/` is reviewed; Linux cases are made explicit and graceful. A new `lib/core/platform/linux_platform_availability.dart` module centralizes Linux-specific predicates. |
| **Constitutional amendment** | `.specify/memory/constitution.md` version bump 1.1.0 → 1.2.0 (MINOR: "materially expands governance or quality gates" by adding a new supported platform). The supported-targets sentence in the Flutter Quality Gates section is updated. |
| **YouTube engine** | **Opted out** on Linux for v1. The engine requires `flutter_inappwebview`'s Linux backend, which depends on `webview2gtk-4.0` — not present on a default Ubuntu 22.04 LTS install. The app shows a localized "YouTube is not yet available on Linux — coming soon" message. A follow-up ADR can re-evaluate. |
| **In-app auto-update** | **Opted out** on Linux for v1. `auto_updater: 0.2.1` (exact pin) is Windows/macOS-only. The Linux user downloads a new AppImage from the landing page. AppImageUpdate / Flatpak / snap auto-update is deferred. |
| **Minimum supported Linux** | Ubuntu 22.04 LTS (glibc 2.35, GTK 3, PulseAudio/PipeWire, x86_64). Other architectures (aarch64) and older distributions are out of scope for v1. |
| **Media playback** | `media_kit` + `media_kit_libs_video` on Linux (same engine as Windows/macOS, per ADR-0003). The `MediaKitPlayerEngine._videoControllerConfiguration` gains an explicit Linux branch mirroring macOS (`hwdec: 'auto-safe'`, `enableHardwareAcceleration: false`) to avoid green-screen / EGL_BAD_DISPLAY issues on Wayland + discrete GPUs. |
| **Auth providers** | Google Sign-In is **enabled** on Linux (`google_sign_in: ^6.3.0` supports Linux). Apple Sign-In is **not available** (same as Windows — `nativeAppleSignInSupported` already returns `false` for non-iOS/non-macOS). |
| **Recording (echo mode)** | `record: ^7.0.0` is **enabled** on Linux by default; a new `echoRecordingAvailableOnLinux` getter allows flipping it off if first smoke shows a crash. |

**Explicitly out of scope for v1 (require follow-up ADRs)**:

- `.deb` / `.rpm` / Flatpak / snap packaging
- In-app auto-update for Linux (AppImageUpdate, Flatpak, snap)
- AArch64 Linux
- YouTube on Linux (WebViewGTK dependency re-evaluation)
- AppImage GPG signature
- Per-distribution manifest entries or landing-page links

### Constitution amendment

The constitution (`.specify/memory/constitution.md`) is amended in the same change:

- Version: **1.1.0 → 1.2.0** (MINOR per the constitution's own versioning policy: the change "materially expands governance or quality gates" by adding a new supported platform to the enforcement scope).
- Flutter Quality Gates section, "Supported targets" sentence: updated from "Android, iOS, macOS, and Windows" to "Android, iOS, macOS, Windows, and Linux."
- The Sync Impact Report header block is updated with the new version, amendment date, and rationale.

The amendment is part of the same PR as the rest of the change so reviewers see the constitution change alongside the platform work it governs.

### AGENTS.md / README.md updates

- `AGENTS.md`: "Supported platforms: Android, iOS, macOS, Windows (Linux may follow)" → "Supported platforms: Android, iOS, macOS, Windows, Linux." The `linux/**` path is added to any platform-folder enumeration.
- `README.md`: "Linux experimental" → fully supported. A Linux setup section is added listing the apt packages a developer needs to build from source.

## Consequences

- **Positive**: Linux users can install and run Enjoy Player from the public landing page with no more friction than Windows/macOS users.
- **Positive**: Every PR that touches shared code is automatically verified on Linux by the new CI workflow, preventing silent Linux regressions on the other desktops.
- **Positive**: The constitution, AGENTS.md, README.md, and landing page are now internally consistent (no more "experimental / may follow" vs. partial code support).
- **Positive**: The new `LinuxPlatformAvailability` module centralizes Linux-specific decisions; a future ADR can flip a single constant to enable YouTube or auto-update on Linux without touching call sites.
- **Negative**: One new self-hosted CI job per PR (Linux desktop build smoke); the `baizhiheizi` runner pool already serves Linux CI and Android smoke, so the incremental load is small (~15 min per run, same resource pool).
- **Negative**: The landing page gains a new platform card and 4 new i18n strings per language; the page is already 278 lines and a fifth card adds ~25 lines.
- **Risk**: `flutter_inappwebview_linux` is a transitive dependency of `flutter_inappwebview: ^6.1.5` even when Linux is not a target; if a future `flutter_inappwebview` minor release drops Linux support, the CI job catches it.
- **Risk**: The `record` package's Linux backend is the most fragile of the audio packages; the `echoRecordingAvailableOnLinux` getter is a one-line kill switch if first smoke shows a regression.
- **Follow-up**: When YouTube-on-Linux demand grows, re-evaluate the WebViewGTK dependency story and flip `youtubeEngineAvailableOnLinux` to true. A separate ADR will capture the decision.
- **Follow-up**: When the first Linux user asks for a package-manager-native install (`.deb` / `.rpm` / Flatpak / snap), evaluate each format and write a separate ADR.

## Alternatives considered

- *Keep Linux as "experimental / may follow"* — rejected; the codebase already has Linux support in several places (recording uploads, `isDesktop`, `recovery_actions.dart`, `distribution_channel`, `desktop_window.dart`), the Flutter framework itself supports Linux as a first-class desktop target, and the landing page already has a platform-card pattern that a Linux card would slot into. The cost of "officially supported" is the `linux/` scaffold + a CI job + landing-page card; the cost of "unsupported forever" is one platform fewer than Flutter supports and a pattern of unaddressed user requests.
- *Enable YouTube on Linux for v1* — rejected; the `webview2gtk-4.0` dependency is not present on a default Ubuntu 22.04 LTS install and would force users to install an obscure package. The AppImage-only experience is a cleaner v1.
- *Ship a `.deb` / `.rpm` instead of AppImage* — rejected; AppImage is the only format that works on Ubuntu, Fedora, and Debian without per-distribution build logic. `.deb` and `.rpm` require separate maintenance pipelines and a repository.
- *Add Linux to a separate "mobile + desktop" vs. "desktop only" ADR* — rejected; the constitution amendment is small (one sentence) and the decision is scoped to this single ADR, which is already comprehensive.
- *Ship Linux without a constitutional amendment* — rejected; the constitution and the platform-support list must stay aligned, and the amendment is a one-sentence change.

## Artifacts

- [spec.md](../../specs/014-linux-platform-support/spec.md) — feature spec
- [plan.md](../../specs/014-linux-platform-support/plan.md) — implementation plan + platform-conditional audit
- [research.md](../../specs/014-linux-platform-support/research.md) — 15 resolved unknowns (R1..R15)
- [data-model.md](../../specs/014-linux-platform-support/data-model.md) — entities (no Drift schema changes)
- [contracts/release-manifest-linux.md](../../specs/014-linux-platform-support/contracts/release-manifest-linux.md) — manifest schema
- [quickstart.md](../../specs/014-linux-platform-support/quickstart.md) — 9 validation scenarios
- [tasks.md](../../specs/014-linux-platform-support/tasks.md) — task breakdown
