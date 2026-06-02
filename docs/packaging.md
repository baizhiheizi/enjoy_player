# Packaging & platforms

## Android

### Application ID

Production **`applicationId`** / **`namespace`**: `ai.enjoy.player` (see [ADR-0020](decisions/0020-android-windows-release-identity.md)). `MainActivity` lives under `android/app/src/main/kotlin/ai/enjoy/player/`.

### `minSdk` / toolchain

- **`minSdk`**: at least **26** (Azure / `media_kit` plugin baseline) — see [`android/app/build.gradle.kts`](../android/app/build.gradle.kts).
- **Java 17** for Gradle compile options.
- **AGP / Gradle** (staged AGP 9 upgrade): **AGP 9.0.1**, **Gradle 9.1.0**, **KGP 2.3.20** — see [`android/settings.gradle.kts`](../android/settings.gradle.kts) and [`android/gradle/wrapper/gradle-wrapper.properties`](../android/gradle/wrapper/gradle-wrapper.properties).
- **`android.newDsl=false`** in [`android/gradle.properties`](../android/gradle.properties) until Flutter and pub plugins finish the [AGP 9.0 variant API migration](https://developer.android.com/build/releases/agp-9-0-0-release-notes).
- **`android.builtInKotlin=false`** (same file): avoids duplicate Kotlin with Flutter’s auto-injected `kotlin-android` on modules that omit it in `build.gradle`; remove explicit `kotlin-android` / `org.jetbrains.kotlin.android` from `:app` and patched plugins to silence KGP warnings.
- After `flutter pub get`, run [`tool/patch_agp9_pub_plugins.sh`](../tool/patch_agp9_pub_plugins.sh) (Linux/macOS CI) or [`tool/patch_agp9_pub_plugins.ps1`](../tool/patch_agp9_pub_plugins.ps1) (Windows) to patch pub-cache Gradle files (`flutter_inappwebview_android` ProGuard name; strip explicit KGP from `package_info_plus`, `url_launcher_android`, `wakelock_plus`).
- **`ffmpeg_kit_flutter_new`** is vendored under [`packages/ffmpeg_kit_flutter_new`](../packages/ffmpeg_kit_flutter_new) (path dependency) with AGP 9–compatible `android/build.gradle` and dependencies moved outside the `android {}` block.

### Release signing (Play + sideload)

1. Create an upload keystore (once) and keep it **out of git**.
2. Copy [`android/key.properties.example`](../android/key.properties.example) to **`android/key.properties`** (gitignored) and fill `storePassword`, `keyPassword`, `keyAlias`, `storeFile` (`storeFile` is relative to the **`android/`** directory).
3. Build:
   - **Google Play (AAB):** `flutter build appbundle --release --flavor store` — Play serves optimized per-device splits automatically.
   - **Direct APK (sideload):** `flutter build apk --release --split-per-abi --flavor direct --dart-define=DISTRIBUTION_CHANNEL=direct` — one APK per CPU architecture (much smaller than a universal/fat APK).

   | Output APK | Typical use |
   |------------|-------------|
   | `EnjoyPlayer-vX.Y.Z-arm64-v8a.apk` | Most phones and tablets (2019+) |
   | `EnjoyPlayer-vX.Y.Z-armeabi-v7a.apk` | Older 32-bit ARM devices |
   | `EnjoyPlayer-vX.Y.Z-x86_64.apk` | x86_64 emulators / rare x86 devices |

   After `flutter build`, run `bash .github/scripts/rename_release_artifacts.sh android` to apply versioned names. Play upload uses **`EnjoyPlayer-vX.Y.Z.aab`** under `build/app/outputs/bundle/release/`. For sideload, pick **one** APK matching the device — do not install multiple ABIs.

If **`android/key.properties` is missing**, release builds still compile but use the **debug keystore** — **do not upload** those artifacts to Play.

**CI:** see [android-release-ci.md](android-release-ci.md) for GitHub Secrets, self-hosted runner setup, and [`.github/workflows/release_android.yml`](../.github/workflows/release_android.yml).

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

### Identity & deployment

- **Bundle ID**: `ai.enjoy.player` (matches Android `applicationId` in [ADR-0020](decisions/0020-android-windows-release-identity.md)).
- **Team**: `46X685R747` — automatic signing in [`ios/Runner.xcodeproj/project.pbxproj`](../ios/Runner.xcodeproj/project.pbxproj).
- **Deployment target**: **14.0** (`ios/Podfile`, Xcode project). Azure Speech pods require aligning pod targets to this floor.
- **Versioning**: `pubspec.yaml` → `CFBundleShortVersionString` / `CFBundleVersion`.

### Prerequisites (developers)

- **Xcode** + Apple Developer Program membership for the Enjoy team.
- **CocoaPods** (`pod --version` — Flutter doctor reports it when Xcode is installed).
- Open **`ios/Runner.xcworkspace`** (not `.xcodeproj`) after `flutter pub get`.

```bash
flutter pub get
cd ios && pod install && cd ..
```

### Privacy & capabilities

[`ios/Runner/Info.plist`](../ios/Runner/Info.plist):

- **`NSMicrophoneUsageDescription`** — shadow-reading / `record` package.
- **`ITSAppUsesNonExemptEncryption` = false** — standard HTTPS/TLS only (exempt encryption).

Local media uses the app sandbox (files copied on import). YouTube and Enjoy auth use `flutter_inappwebview` (see [youtube.md](features/youtube.md)).

**App Store Connect** (manual, before first upload):

1. Register App ID **`ai.enjoy.player`** in Apple Developer → Identifiers.
2. Create the app record in App Store Connect.
3. Complete **App Privacy** questionnaire: microphone (shadow reading), network/API usage, optional analytics if added later.
4. Provide microphone justification in review notes if asked.

### Native dependencies (CocoaPods)

`ios/Podfile` uses **`use_frameworks!`** (required for Azure Speech, ADR-0017). Notable pods: `MicrosoftCognitiveServicesSpeech-iOS`, `ffmpeg_kit_flutter_new/full-gpl`, `flutter_inappwebview_ios`, `media_kit_*`, `record_ios`.

[`ios/Podfile.lock`](../ios/Podfile.lock) is tracked for reproducible builds — commit changes when pods shift.

### Dev run

```bash
flutter run -d ios          # simulator or connected device
open ios/Runner.xcworkspace # confirm Team + Signing & Capabilities
```

### App Store / TestFlight release

**CI:** see [apple-release-ci.md](apple-release-ci.md) for GitHub Secrets, self-hosted runner setup, and [`.github/workflows/release_apple.yml`](../.github/workflows/release_apple.yml).

1. Bump `version:` in `pubspec.yaml`.
2. Run pre-release checks (see [Release verification](#release-verification-local) below).
3. Build and export:

```bash
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.export.plist
```

Output: `build/ios/ipa/enjoy_player.ipa` (rename to `EnjoyPlayer-vX.Y.Z.ipa` via `bash .github/scripts/rename_release_artifacts.sh apple`).

4. Upload via **Xcode Organizer** (Window → Organizer → Archives) or **Transporter** / `xcrun altool --upload-app`.
5. In App Store Connect: attach build to a version, submit for TestFlight or App Review.

Compile-only (no upload signing):

```bash
flutter build ios --release --no-codesign
```

---

## macOS

### Identity & deployment

- **Bundle ID**: `ai.enjoy.player` — [`macos/Runner/Configs/AppInfo.xcconfig`](../macos/Runner/Configs/AppInfo.xcconfig).
- **Team**: `46X685R747` — automatic signing in Xcode project.
- **Min OS**: **10.15** (`macos/Podfile`, Xcode project).
- **Display name**: Enjoy Player (`PRODUCT_NAME` in AppInfo.xcconfig).
- **Distribution target**: **direct download** with **Developer ID Application** signing + notarization (not Mac App Store).

### Prerequisites (developers)

- **Xcode** + **CocoaPods**.
- **Homebrew** + FFmpeg kit deps (see [FFmpeg section](#ffmpeg-ffmpeg_kit_flutter_new-and-homebrew) below).
- Open **`macos/Runner.xcworkspace`** after pods resolve.

```bash
flutter pub get
brew bundle install --file=macos/Brewfile
cd macos && pod install && cd ..
```

### Sandbox & entitlements

App Sandbox is **on**. Entitlements:

| File | Purpose |
|------|---------|
| [`DebugProfile.entitlements`](../macos/Runner/DebugProfile.entitlements) | Debug/Profile: sandbox, user-selected files, network client, JIT, network server, **audio input**, **Keychain Sharing** (`keychain-access-groups` for `flutter_secure_storage`) |
| [`Release.entitlements`](../macos/Runner/Release.entitlements) | Release: sandbox, user-selected files, network client, **audio input**, **Keychain Sharing** |

[`macos/Runner/Info.plist`](../macos/Runner/Info.plist) includes **`NSMicrophoneUsageDescription`** for shadow-reading.

**Keychain + debug signing:** `keychain-access-groups` (required for Enjoy account tokens via `flutter_secure_storage`) needs a real **Apple Development** signature, not ad-hoc (`-`). The Runner target sets `"CODE_SIGN_IDENTITY[sdk=macosx*]" = Apple Development` in [`project.pbxproj`](../macos/Runner.xcodeproj/project.pbxproj). On a new Mac, the first build may fail with *No profiles for 'ai.enjoy.player'* — register the machine and create a Mac development profile once:

```bash
cd macos && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
```

Or open **`macos/Runner.xcworkspace`** → Runner → **Signing & Capabilities** → ensure **Automatically manage signing** and team **46X685R747** are set, then build once in Xcode.

Release builds set **`ENABLE_HARDENED_RUNTIME = YES`**. `flutter build macos --release` uses automatic **development** signing; the notarization script re-signs with **Developer ID Application** before upload.

### Native dependencies

Same CocoaPods pattern as iOS (`use_frameworks!`). [`macos/Podfile.lock`](../macos/Podfile.lock) is tracked for reproducible builds.

### Dev run

```bash
flutter run -d macos
```

Run from the **repository root** (not only `macos/`) so paths match `build/macos`.

**Xcode “Stale file … outside of the allowed root paths” warnings:** Flutter builds into `build/macos`, but opening **`macos/Runner.xcworkspace`** in Xcode can leave artifacts under `~/Library/Developer/Xcode/DerivedData/Runner-*`. The workspace uses **project-relative Derived Data** at `build/macos` (see `macos/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`). If warnings persist after pulling that change, run once:

```bash
chmod +x macos/scripts/clean_xcode_derived_data.sh
./macos/scripts/clean_xcode_derived_data.sh
flutter run -d macos
```

**`Failed to foreground app; open returned 1`:** harmless when the app is already running or macOS blocks auto-focus from the terminal; the build still succeeds.

**Hot restart (`R`) on macOS:** unreliable with this app’s native stack (`media_kit` / Mpv, FFmpegKit, sqlite3). After hot restart you may see duplicate Objective‑C class warnings, `Unable to load asset: AssetManifest.bin`, missing fonts/SVGs, and layout crashes. Prefer **hot reload (`r`)** for Dart-only edits, or quit and run `flutter run -d macos` again for a full restart.

If launch fails with **DYLD, Library missing** (`libz.1.dylib` etc.), run `brew bundle install --file=macos/Brewfile` and rebuild. The Xcode **Bundle FFmpeg Homebrew deps** phase copies required dylibs into the app bundle.

### Direct release (Developer ID + notarization)

1. Bump `version:` in `pubspec.yaml`.
2. Run pre-release checks.
3. Build:

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/Enjoy Player.app`

4. **One-time notary credentials** (store outside git). Prefer **App Store Connect API key** (same as CI):

```bash
xcrun notarytool store-credentials "enjoy-notary" \
  --key "AuthKey_XXXXX.p8" \
  --key-id "YOUR_KEY_ID" \
  --issuer "YOUR_ISSUER_ID"
```

Or with Apple ID + app-specific password ([generate at appleid.apple.com](https://appleid.apple.com) → App-Specific Passwords):

```bash
xcrun notarytool store-credentials "enjoy-notary" \
  --apple-id "you@example.com" \
  --team-id "46X685R747" \
  --password "@keychain:AC_PASSWORD"
```

5. Notarize and staple:

```bash
./macos/scripts/notarize_release.sh \
  "build/macos/Build/Products/Release/Enjoy Player.app"
```

Override profile if needed: `NOTARY_PROFILE=my-profile ./macos/scripts/notarize_release.sh …`

6. Ship the stapled `.app` (zip or DMG). For a versioned zip at repo root:

```bash
version="$(bash .github/scripts/read_pubspec_version.sh)"
ditto -c -k --keepParent "build/macos/Build/Products/Release/Enjoy Player.app" \
  "EnjoyPlayer-macOS-v${version}.zip"
```

Gatekeeper should pass: `spctl --assess --type execute --verbose=4 "…/Enjoy Player.app"`.

**GPL note:** macOS/iOS use `ffmpeg_kit_flutter_new/full-gpl` (bundled FFmpeg). Confirm licensing/compliance before public distribution.

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

Before a release build, fetch the bundled binary (or put `ffmpeg` on **PATH**):

```powershell
pwsh windows/scripts/fetch_ffmpeg.ps1
flutter build windows --release
```

CMake copies **`windows/ffmpeg/ffmpeg.exe`** next to the executable when present. See [`windows/ffmpeg/README.md`](../windows/ffmpeg/README.md). Without it, embedded subtitle probe/extract, some duration probes, echo PCM extraction, and poster extraction paths that rely on subprocess FFmpeg are degraded — see [architecture.md](architecture.md).

### Signed installer (Inno Setup)

Use the script under [`windows/installer/`](../windows/installer/README.md):

```powershell
flutter build windows --release
pwsh .github/scripts/sync_windows_installer_version.ps1
iscc windows\installer\enjoy_player.iss
```

Installer output: `build/windows/installer/EnjoyPlayerSetup-vX.Y.Z.exe`. **Code signing** (Authenticode) is configured outside this repo.

**CI:** see [windows-release-ci.md](windows-release-ci.md) for GitHub Actions setup and [`.github/workflows/release_windows.yml`](../.github/workflows/release_windows.yml).

### Version / legal strings

File/product version comes from **`pubspec.yaml`** via Flutter’s `Runner.rc` injection. **Company / copyright** strings are in [`windows/runner/Runner.rc`](../windows/runner/Runner.rc); align with your legal entity before public release.

---

## Direct-download updates (`dl.enjoy.bot`)

See [ADR-0023](decisions/0023-app-update-distribution.md). **Store** builds (TestFlight, Play test) do not run a custom updater. **Direct** builds (Windows installer, notarized macOS zip, Android sideload APK) check `https://dl.enjoy.bot/player/latest.json` and install via Sparkle/WinSparkle (`auto_updater`) or `ota_update`.

### Build flavors / channel

| Artifact | Flutter build | `DISTRIBUTION_CHANNEL` |
|----------|---------------|------------------------|
| Play AAB | `flutter build appbundle --release --flavor store` | `store` (default on mobile) |
| Sideload APK | `flutter build apk --release --split-per-abi --flavor direct --dart-define=DISTRIBUTION_CHANNEL=direct` | `direct` |
| Windows / macOS direct | `flutter build windows\|macos --release --dart-define=DISTRIBUTION_CHANNEL=direct` | `direct` (default on desktop when unset) |

The **direct** Android flavor adds `REQUEST_INSTALL_PACKAGES` and the OTA `FileProvider` overlay under `android/app/src/direct/`.

### Publishing feeds (CI + local)

Hosting is **Cloudflare R2** (S3-compatible API) behind `https://dl.enjoy.bot/player/`. The publish script also supports plain AWS S3 + CloudFront if needed.

**GitHub Actions secrets** (Settings → Secrets → Actions):

| Secret | Purpose |
|--------|---------|
| `S3_ACCESS_KEY_ID` | R2 API token access key ID |
| `S3_SECRET_ACCESS_KEY` | R2 API token secret |
| `S3_BUCKET` | R2 bucket name |
| `S3_ENDPOINT` | e.g. `https://<account-id>.r2.cloudflarestorage.com` |
| `CLOUDFLARE_API_TOKEN` | Purge `latest.json` / `appcast.xml` after upload (Zone → Cache Purge) |
| `CLOUDFLARE_ZONE_ID` | Zone ID for `enjoy.bot` (website zone, not R2) |
| `SPARKLE_DSA_PRIV_PEM_BASE64` | WinSparkle **private** key (`dsa_priv.pem`, base64) for CI appcast signing |

Optional env (defaults in script): `S3_PREFIX` (`player`), `S3_REGION` (`auto` for AWS CLI).

### Sparkle / WinSparkle keys (desktop auto-update)

Desktop `direct` builds verify update packages with **Sparkle (macOS)** and **WinSparkle (Windows)**. Each platform needs a one-time key pair; CI signs each release artifact at publish time (`.github/scripts/sign_sparkle_enclosure.sh`).

#### macOS (EdDSA)

On a **Mac** (once):

```bash
flutter pub get
cd macos && pod install && cd ..
dart run auto_updater:generate_keys
```

Copy the printed `SUPublicEDKey` into [`macos/Runner/Info.plist`](../macos/Runner/Info.plist). The private key stays in the **login keychain** on that Mac.

For **CI** (self-hosted macOS runner): run `generate_keys` once on the same machine that publishes releases so `sign_update` can read the keychain.

#### Windows (DSA)

On **Windows** (once; requires [OpenSSL](https://slproweb.com/products/Win32OpenSSL.html) or `choco install openssl`):

```powershell
flutter pub get
dart run auto_updater:generate_keys
```

This creates `dsa_priv.pem` (secret) and `dsa_pub.pem` (public). Add to [`windows/runner/Runner.rc`](../windows/runner/Runner.rc):

```rc
DSAPub      DSAPEM      "..\\dsa_pub.pem"
```

Commit **`windows/dsa_pub.pem`** only. Store the private key as a GitHub secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("dsa_priv.pem"))
# → Settings → Secrets → SPARKLE_DSA_PRIV_PEM_BASE64
```

#### Verify wiring

```bash
bash .github/scripts/verify_sparkle_setup.sh
# Before dl.enjoy.bot is live:
SKIP_FEED_CHECK=1 bash .github/scripts/verify_sparkle_setup.sh
```

#### End-to-end spike (required before first public release)

1. Publish **vA** (older) to `dl.enjoy.bot` — install locally.
2. Bump `pubspec.yaml`, tag **vB**, let CI publish feeds.
3. Launch vA → Settings → **Check for updates** → confirm prompt → install vB.
4. Repeat for Windows installer, macOS zip, and Android sideload APK.

Without valid signatures, desktop clients may refuse to install updates even when feeds are correct.

### Cloudflare R2 + `dl.enjoy.bot` (one-time infra)

Feeds and installers are **404 today** until this is done:

1. **R2 bucket** — create a bucket (e.g. `enjoy-dl`), enable public access via **R2 custom domain** `dl.enjoy.bot` (or Workers route).
2. **R2 API token** — Object Read & Write → `S3_ACCESS_KEY_ID` / `S3_SECRET_ACCESS_KEY`; bucket name → `S3_BUCKET`; endpoint → `S3_ENDPOINT`.
3. **Cache purge** — `CLOUDFLARE_API_TOKEN` (Cache Purge) + `CLOUDFLARE_ZONE_ID` for the `enjoy.bot` zone.
4. **Smoke test** — after a tagged release, confirm:
   - `https://dl.enjoy.bot/player/latest.json` → 200
   - `https://dl.enjoy.bot/player/appcast.xml` → 200
   - `https://dl.enjoy.bot/player/<version>/EnjoyPlayerSetup-v<version>.exe` → 200

**Local — Git Bash / WSL** (install [AWS CLI v2](https://aws.amazon.com/cli/)):

```bash
export S3_ACCESS_KEY_ID="<R2 access key>"
export S3_SECRET_ACCESS_KEY="<R2 secret>"
export S3_BUCKET="<r2-bucket>"
export S3_ENDPOINT="https://<account-id>.r2.cloudflarestorage.com"
export CLOUDFLARE_API_TOKEN="<token with Cache Purge>"
export CLOUDFLARE_ZONE_ID="<zone id for enjoy.bot>"
```

**Local publish** — prefer [`release.ps1`](../release.ps1) (loads `publish_env.local.ps1` automatically):

```powershell
Copy-Item .github\scripts\publish_env.example.ps1 .github\scripts\publish_env.local.ps1
# edit credentials, then:
pwsh ./release.ps1 -Publish
```

Low-level publish (same script CI uses):

```powershell
. .\.github\scripts\publish_env.local.ps1
bash .github/scripts/publish_player_release_to_s3.sh --windows-installer "build/windows/installer/EnjoyPlayerSetup-v0.1.0.exe"
```

**Persistent user env vars (Windows)** — System Properties → Environment Variables, or PowerShell (new terminals only):

```powershell
[System.Environment]::SetEnvironmentVariable("S3_ACCESS_KEY_ID", "<key>", "User")
[System.Environment]::SetEnvironmentVariable("S3_SECRET_ACCESS_KEY", "<secret>", "User")
[System.Environment]::SetEnvironmentVariable("S3_BUCKET", "<bucket>", "User")
[System.Environment]::SetEnvironmentVariable("S3_ENDPOINT", "https://<account-id>.r2.cloudflarestorage.com", "User")
```

Verify: `echo $env:S3_BUCKET` (PowerShell) or `echo $S3_BUCKET` (Git Bash).

On tag push, release workflows call the same **`release_*.sh`** scripts, upload artifacts, and overwrite **`latest.json`** + **`appcast.xml`**.

See [Release verification (local)](#local-release-same-logic-as-github-actions) for `release.ps1` / `release.sh`.

---

## Versioned release filenames

Semver comes from `pubspec.yaml` (`version: 0.1.0+1` → `0.1.0` in filenames). CI applies these automatically; locally run the sync/rename scripts after building.

| Platform | Output (example at `0.1.0`) |
|----------|-----------------------------|
| Windows installer | `build/windows/installer/EnjoyPlayerSetup-v0.1.0.exe` — `pwsh .github/scripts/sync_windows_installer_version.ps1` before `iscc` |
| Android (Play) | `build/app/outputs/bundle/release/EnjoyPlayer-v0.1.0.aab` |
| Android (sideload) | `EnjoyPlayer-v0.1.0-arm64-v8a.apk` (and `-armeabi-v7a`, `-x86_64`) |
| iOS | `build/ios/ipa/EnjoyPlayer-v0.1.0.ipa` |
| macOS (zip) | `EnjoyPlayer-macOS-v0.1.0.zip` at repo root |

```bash
bash .github/scripts/rename_release_artifacts.sh android   # after flutter build appbundle/apk
bash .github/scripts/rename_release_artifacts.sh apple     # after flutter build ipa
```

---

## Release verification (local)

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

### Local release (same logic as GitHub Actions)

Use **`release.ps1`** (Windows) or **`release.sh`** (Git Bash / macOS / Linux). These call the same scripts as `.github/workflows/release_*.yml`.

**One-time:** copy publish credentials:

```powershell
Copy-Item .github\scripts\publish_env.example.ps1 .github\scripts\publish_env.local.ps1
# edit S3 / Cloudflare values
```

**Windows — build installer:**

```powershell
pwsh ./release.ps1                      # analyze + test + build + Inno Setup .exe
pwsh ./release.ps1 -SkipChecks          # faster iteration while debugging
```

**Publish to dl.enjoy.bot:**

```powershell
pwsh ./release.ps1 -Publish             # build + upload + feeds
pwsh ./release.ps1 -PublishOnly -Publish  # re-upload existing artifacts
```

**Test auto-update locally (no S3):**

```powershell
pwsh ./release.ps1 -FeedsOnly           # writes build/release/serve/player/
cd build/release/serve && python -m http.server 8787
# feeds point at http://127.0.0.1:8787/player — use for update spike testing
```

**Git Bash / macOS:**

```bash
bash .github/scripts/release.sh --platform windows
bash .github/scripts/release.sh --platform windows --publish
bash .github/scripts/release.sh --platform android --publish
bash .github/scripts/release.sh --platform apple --notarize --publish
```

Scripts (shared with CI):

| Script | Role |
|--------|------|
| [`release.ps1`](../release.ps1) | Windows entry point |
| [`.github/scripts/release.sh`](../.github/scripts/release.sh) | Platform dispatcher |
| [`.github/scripts/release_windows.sh`](../.github/scripts/release_windows.sh) | Windows build + publish |
| [`.github/scripts/publish_player_release_to_s3.sh`](../.github/scripts/publish_player_release_to_s3.sh) | Upload, sign, feeds |

Then platform release builds as above. CI runs analyze/tests and platform smoke builds (Android, Windows, iOS compile-only, macOS compile-only with ad-hoc signing) — see [testing.md](testing.md). **Release** APK/AAB/Windows/IPA/notarized macOS builds are recommended before tagging a release.
