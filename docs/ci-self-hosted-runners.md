# Self-hosted CI runners

**Overview:** [ci.md](ci.md) describes the hybrid managed + self-hosted strategy. PR gates (`flutter analyze`, `flutter test`, format, secret scan) run on GitHub-hosted **`ubuntu-latest`** so merges are not blocked when self-hosted runners are offline.

Platform compile smokes and releases (below) run on **self-hosted** runners registered for this repository only, except **Release Windows**, which still uses GitHub-hosted `windows-latest` until a self-hosted Windows runner is ready for publishing. They do **not** use GitHub Actions cache (`actions/cache` or `cache: true` on setup actions) or upload build outputs via `actions/upload-artifact` — both bill for storage. Dependencies stay on the runner's local disk between jobs; release binaries go to **dl.enjoy.bot** (S3/R2) when publish is enabled, or remain on the runner workspace until the job ends.

Shared workflow pieces:

| Path | Purpose |
|------|---------|
| [`.github/actions/setup-flutter`](../.github/actions/setup-flutter) | Install/pin Flutter from [`.github/flutter-version`](../.github/flutter-version) (`cache: false`) |
| [`.github/actions/setup-macos-runner-env`](../.github/actions/setup-macos-runner-env) | Homebrew PATH, UTF-8 locale, curl HTTP/1.1 |
| [`.github/scripts/ensure_linux_tooling.sh`](../.github/scripts/ensure_linux_tooling.sh) | Install apt packages only when missing |
| [`.github/scripts/ensure_nuget_feed.ps1`](../.github/scripts/ensure_nuget_feed.ps1) | Ensure NuGet.org feed on Windows |
| [`.github/workflows/shared/runtime.md`](../.github/workflows/shared/runtime.md) | gh-aw shared Flutter pre-agent setup + `dart` network for agentic workflows |

When you bump Flutter in `.github/flutter-version`, the next workflow run installs/switches to that version on the runner via `flutter-action` (local disk, no GitHub cache API).

---

## Agentic workflows (gh-aw)

GitHub **Agentic Workflows** (`gh-aw`) run on a Linux self-hosted runner with labels **`self-hosted`**, **`linux`**, and **`agentic`**. The same physical machine may also carry the **`Linux`** label used by deterministic CI — that is fine; both share the Flutter pin in [`.github/flutter-version`](../.github/flutter-version).

Each agentic job runs pre-agent steps from [`shared/runtime.md`](../.github/workflows/shared/runtime.md) before the AI engine starts:

1. `ensure_linux_tooling.sh` (apt packages, idempotent)
2. [`.github/actions/setup-flutter`](../.github/actions/setup-flutter)
3. `flutter pub get`

**Scope:** AWF requires Linux. Agents can run `flutter analyze`, `flutter test`, and `dart format` here — not iOS/macOS/Windows builds or signed Android releases.

**Network:** Shared runtime adds the gh-aw `dart` ecosystem (`pub.dev`, Flutter storage) to the firewall allowlist.

**Compile:** After editing workflow `.md` files, run `gh aw compile --validate` and commit the generated `.lock.yml` files.

Agentic workflow sources: `test-improver`, `repo-assist`, `perf-improver`, `duplicate-code-detector`, `large-file-simplifier`, `issue-triage`, `update-docs`, `agentic-wiki-writer`.

---

## Register runners

GitHub → repo **Settings** → **Actions** → **Runners** → **New self-hosted runner**.

Use labels that match workflow `runs-on`:

| Workflow | Labels |
|----------|--------|
| CI, Codegen drift, Android APK smoke | `self-hosted`, `Linux` |
| gh-aw agentic workflows (test-improver, repo-assist, …) | `self-hosted`, `linux`, `agentic` |
| Build Apple, Release Apple | `self-hosted`, `macos` |
| Release Android | `self-hosted`, `Linux` |
| Build Windows | `self-hosted`, `Windows` |
| Release Windows | GitHub-hosted `windows-latest` (planned: `self-hosted`, `Windows`) |

---

## Linux runner checklist

One machine can serve CI, codegen, and Android smoke jobs.

```bash
# Flutter (pin to .github/flutter-version)
flutter --version
flutter doctor

# Java 17+ on PATH
java -version

# Android SDK (set in runner service env or ~/.profile)
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"   # example path
sdkmanager "platforms;android-35" "build-tools;35.0.0"

# Build deps (CI also runs ensure_linux_tooling.sh idempotently)
sudo apt-get install -y \
  clang cmake curl git ninja-build pkg-config unzip xz-utils zip \
  libgtk-3-dev liblzma-dev libsqlite3-dev
```

Ensure the runner service inherits `PATH`, `ANDROID_SDK_ROOT`, and `JAVA_HOME`.

---

## macOS runner checklist

See also [apple-release-ci.md](apple-release-ci.md) for signing secrets and release steps.

```bash
flutter --version
xcodebuild -version
pod --version
brew bundle install --file=macos/Brewfile

# One-time after Xcode upgrade (installs CoreSimulator + CLI components; needs admin once):
sudo xcodebuild -runFirstLaunch

# iOS smoke CI also runs this idempotently; pre-warm to avoid multi-GB downloads mid-job:
xcodebuild -downloadPlatform iOS
```

The **Build Apple** workflow runs [`.github/scripts/ensure_ios_ci_toolchain.sh`](../.github/scripts/ensure_ios_ci_toolchain.sh) before iOS compile smoke. If `xcodebuild -runFirstLaunch` fails with *Authorization is required*, run the `sudo` command above on the runner Mac.

Runner user must access Keychain certs when using `APPLE_USE_RUNNER_KEYCHAIN=true`.

---

## Windows runner checklist

```bash
flutter --version
flutter doctor
nuget help   # NuGet CLI on PATH for azure_speech / WebView2
```

Windows release/smoke workflows run `windows/scripts/fetch_ffmpeg.ps1` automatically; for local builds see [packaging.md](packaging.md).

---

## Workflows

| Workflow | Runner | Notes |
|----------|--------|-------|
| [ci.yml](../.github/workflows/ci.yml) | GitHub-hosted `ubuntu-latest` | analyze, format, test, secret scan |
| [codegen_drift.yml](../.github/workflows/codegen_drift.yml) | Linux | build_runner drift check |
| [android_apk_smoke.yml](../.github/workflows/android_apk_smoke.yml) | Linux | APK + AAB compile smoke |
| [build_windows.yml](../.github/workflows/build_windows.yml) | self-hosted Windows | debug + release smoke |
| [build_apple.yml](../.github/workflows/build_apple.yml) | macOS | iOS + macOS compile smoke |
| [release_apple.yml](../.github/workflows/release_apple.yml) | macOS | signed IPA, TestFlight, notarized macOS |
| [release_android.yml](../.github/workflows/release_android.yml) | Linux | signed AAB/APK for Play / sideload |
| [release_windows.yml](../.github/workflows/release_windows.yml) | GitHub-hosted `windows-latest` | release build + Inno Setup installer |
