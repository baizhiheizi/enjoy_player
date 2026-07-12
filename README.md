# Enjoy Player

Cross-platform **language-learning player** (Android, iOS, Windows, macOS, Linux) built with Flutter. **Flutter web is not supported.**

## Prerequisites

- Flutter SDK (stable, 3.x)
- Dart SDK ^3.12 (matches `pubspec.yaml` and `.github/flutter-version`)
- **Apple (iOS + macOS)**: **Xcode**, **CocoaPods**, Apple Developer Program access for team **`46X685R747`**. See [packaging.md](docs/packaging.md#one-time-setup) for signing, TestFlight, and notarization.
- **macOS desktop builds**: [Homebrew](https://brew.sh) plus FFmpeg kit deps — `brew bundle install --file=macos/Brewfile` (see [packaging.md](docs/packaging.md#troubleshooting)). Without this, `flutter run -d macos` can fail at launch with a missing `libz.1.dylib` / DYLD error.
- **Windows desktop builds**: [NuGet CLI](https://learn.microsoft.com/en-us/nuget/install-nuget-client-tools?tabs=windows#nugetexe-cli) on your `PATH` (`nuget` / `nuget.exe`). Required by [`flutter_inappwebview`](https://inappwebview.dev/docs/intro#setup-windows) to pull WebView2 native dependencies during CMake/MSBuild. After installing, open a **new** terminal and run `nuget` to verify.
  - NuGet must have **at least one package source** (normally `nuget.org`). If `nuget sources list` is empty or MSBuild fails with `primarySources` / "Feeds used:" and then an error, add it once:  
    `nuget sources Add -Name "nuget.org" -Source "https://api.nuget.org/v3/index.json"`
  - **FFmpeg** (embedded subtitles, duration probe, echo PCM): run `pwsh windows/scripts/fetch_ffmpeg.ps1` before release builds — see [windows/ffmpeg/README.md](windows/ffmpeg/README.md).
- **Linux desktop builds**: Install the Flutter Linux build packages (clang, cmake, ninja-build, GTK 3, libsqlite3):
  ```bash
  sudo apt-get install -y clang cmake curl git ninja-build pkg-config xz-utils zip \
    libgtk-3-dev liblzma-dev libsqlite3-dev ffmpeg
  ```
  The Linux build uses the system `ffmpeg` (no separate fetch script). The CI workflow reuses `.github/scripts/ensure_linux_tooling.sh` for the same packages. See [docs/features/linux-platform.md](docs/features/linux-platform.md) for the full Linux support story.

## Setup

```bash
flutter pub get
dart run build_runner build   # after changing Drift / Riverpod annotations
```

### App icon & logo assets

The in-app logo uses [`assets/logo-light.svg`](assets/logo-light.svg). Launcher icons are generated from a raster export:

```bash
npm install --prefix tool
node tool/svg_to_png.mjs           # writes assets/logo.png from the SVG
dart run flutter_launcher_icons    # uses flutter_launcher_icons.yaml
```

## Run

```bash
flutter run
```

**Android** builds use `store` / `direct` [product flavors](docs/decisions/0023-app-update-distribution.md). Plain `flutter run` uses the default `store` flavor. To test sideload/OTA behavior locally:

```bash
flutter run --flavor direct --dart-define=DISTRIBUTION_CHANNEL=direct
```

If install fails with `INSTALL_FAILED_VERSION_DOWNGRADE`, uninstall the existing release build from the device first. On some OEMs (e.g. Xiaomi), enable **Install via USB** in Developer options when you see `INSTALL_FAILED_USER_RESTRICTED`.

## Test / analyze

Before pushing Dart changes, run the same cheap gates as CI (format + codegen drift):

```bash
bash .github/scripts/validate_ci_gates.sh
# or auto-fix + regenerate:
bash .github/scripts/validate_ci_gates.sh --fix
```

Then analyze / test:

```bash
flutter analyze
flutter test
```

Install git hooks once per clone (`git config core.hooksPath .githooks`) so pre-push runs format + codegen checks.

## Docs

| Doc | Purpose |
|-----|---------|
| [.specify/memory/constitution.md](.specify/memory/constitution.md) | Quality, testing, UX, performance, and governance principles |
| [AGENTS.md](AGENTS.md) | Rules for contributors & AI agents |
| [docs/architecture.md](docs/architecture.md) | Structure & flows |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records |
| [docs/features/](docs/features/) | Feature specs |
| [docs/features/linux-platform.md](docs/features/linux-platform.md) | Linux install, format, and support matrix |

## Tech highlights

- **Player**: [media_kit](https://pub.dev/packages/media_kit) (+ `media_kit_video`, `media_kit_libs_video`)
- **State**: [Riverpod 3](https://pub.dev/packages/flutter_riverpod) + `riverpod_annotation`
- **DB**: [Drift](https://pub.dev/packages/drift) + `drift_flutter`

## License

Private / unpublished (`publish_to: 'none'`).
