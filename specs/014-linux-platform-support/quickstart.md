# Quickstart: Linux Desktop Platform Support

**Feature**: [spec.md](spec.md) | **Date**: 2026-07-12

This quickstart is the end-to-end validation guide for the Linux platform support change. It documents runnable scenarios that prove the change works, with prerequisites, run commands, and expected outcomes. It does **not** include implementation code; that lives in `tasks.md` and the implementation phase.

## Prerequisites

- Linux desktop dev environment (Ubuntu 22.04 LTS x86_64 recommended; Fedora 39 / Debian 12 also supported).
- Flutter stable, pinned to the version in `.github/flutter-version`.
- The apt packages listed in `.github/scripts/ensure_linux_tooling.sh`:
  ```bash
  sudo apt-get install -y \
    clang cmake curl git ninja-build pkg-config unzip xz-utils zip \
    libgtk-3-dev liblzma-dev libsqlite3-dev
  ```
  On the self-hosted `baizhiheizi` Linux runner these are baked into the container image — no manual install.
- `ffmpeg` on `PATH` (for FFmpeg-based features; the AppImage bundles its own):
  ```bash
  sudo apt-get install -y ffmpeg
  ```
- A self-hosted Linux runner registered with labels `self-hosted`, `Linux` (the same pool the other workflows use).
- Access to the `dl.enjoy.bot` bucket for publishing (same S3 credentials as the other release workflows).

## Build Verification

### Scenario 1 — Linux desktop build compiles

**Objective**: prove the new `linux/` folder is wired correctly and the Linux desktop build succeeds.

**Steps**:

```bash
# 1. Get dependencies
flutter pub get

# 2. Confirm the linux folder was generated
ls linux/

# 3. Run the Linux build (debug)
flutter build linux --debug

# 4. Run the Linux build (release)
flutter build linux --release

# 5. Inspect the release bundle
ls -la build/linux/x64/release/bundle/
```

**Expected outcome**:
- `build/linux/x64/release/bundle/enjoy_player` exists and is a runnable ELF binary.
- No `MissingPluginException`, no `Could not find linux/CMakeLists.txt`, no `Unmet dependency` errors.
- The release bundle contains the Flutter assets, `lib/`, and the `data/` subdirectory.

**Test command**: the new `.github/workflows/build_linux.yml` runs this exact sequence on every PR; a green status is the headline gate.

---

### Scenario 2 — Linux desktop build runs

**Objective**: prove the binary actually starts on Linux.

**Steps**:

```bash
# From the bundle directory
cd build/linux/x64/release/bundle
./enjoy_player
```

**Expected outcome**:
- A window opens within 6 seconds (median; spec SC-003).
- The library page renders.
- No `EGL_BAD_DISPLAY` (Wayland fallback to XWayland works), no `libmpv.so: cannot open shared object file`, no `GTK module not found`.

**Test command**: manual verification on a clean Ubuntu 22.04 LTS VM. Documented in `docs/features/linux-platform.md`.

---

### Scenario 3 — AppImage production

**Objective**: prove the AppImage packaging step works.

**Steps**:

```bash
# From the repo root
bash linux/packaging/make_appimage.sh \
  --version 0.5.0 \
  --bundle build/linux/x64/release/bundle \
  --output dist/

# Run the AppImage
chmod +x dist/enjoy-player-0.5.0-x86_64.AppImage
./dist/enjoy-player-0.5.0-x86_64.AppImage
```

**Expected outcome**:
- A single file `dist/enjoy-player-0.5.0-x86_64.AppImage` exists.
- Running the AppImage launches the same binary as scenario 2 (no functional difference).
- The AppImage is self-contained: no `apt install` of project-specific dependencies is required on Ubuntu 22.04 LTS.

**Test command**: manual verification; first AppImage build is documented in the release notes.

---

### Scenario 4 — Landing page Linux card

**Objective**: prove the landing page surfaces the Linux download correctly.

**Steps**:

1. Update `dl.enjoy.bot/player/latest.json` to include the new `linux` entry (per [contracts/release-manifest-linux.md](contracts/release-manifest-linux.md)).
2. Upload the AppImage to `dl.enjoy.bot/player/v<version>/enjoy-player-<version>-x86_64.AppImage`.
3. Open `https://get.enjoy.bot/` in a Linux browser (e.g. Firefox on Ubuntu 22.04 LTS).
4. Click the "Linux" download card.

**Expected outcome**:
- The Linux card is visible alongside Windows / macOS / Android / iOS.
- The Linux card is highlighted as "Recommended for your device" (mirroring the existing OS-detect behavior).
- The download link points at the uploaded AppImage, not at the directory listing.
- The page metadata (`og:image`, `twitter:description`) includes "Linux" in the list of supported platforms.

**Test command**: manual verification by the release engineer; the contract test in [contracts/release-manifest-linux.md](contracts/release-manifest-linux.md) is the schema gate.

---

### Scenario 5 — Close-and-reopen preserves state

**Objective**: prove the persistence story is identical to Windows/macOS.

**Steps**:

1. Launch the AppImage.
2. Import a local media file (any `.mp4` or `.mp3`).
3. Open the file, start playback, then close the app.
4. Reopen the AppImage.

**Expected outcome**:
- The library still contains the imported media item.
- The last playback position is restored (if the feature is enabled in settings; otherwise the library is enough).
- No "library is empty" message; no "database corrupted" error.

**Test command**: manual verification; this is the persistence path used by all desktops and is already covered by the existing test suite (`flutter test` on the Linux CI runner).

---

### Scenario 6 — YouTube on Linux shows the "coming soon" message

**Objective**: prove the YouTube engine is gracefully opt-out on Linux.

**Steps**:

1. Launch the AppImage.
2. Open the YouTube import sheet and paste any YouTube URL.
3. Tap "Open".

**Expected outcome**:
- A localized message ("YouTube is not yet available on Linux — coming soon") is shown in the video stage area.
- No crash, no `MissingPluginException`, no `WebViewGTK not installed` dialog.
- The message has a link to the GitHub issue tracker (per the spec).

**Test command**: manual verification; the `youtubeEngineAvailableOnLinux` getter is unit-tested (always `false` for v1) in `test/core/platform/linux_platform_availability_test.dart`.

---

## Code Verification

### Scenario 7 — Platform-conditional audit passes

**Objective**: prove every shared `Platform.isX` / `TargetPlatform.x` site is reviewed and the Linux branch is explicit (or correctly absent).

**Steps**:

```bash
# From the repo root
flutter analyze
flutter test
```

**Expected outcome**:
- `flutter analyze` is clean (no new warnings).
- `flutter test` is green, including the new tests in:
  - `test/data/api/recording_client_platform_test.dart` (new)
  - `test/features/auth/domain/auth_platform_support_test.dart` (new)
  - `test/core/platform/linux_platform_availability_test.dart` (new)
  - `test/core/platform/desktop_platform_test.dart` (new, if `desktop_platform.dart` is added)
- The existing `test/core/release/distribution_channel_test.dart` Linux cases remain green.

**Test command**: the existing `ci.yml` workflow runs `flutter analyze` and `flutter test` on every PR; a green status is the gate.

---

### Scenario 8 — CI Linux build workflow

**Objective**: prove the new workflow runs on the right paths and only on the right paths.

**Steps**:

1. Open a PR that touches only `lib/foo.dart`.
2. Observe the Actions tab.
3. Open a PR that touches only `docs/some-doc.md`.
4. Observe the Actions tab.

**Expected outcome**:
- The first PR triggers `build_linux.yml` (because `lib/**` is in the path filter).
- The second PR does **not** trigger `build_linux.yml` (because `docs/**` is not in the path filter).
- Both PRs still trigger the existing `ci.yml` and `codegen_drift.yml` workflows (which have their own path filters).

**Test command**: manual verification by the reviewer; the workflow is wired in `.github/workflows/build_linux.yml`.

---

### Scenario 9 — Constitutional amendment is consistent

**Objective**: prove the constitutional version bump is applied and the document is internally consistent.

**Steps**:

```bash
# From the repo root
grep -E "Version|Linux" .specify/memory/constitution.md
grep -E "Supported platforms" AGENTS.md
grep -E "Linux" README.md
```

**Expected outcome**:
- `.specify/memory/constitution.md` shows `Version: 1.2.0`, the `Sync Impact Report` block reflects the bump, and the supported-targets list includes Linux.
- `AGENTS.md` lists Linux in the supported-platforms line (no "may follow" parenthetical).
- `README.md` describes Linux as a fully supported platform with a Linux setup section.
- The new ADR `docs/decisions/0044-linux-platform-support.md` exists and references the constitution version bump.

**Test command**: review-time; the new ADR is the spec's "documentation contract" for the amendment.

---

## Run Verification Commands

```bash
# 1. Format + codegen drift (CI gate)
bash .github/scripts/validate_ci_gates.sh

# 2. Analyze
flutter analyze

# 3. Test (host VM)
flutter test

# 4. Linux build smoke (matches CI)
bash .github/scripts/ensure_linux_tooling.sh
flutter pub get
flutter build linux --debug
flutter build linux --release

# 5. AppImage production (matches release)
flutter build linux --release
bash linux/packaging/make_appimage.sh --version <X.Y.Z> --bundle build/linux/x64/release/bundle --output dist/

# 6. Manual smoke on a clean Ubuntu 22.04 LTS VM
scp dist/enjoy-player-<X.Y.Z>-x86_64.AppImage test-vm:~
ssh test-vm 'chmod +x ~/enjoy-player-<X.Y.Z>-x86_64.AppImage && ~/enjoy-player-<X.Y.Z>-x86_64.AppImage'
```

## Key Files to Verify (read these for context)

- [spec.md](spec.md) — feature spec
- [plan.md](plan.md) — implementation plan + platform-conditional audit
- [research.md](research.md) — resolved unknowns (R1..R15)
- [data-model.md](data-model.md) — entities, no schema changes
- [contracts/release-manifest-linux.md](contracts/release-manifest-linux.md) — manifest schema

## Out of scope (manual verification only)

- **YouTube engine on Linux** — manually verified to NOT work; the opt-out message is the expected outcome.
- **AppImage auto-update** — v1 has no auto-update; users re-download manually. Future ADR will evaluate AppImageUpdate / Flatpak / snap.
- **AArch64 Linux** — out of scope for v1. Follow-up ADR.
- **AppImage GPG signature** — v1 ships unsigned AppImages. Follow-up.
