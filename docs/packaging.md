# Packaging & platforms

## Android

### Application ID

Production **`applicationId`** / **`namespace`**: `ai.enjoy.player` (see [ADR-0020](decisions/0020-android-windows-release-identity.md)). `MainActivity` lives under `android/app/src/main/kotlin/ai/enjoy/player/`.

### `minSdk` / toolchain

- **`minSdk`**: at least **26** (Azure / `media_kit` plugin baseline) — see [`android/app/build.gradle.kts`](../android/app/build.gradle.kts).
- **Java 17** for Gradle compile options.

### Release signing (Play + sideload)

1. Create an upload keystore (once) and keep it **out of git**.
2. Copy [`android/key.properties.example`](../android/key.properties.example) to **`android/key.properties`** (gitignored) and fill `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (`storeFile` is relative to the **`android/`** directory).
3. Build:
   - **Google Play (AAB):** `flutter build appbundle --release`
   - **Direct APK:** `flutter build apk --release`

If **`android/key.properties` is missing**, release builds still compile but use the **debug keystore** — **do not upload** those artifacts to Play.

### Gradle / network (`dl.google.com`)

Symptoms: configuring plugins fails with TLS handshake to Google Maven. Mitigations:

1. **Already in repo**: [`settings.gradle.kts`](../android/settings.gradle.kts) lists mirrors before `google()`.
2. Fix VPN/proxy/DNS (especially WSL2).
3. Use JDK **17** for Gradle.

### Permissions

[`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml): `INTERNET`, `RECORD_AUDIO`. After adding plugins, inspect the **merged manifest** for transitive permissions and complete Play **Data safety** / microphone declarations.

### R8 (release shrinker)

Release builds enable R8. [`proguard-rules.pro`](../android/app/proguard-rules.pro) includes `-dontwarn` entries for optional Azure / Reactor classpath references. If `flutter build appbundle` fails with new missing-class errors, follow Gradle’s suggested `missing_rules.txt` and extend that file.

---

## iOS

- Deployment target **13.0** in Xcode project (≥ plan minimum 12).
- Local file playback uses copied files under app sandbox.

## macOS

- Sandbox **on**; entitlements include user-selected files and network client.
- Files: [`macos/Runner/DebugProfile.entitlements`](../macos/Runner/DebugProfile.entitlements), [`Release.entitlements`](../macos/Runner/Release.entitlements).

### FFmpeg (`ffmpeg_kit_flutter_new`) and Homebrew

The macOS **ffmpeg_kit** prebuilt frameworks are linked against libraries under `/opt/homebrew/opt/…`. If those kegs are missing, the app crashes at launch with **DYLD, Library missing** (often `libz.1.dylib` from `libswresample.framework`).

**One-time setup (developers):**

```bash
brew bundle install --file=macos/Brewfile
```

The Xcode target runs [`macos/scripts/bundle_ffmpeg_homebrew_deps.sh`](../macos/scripts/bundle_ffmpeg_homebrew_deps.sh) after CocoaPods embeds frameworks. It copies the required Homebrew dylibs into `Contents/Frameworks/`, rewrites load paths to `@rpath`, and **re-signs** the touched binaries (required on recent macOS — otherwise dyld fails with `CODESIGNING` / “Invalid Page”).

## Windows

### Runner build

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/` (executable `enjoy_player.exe` plus `data/`, plugin DLLs).

### Prerequisites (developers)

- **NuGet CLI** on `PATH` for `flutter_inappwebview` / WebView2 native restore — see [README](../README.md).
- **WebView2 Runtime** is required at runtime for YouTube / in-app WebView flows; document for end users if you ship a bare zip.

### FFmpeg (feature parity)

Place **`windows/ffmpeg/ffmpeg.exe`** before the build so CMake copies it next to the executable, or put `ffmpeg` on **PATH**. See [`windows/ffmpeg/README.md`](../windows/ffmpeg/README.md). Without it, embedded subtitle probe/extract, some duration probes, echo PCM extraction, and poster extraction paths that rely on subprocess FFmpeg are degraded — see [architecture.md](architecture.md).

### Signed installer (Inno Setup)

Use the script under [`windows/installer/`](../windows/installer/README.md):

```bash
flutter build windows --release
iscc windows\installer\enjoy_player.iss
```

Installer output: `build/windows/installer/EnjoyPlayerSetup.exe`. **Code signing** (Authenticode) is configured outside this repo.

### Version / legal strings

File/product version comes from **`pubspec.yaml`** via Flutter’s `Runner.rc` injection. **Company / copyright** strings are in [`windows/runner/Runner.rc`](../windows/runner/Runner.rc); align with your legal entity before public release.

---

## Release verification (local)

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

Then platform release builds as above. CI runs analyze/tests and debug smoke builds; **release** APK/AAB/Windows builds are recommended before tagging a release.
