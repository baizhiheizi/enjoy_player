## ADDED Requirements

### Requirement: Versioned artifact layout on the download host

Release artifacts SHALL be published under `https://dl.enjoy.bot/player/<version>/<filename>` using the existing versioned filenames, with each version folder treated as immutable.

#### Scenario: Published release is addressable

- **WHEN** version `X.Y.Z` is released
- **THEN** each platform installer SHALL be retrievable at `https://dl.enjoy.bot/player/X.Y.Z/<filename>`

#### Scenario: Old versions remain available

- **WHEN** a newer version is published
- **THEN** prior `player/<version>/` folders SHALL remain unchanged and downloadable for rollback and support

### Requirement: Desktop appcast feed

The host SHALL serve a Sparkle-compatible `appcast.xml` at a stable path (`https://dl.enjoy.bot/player/appcast.xml`) describing the latest macOS and Windows releases, including version, download URL, and update signature, consumable by the desktop auto-update mechanism.

#### Scenario: Desktop client reads the appcast

- **WHEN** a `direct`-flavor desktop build checks for updates
- **THEN** it SHALL fetch `appcast.xml` from the stable path and resolve the latest version and platform-specific download URL

#### Scenario: Appcast reflects latest release

- **WHEN** a new desktop release is published
- **THEN** `appcast.xml` SHALL be updated to reference the new version and its assets

### Requirement: Android sideload manifest

The host SHALL serve a `latest.json` at a stable path (`https://dl.enjoy.bot/player/latest.json`) containing the latest `version`, `minSupportedVersion`, release notes, and per-platform asset entries with `url` and `sha256` (including per-ABI Android APKs and an iOS `storeUrl`).

#### Scenario: Sideload client resolves its APK

- **WHEN** a `direct`-flavor Android build checks for updates
- **THEN** it SHALL read `latest.json` and select the APK URL matching the device ABI along with its SHA-256

#### Scenario: Manifest carries minimum supported version

- **WHEN** the client reads `latest.json`
- **THEN** the manifest SHALL provide `minSupportedVersion` for the client to enforce mandatory updates

### Requirement: Build-flavor channel split

The app SHALL be buildable in a `store` flavor (TestFlight / Play test / future store production) and a `direct` flavor (Windows, macOS, Android sideload), where the flavor determines the update strategy and feed usage.

#### Scenario: Direct flavor targets the download host

- **WHEN** the app is built with the `direct` flavor
- **THEN** its update strategy SHALL target `dl.enjoy.bot` feeds

#### Scenario: Store flavor defers to the platform

- **WHEN** the app is built with the `store` flavor
- **THEN** its update strategy SHALL be a no-op that defers to the platform store

### Requirement: CI publishing of artifacts and feeds

Release CI SHALL, for a tagged release, upload built artifacts to `player/<version>/` and regenerate `appcast.xml` and `latest.json`, then invalidate the CDN cache for the feed paths. Signing SHALL occur before upload.

#### Scenario: Tagged release publishes feeds

- **WHEN** a `v*` tag triggers a release build
- **THEN** CI SHALL upload the signed artifacts and regenerated `appcast.xml` + `latest.json`, and invalidate the feed cache

#### Scenario: Immutable folders, mutable feeds

- **WHEN** CI publishes a release
- **THEN** it SHALL write a new immutable `player/<version>/` folder and overwrite only the two feed files
