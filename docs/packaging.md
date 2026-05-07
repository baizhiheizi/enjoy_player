# Packaging & platforms

## Android

- `minSdk 21` set in [`android/app/build.gradle.kts`](../android/app/build.gradle.kts).
- `INTERNET` permission declared for `media_kit` / plugin baseline ([`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)).
- Java 17 toolchain already configured.

## iOS

- Deployment target **13.0** in Xcode project (≥ plan minimum 12).
- Local file playback uses copied files under app sandbox.

## macOS

- Sandbox **on**; entitlements include:
  - `com.apple.security.files.user-selected.read-write` (file picker)
  - `com.apple.security.network.client` (future streaming)
- Files: [`macos/Runner/DebugProfile.entitlements`](../macos/Runner/DebugProfile.entitlements), [`Release.entitlements`](../macos/Runner/Release.entitlements).

## Windows

- Default Flutter Windows runner; `media_kit_libs_video` ships native libs.

## Release builds

```bash
flutter build apk
flutter build ios
flutter build macos
flutter build windows
```

Signing & store listings are project-specific — document secrets outside this repo.
