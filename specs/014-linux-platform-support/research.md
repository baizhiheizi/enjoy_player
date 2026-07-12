# Research: Linux Desktop Platform Support

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-12

This document resolves the unknowns surfaced in `plan.md` → Technical Context. Each section follows the format:

- **Decision**: what was chosen
- **Rationale**: why chosen
- **Alternatives Considered**: what else was evaluated

---

## R1: Does `flutter_inappwebview` support Linux, and is it production-ready?

### Decision

`flutter_inappwebview: ^6.1.5` supports Linux via the `flutter_inappwebview_linux` plugin (WebViewGTK / webkit2gtk). The Linux implementation is published and resolved transitively on `flutter pub get` for Linux targets. For this change, the **YouTube engine opts out on Linux** (graceful "YouTube coming soon on Linux" message) — see R6 for the full rationale.

### Rationale

- The Linux implementation depends on `webkit2gtk-4.0` (GTK 3 + WebKit2GTK 2.x). On a default Ubuntu 22.04 LTS desktop install, `webkit2gtk-4.0` is **not** installed by default — it must be added (`libwebkit2gtk-4.0-dev`).
- A v1 release that requires `apt install` of a non-obvious package (webkit2gtk) is a poor first impression for a new platform. The Windows and macOS apps do not require additional runtime installs.
- The native dependency is heavy (≈ 30 MB of additional shared libraries) and increases the AppImage size by an order of magnitude.
- The YouTube engine already has an opt-out path (it can be disabled for any platform); the rest of the app works on Linux without it.

### Alternatives Considered

- **Opt the YouTube engine in on Linux** — rejected for v1; the runtime dependency on `webkit2gtk-4.0` is fragile, large, and would block a clean AppImage-only experience. Re-evaluate after the first release if the user demand is high.
- **Use a different WebView library (e.g. `webview_flutter`)** — rejected; this would be a much larger rewrite and would diverge from the macOS/Windows path.
- **Build a separate `linux` YouTube feature flag in `auth_platform_support.dart`** — chosen; the new module `lib/core/platform/youtube_engine_availability.dart` centralizes the decision (R6).

---

## R2: Does `media_kit` (libmpv) work on Linux, and what `VideoControllerConfiguration` is correct?

### Decision

`media_kit: ^1.2.2` + `media_kit_video: ^2.0.0` + `media_kit_libs_video: ^1.0.7` work on Linux via the bundled `libmpv` shipped by `media_kit_libs_video`. The default `VideoControllerConfiguration()` (no overrides) is the starting point, with an **explicit Linux branch** in `MediaKitPlayerEngine._videoControllerConfiguration` that mirrors the macOS branch (`hwdec: 'auto-safe'`, `enableHardwareAcceleration: false`) to avoid green-screen / EGL_BAD_DISPLAY issues seen on Linux + Wayland + NVIDIA / AMD hybrid GPUs.

### Rationale

- The macOS branch already exists for the same reason (deprecated OpenGL HW textures can stay black). The same root cause applies to Linux on Wayland with discrete GPUs.
- `media_kit_libs_video` ships prebuilt `libmpv.so` for x86_64 Linux in the AppImage, removing the need for system-level `libmpv`.
- System-level `ffmpeg` is still required for `lib/data/files/ffmpeg_media_probe.dart` and the embedded-subtitle service; the AppImage bundles `ffmpeg` so the runtime is self-contained.

### Alternatives Considered

- **Require system `libmpv` and `ffmpeg`** — rejected; bloats the README, breaks the AppImage-only experience, and contradicts the "drop-in install" goal.
- **Use the system `media_kit` path that loads `libmpv` from PATH** — rejected; same reason. `media_kit_libs_video` ships a stable prebuilt binary per platform that does not require the user to have anything installed.
- **Disable hardware decoding entirely on Linux** — possible follow-up; the `auto-safe` profile degrades gracefully to software if the GPU path fails, so explicit disablement is not needed for v1.

---

## R3: What is the right apt-package set for `flutter build linux` on Ubuntu 22.04 LTS?

### Decision

Reuse the existing `.github/scripts/ensure_linux_tooling.sh` package list, plus `libwebkit2gtk-4.0-dev` and `libgtk-3-dev` are already there. No new packages are required for the build (only for the YouTube engine if it were opted in — see R1). The gh-sr `baizhiheizi` agentic runner image already bakes these into the container image via `container_runner_image.extra_apt_packages`, so the per-job `ensure_linux_tooling.sh` call is a fast no-op there.

### Rationale

- The package list (`clang cmake curl git jq ninja-build pkg-config unzip xz-utils zip libgtk-3-dev liblzma-dev libsqlite3-dev`) is the canonical Flutter Linux build set and has been validated by the existing `ci.yml` and `android_apk_smoke.yml` workflows.
- No change to the runner image is required.
- The same script runs on every job, so any non-gh-sr / native Linux host also works.

### Alternatives Considered

- **Bake a separate Linux-build image** — rejected; the existing image already supports the build.
- **Switch to a GitHub-hosted Linux runner (`ubuntu-latest`)** — rejected; the self-hosted-runner policy in `docs/ci-self-hosted-runners.md` forbids GitHub-hosted runners and `actions/cache` to keep CI cost predictable.

---

## R4: How is the Linux AppImage produced?

### Decision

A new script `.github/scripts/release_linux.sh` (mirroring `release_windows.sh` and `release_apple.sh`) wraps the `flutter build linux --release` output (`build/linux/x64/release/bundle/`) into an AppImage using a small bash script under `linux/packaging/make_appimage.sh`. The script downloads `appimagetool` (a single static binary) from AppImageKit's official GitHub release on first run, runs it against the bundle, and produces a single-file `enjoy-player-x.y.z-x86_64.AppImage`.

### Rationale

- AppImage is the only first-class v1 format per the spec (Assumptions).
- `appimagetool` is the standard, well-maintained tool from the AppImage project; it produces a single-file artifact that runs on Ubuntu 22.04 LTS / Fedora 39 / Debian 12 without `apt install` of project-specific deps.
- The script follows the same shape as the other release scripts (idempotent, env-var-driven, separate `--publish-only` mode) so the existing `release.sh` dispatcher can route to it.

### Alternatives Considered

- **`.deb` / `.rpm` packaging** — rejected for v1; each requires per-distribution build logic and a separate repository. Deferred to a follow-up ADR.
- **Flatpak** — rejected for v1; requires a Flatpak manifest, signing, and a Flatpak repository (Flathub or self-hosted). Out of scope.
- **snap** — rejected; Canonical-only, restricted store model, requires snapd on the target. Out of scope.
- **Linuxbrew-style tarball** — possible follow-up; not user-friendly enough as the only v1 option.

---

## R5: How does the landing page discover the Linux artifact?

### Decision

Extend the existing `dl.enjoy.bot/player/latest.json` manifest with a new `linux` entry. Schema mirrors the existing Windows / macOS / Android entries:

```json
{
  "version": "0.5.0",
  "assets": {
    "windows": { "url": "https://dl.enjoy.bot/player/.../EnjoyPlayerSetup-0.5.0.exe", "sha256": "..." },
    "macos":   { "url": "https://dl.enjoy.bot/player/.../enjoy-player-0.5.0-macos.zip", "sha256": "..." },
    "android_arm64_v8a": { "url": "https://dl.enjoy.bot/player/.../enjoy-player-0.5.0-arm64.apk", "sha256": "..." },
    "linux":   { "url": "https://dl.enjoy.bot/player/.../enjoy-player-0.5.0-x86_64.AppImage", "sha256": "...", "format": "appimage" }
  }
}
```

`landing/main.js` reads `assets.linux.url` and applies it to `#btn-linux` (a new anchor with the same `class="btn btn--primary"` shape as the other download buttons). `landing/main.js → detectOS()` is updated to return `'linux'` for `navigator.userAgent` matching `/linux/i`, and `highlightPlatform('linux')` runs the same reorder-and-badge logic as the other platforms.

### Rationale

- Reuses the existing manifest reader and update flow — no new CDN endpoint, no new config schema, no new deploy pipeline.
- The new `format` field is informational; the landing page does not branch on it (the same button serves the same single file).
- `navigator.userAgent` matching for Linux is well-established; false positives are rare in practice (Wayland reports Linux; X11 reports X11 + Linux).

### Alternatives Considered

- **Per-architecture manifests** (`linux-x86_64.json`, `linux-aarch64.json`) — rejected; aarch64 is out of scope for v1 (Assumptions). A future ADR can introduce a multi-arch manifest.
- **Detect `navigator.platform === 'Linux x86_64'` instead of UA** — considered; UA is more reliable across browsers, and we already use UA for the other OSes.

---

## R6: Is the YouTube engine on or off on Linux for v1?

### Decision

**YouTube engine is OFF on Linux for v1.** When the user opens a YouTube import or pastes a YouTube URL on Linux, the app shows a localized "YouTube is not yet available on Linux — coming soon" message in the existing transcript / video stage, with a link to the GitHub issue tracker. No crash, no `MissingPluginException`, no silent fallback to media_kit (which does not play YouTube).

### Rationale

- `flutter_inappwebview` on Linux requires `webkit2gtk-4.0` at runtime, which is not present on a default Ubuntu 22.04 LTS install. Shipping an AppImage that requires `sudo apt install libwebkit2gtk-4.0-dev` is a poor first impression and contradicts the "drop-in install" goal.
- The native dependency is heavy (≈ 30 MB of WebKit2GTK shared libraries) and would significantly bloat the AppImage.
- All other features (local media, transcripts, echo mode, library, sync) work on Linux without YouTube, so v1 is genuinely useful.
- The opt-out is a single conditional in a new `lib/core/platform/youtube_engine_availability.dart` helper, so re-enabling is a small change once the dependency story improves.

### Alternatives Considered

- **YouTube ON on Linux** — rejected for v1; see R1.
- **Ship a separate "YouTube-on-Linux" experimental build** — rejected; doubles the release matrix and confuses users.
- **Auto-detect `webkit2gtk-4.0` at startup and enable YouTube if present** — possible follow-up; would require a runtime probe of the package, which is a maintenance burden. The ADR captures this as a future option.

---

## R7: How does `auto_updater` behave on Linux, and is anything needed?

### Decision

No change. `auto_updater: 0.2.1` (exact pin) is already correctly excluded from Linux in `lib/features/update/application/direct_update_strategy.dart:50` (`if (Platform.isWindows || Platform.isMacOS)` … otherwise logs a warning). The Linux user gets a clear "no update available" status and is expected to download a new AppImage from the landing page.

### Rationale

- The plugin is Windows/macOS-only (it uses WinSparkle on Windows and Sparkle on macOS); there is no equivalent on Linux.
- Sparkle / AppImageUpdate / AppImageUpdate-Delta integration is a non-trivial effort; deferred to a follow-up ADR per the spec Assumptions.
- The direct-download model is consistent with what Linux users expect on day one (most Linux software is installed this way).

### Alternatives Considered

- **Bundle `AppImageUpdate`** — rejected for v1; requires an extra binary, runtime updates, and a separate signing story. Out of scope.
- **Use `update-notifier` (npm-style)** — rejected; not native, not Linux-native, would not integrate with the existing `auto_updater` flow.

---

## R8: What about `record`, `audioplayers`, `share_plus`, `app_links` on Linux?

### Decision

- `record: ^7.0.0` — Linux support is **experimental**; if first smoke shows a crash, echo recording is gracefully disabled on Linux with a localized "echo recording is not yet available on Linux" message (the rest of echo mode still works — shadow reading without recording).
- `audioplayers: ^6.1.0` — Linux supported via PulseAudio/PipeWire; no change.
- `share_plus: ^13.1.0` — Linux supported via `xdg-open`; no change.
- `app_links: ^6.4.0` — Linux supported; no change.

### Rationale

- The `record` package's Linux backend is the most fragile of the four; it depends on `libpulse` / `libpipewire` and the user's session bus configuration. A first smoke failure is plausible and must be handled.
- The other three are stable on Linux.

### Alternatives Considered

- **Replace `record` with `flutter_sound` on Linux** — rejected; would diverge the recording path from Windows/macOS.
- **Disable echo mode entirely on Linux** — rejected; too aggressive. Disabling just the recording step preserves the rest of echo mode's value.

---

## R9: How does `flutter_secure_storage` work on Linux?

### Decision

`flutter_secure_storage: ^10.2.0` uses `flutter_secure_storage_linux: 3.0.1` (already transitively resolved per `pubspec.lock`), which is backed by `libsecret` / GNOME Keyring / KWallet. If no keyring is installed (e.g. on a headless server), the secure storage degrades gracefully (existing behavior); the spec does not require a different backend.

### Rationale

- The transitive dep is already pinned and present in the lockfile; no `flutter pub add` is required.
- The "no keyring" degradation has been the project's behavior since day one; it is not Linux-specific.
- Documenting the requirement (libsecret / GNOME Keyring) on `docs/features/linux-platform.md` is sufficient for v1.

### Alternatives Considered

- **Use a different secret store on Linux (e.g. `kwalletd`, plain file with restricted permissions)** — rejected; `flutter_secure_storage_linux` already handles this internally.

---

## R10: What about `google_sign_in` on Linux?

### Decision

`google_sign_in: ^6.3.0` is **enabled on Linux** for v1. The Linux implementation works (via a browser-based OAuth flow that opens the system browser). If first smoke shows a crash or auth loop, the new `auth_platform_support.dart` predicate can be flipped to `false` for Linux and the button hidden, mirroring the Windows behavior.

### Rationale

- The package's Linux implementation is stable enough for v1.
- Most Enjoy Player users on Linux will want to sign in.
- The graceful-disable path is a one-line change in `auth_platform_support.dart`; no architecture impact.

### Alternatives Considered

- **Disable Google Sign-In on Linux** — rejected; the feature works and most users expect it.
- **Use a custom OAuth flow** — rejected; the package already handles it.

---

## R11: What is the constitutional amendment scope?

### Decision

The constitutional amendment is:

- **Version bump**: 1.1.0 → 1.2.0 (MINOR per the constitution's own versioning policy: "adds a principle or materially expands governance or quality gates").
- **Supported targets** (Flutter Quality Gates section): the existing list is "Android, iOS, macOS, and Windows". After the amendment: "Android, iOS, macOS, Windows, and Linux".
- **No new principle added**; the change is a platform-support expansion, not a new governance rule.

### Rationale

- The amendment is a small, surgical change — one sentence, one list expansion, one version bump — and is justified by the new ADR (`0044-linux-platform-support`).
- The constitution's own "Sync Impact Report" header at the top of the file is updated to reflect the bump.
- The amendment is part of the same PR as the rest of the change, so reviewers see all moving parts together.

### Alternatives Considered

- **Bump to 2.0.0 (MAJOR)** — rejected; no backward-incompatible redefinition occurs. The platform-support list is additive, not a redefinition.
- **Add a new principle "Linux Desktop Parity"** — rejected; the existing principles already cover everything Linux needs (architecture, testing, UX, performance, documentation). A new principle would be redundant.

---

## R12: How is the CI Linux build workflow structured?

### Decision

A new `.github/workflows/build_linux.yml` mirrors the structure of `ci.yml` and `build_windows.yml`:

- `on.pull_request.paths`: `lib/**`, `packages/**`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `linux/**`, plus the Linux CI setup files (`.github/scripts/ensure_linux_tooling.sh`, `.github/workflows/build_linux.yml`).
- `on.push.branches`: `main` (and `master` for parity with the other build workflows).
- `on.workflow_dispatch`: yes, so the maintainer can run the Linux build outside of a PR.
- `concurrency`: `${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true`, matching the other build workflows.
- `runs-on`: `[self-hosted, Linux]`, the same `baizhiheizi` pool the existing CI and Android smoke workflows use.
- Steps: checkout → `ensure_linux_tooling.sh` → `setup-flutter` action → `flutter pub get` → `flutter build linux --debug` → `flutter build linux --release` → upload debug build as a workflow artifact.

The workflow does **not** use `actions/cache` or `actions/upload-artifact` for long-term storage (existing self-hosted-runner policy).

### Rationale

- Path filters keep documentation-only PRs from consuming runner minutes.
- The toolchain is shared with the other workflows (same Flutter version, same Linux apt packages), so dependency drift is impossible.
- The debug artifact lets reviewers reproduce a failure locally by downloading the artifact, running `chmod +x enjoy_player`, and double-clicking.

### Alternatives Considered

- **Use `ubuntu-latest` (GitHub-hosted)** — rejected; self-hosted policy forbids it.
- **Run `flutter test` and `flutter analyze` in the same workflow** — rejected; the existing `ci.yml` already runs those. Avoid duplicating the matrix.
- **Add a `release_linux.yml`** — deferred; the release flow is a follow-up that wires `release_linux.sh` into the existing `release.sh` dispatcher; for v1, the AppImage is produced manually by running `release_linux.sh` on a maintainer machine.

---

## R13: What about `media_kit` + WebView combo on the same Window?

### Decision

The YouTube engine's `InAppWebView` is opt-out on Linux, so there is no `WebViewGTK + libmpv` co-existence concern for v1. The two never run in the same process on Linux.

### Rationale

- The opt-out decision (R6) is the single source of truth.
- The WebViewGTK + libmpv co-existence was a hypothetical risk; it is now moot.

### Alternatives Considered

- **Investigate the co-existence risk anyway** — deferred to a follow-up if/when YouTube is enabled on Linux.

---

## R14: Is there a Flutter Linux "minimum SDK version" concern?

### Decision

No. The Flutter SDK is pinned in `.github/flutter-version` (read by `.github/actions/setup-flutter`); the same pin is used by every workflow. The Linux build does not introduce a new SDK version requirement.

### Rationale

- The `baizhiheizi` gh-sr runner has a persistent, version-keyed Flutter install; the next workflow run after a `.github/flutter-version` bump downloads the new version once and reuses it.
- No system-level SDK (Java, .NET) is required for `flutter build linux`; the apt packages in `ensure_linux_tooling.sh` cover everything.

### Alternatives Considered

- **Pin a different Flutter version for Linux** — rejected; one version across the project is the only sane policy.

---

## R15: What happens with the existing `DistributionChannel.direct` on Linux?

### Decision

Already correct. `lib/core/release/distribution_channel.dart` returns `DistributionChannel.direct` for `TargetPlatform.linux` (tested at `test/core/release/distribution_channel_test.dart:71-75`). The Linux build is a "direct" build (no App Store / Play Store equivalent), so this is the right behavior. The release scripts must set `DISTRIBUTION_CHANNEL=direct` when producing the Linux build (mirroring how the other direct-build scripts do it).

### Rationale

- The existing test already covers this; no new code is required.
- The release script can simply pass `--dart-define=DISTRIBUTION_CHANNEL=direct` to `flutter build linux --release`, the same as the Windows release script does.

### Alternatives Considered

- **Introduce a new `DistributionChannel.linuxAppImage`** — rejected; AppImage IS a direct distribution. The existing enum covers it.

---

## Unresolved

- **AppImage signing** — AppImages can be signed with GPG; the existing dl.enjoy.bot infra already supports GPG signatures for the Windows Sparkle feed. Wiring the AppImage signature into the landing page / release script is a small follow-up; deferred to the v1.1 release. v1 ships unsigned AppImages, documented in `docs/features/linux-platform.md`.
- **Auto-update for Linux** — explicitly out of scope for v1 (Spec Assumptions). A follow-up ADR will evaluate AppImageUpdate, Flatpak, and snap.
- **AArch64 Linux** — explicitly out of scope for v1 (Spec Assumptions). A follow-up ADR will add multi-arch support.
- **YouTube on Linux** — explicitly opted out for v1 (R6). A follow-up ADR will re-evaluate when the WebKit2GTK dependency story improves.
