# ADR-0023: App update distribution (direct download + store no-op)

## Status

Accepted

## Context

Enjoy Player ships on TestFlight (iOS), Play test (Android), and direct downloads (Windows installer, notarized macOS zip, Android sideload APK). Only direct-download channels lack an update path. Store channels must not implement custom download/install flows (policy + platforms already notify testers).

We host installers on `https://dl.enjoy.bot/player/` (S3 + CDN). Flutter has no single `electron-updater` equivalent; desktop uses Sparkle/WinSparkle, Android sideload uses install-intent OTA.

## Decision

1. **Distribution channel** — compile-time `DISTRIBUTION_CHANNEL` (`store` | `direct`), with Android **product flavors** `store` / `direct`. Dev defaults: mobile → `store`, desktop → `direct` when unset.
2. **Feeds** — CI generates **`appcast.xml`** (Sparkle, desktop `auto_updater`) and **`latest.json`** (semver, `minSupportedVersion`, APK URLs + SHA-256) from one tagged release. Immutable `player/<version>/` folders; overwrite only the two feed files.
3. **App behavior** — `store` → no custom updater. `direct` → fetch `latest.json`, compare semver, optional/mandatory Flutter prompts; install via `auto_updater` (desktop) or `ota_update` (Android sideload).
4. **Sparkle signing** — one **EdDSA** key pair for appcast enclosures (macOS `sparkle:edSignature`, Windows DSA per WinSparkle); private key in release secrets, never in repo.
5. **Android ABI (v1)** — `latest.json` exposes per-ABI APK entries; app selects **arm64-v8a** when available, else first listed APK (document arm64-only policy for public sideload).

## Consequences

- Release CI must upload artifacts and regenerate feeds; S3/CDN provisioning is operational (see [packaging.md](../packaging.md)).
- WinSparkle + Inno Setup and Sparkle + notarized zip require **manual spike verification** before first public auto-update (documented in packaging).
- Future App Store / Play production can add `upgrader` soft nudge on `store` without changing the direct channel.
