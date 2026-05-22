# Self-hosted CI runners

All GitHub Actions workflows in this repo (except **Build Windows**, which still uses GitHub-hosted `windows-latest` until a self-hosted Windows runner is ready) run on **self-hosted** runners registered for this repository only. They do **not** use GitHub Actions cache (`actions/cache` or `cache: true` on setup actions). Dependencies stay on local disk between jobs.

Shared workflow pieces:

| Path | Purpose |
|------|---------|
| [`.github/actions/setup-flutter`](../.github/actions/setup-flutter) | Install/pin Flutter from [`.github/flutter-version`](../.github/flutter-version) (`cache: false`) |
| [`.github/actions/setup-macos-runner-env`](../.github/actions/setup-macos-runner-env) | Homebrew PATH, UTF-8 locale, curl HTTP/1.1 |
| [`.github/scripts/ensure_linux_tooling.sh`](../.github/scripts/ensure_linux_tooling.sh) | Install apt packages only when missing |
| [`.github/scripts/ensure_nuget_feed.ps1`](../.github/scripts/ensure_nuget_feed.ps1) | Ensure NuGet.org feed on Windows |

When you bump Flutter in `.github/flutter-version`, the next workflow run installs/switches to that version on the runner via `flutter-action` (local disk, no GitHub cache API).

---

## Register runners

GitHub → repo **Settings** → **Actions** → **Runners** → **New self-hosted runner**.

Use labels that match workflow `runs-on`:

| Workflow | Labels |
|----------|--------|
| CI, Codegen drift, Android APK smoke | `self-hosted`, `Linux` |
| Build Apple, Release Apple | `self-hosted`, `macos` |
| Build Windows | `self-hosted`, `Windows` (planned; currently `windows-latest`) |

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
```

Runner user must access Keychain certs when using `APPLE_USE_RUNNER_KEYCHAIN=true`.

---

## Windows runner checklist

```bash
flutter --version
flutter doctor
nuget help   # NuGet CLI on PATH for azure_speech / WebView2
```

Optional: place `ffmpeg.exe` under `windows/ffmpeg/` before release builds (see [packaging.md](packaging.md)).

---

## Workflows

| Workflow | Runner | Notes |
|----------|--------|-------|
| [ci.yml](../.github/workflows/ci.yml) | Linux | analyze, format, test |
| [codegen_drift.yml](../.github/workflows/codegen_drift.yml) | Linux | build_runner drift check |
| [android_apk_smoke.yml](../.github/workflows/android_apk_smoke.yml) | Linux | APK + AAB compile smoke |
| [build_windows.yml](../.github/workflows/build_windows.yml) | GitHub-hosted `windows-latest` | debug + release smoke (until self-hosted Windows runner is ready) |
| [build_apple.yml](../.github/workflows/build_apple.yml) | macOS | iOS + macOS compile smoke |
| [release_apple.yml](../.github/workflows/release_apple.yml) | macOS | signed IPA, TestFlight, notarized macOS |
