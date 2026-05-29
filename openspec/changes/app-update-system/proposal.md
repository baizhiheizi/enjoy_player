## Why

Before the first public release, Enjoy Player has no way to tell users a newer version exists or help them install it. Store channels handle this for us, but in early days iOS ships via **TestFlight** and Android via a **Play test track** (both self-notify), while **Windows, macOS, and Android sideload APKs** are direct downloads with **no update path at all**. Without this, direct-download users are stranded on stale builds — including builds with destructive schema migrations.

## What Changes

- Add an in-app **update check** that runs at startup (debounced) and on a manual "Check for updates" action in Settings/About.
- Introduce a **distribution-channel split** via build flavors: a **`store`** flavor (TestFlight / Play test / future App Store + Play prod) and a **`direct`** flavor (Windows, macOS, Android sideload served from `dl.enjoy.bot`).
- Host release artifacts and update metadata on **`dl.enjoy.bot/player/`**: an **`appcast.xml`** (desktop, Sparkle/WinSparkle) and a **`latest.json`** (Android sideload), both generated in CI from each tagged release.
- Per-channel update strategy:
  - **Windows + macOS (`direct`)**: native auto-update via Sparkle/WinSparkle (appcast).
  - **Android sideload (`direct`)**: download + install APK from `latest.json`.
  - **iOS TestFlight + Android Play test (`store`)**: **no custom updater** — the platform owns it (no-op in early days).
- Support **optional** (dismissible, snoozeable) and **mandatory** (`minSupportedVersion`, blocking) update prompts, with **SHA-256** integrity verification before installing direct downloads.
- Extend release CI to publish binaries + `appcast.xml` + `latest.json` to S3/CDN and invalidate the manifest path.

## Capabilities

### New Capabilities

- `app-updates`: Detecting newer releases, comparing against the running version (including a minimum-supported-version floor), and presenting optional/mandatory update prompts with snooze and integrity checks.
- `update-distribution`: The `dl.enjoy.bot` artifact layout, `appcast.xml` / `latest.json` feed schema, build-flavor channel split, and CI publishing step.

### Modified Capabilities

<!-- None: no existing OpenSpec specs define update behavior. -->

## Impact

- **App code**: new `lib/features/update/` (or `core/release/`) `UpdateService` + per-platform strategies; wiring into `main()`/root provider and the existing About card ([`about_section_card.dart`](lib/features/settings/presentation/widgets/about_section_card.dart)).
- **Dependencies**: `auto_updater` (desktop Sparkle/WinSparkle), `ota_update` (Android sideload), optional `upgrader` (store soft-nudge later); reuse existing `package_info_plus`, `url_launcher`.
- **Build config**: Android/iOS/macOS/Windows **flavors** (`store` vs `direct`) — new variant axis on top of current per-platform CI.
- **CI**: `release_android.yml`, `release_apple.yml`, `release_windows.yml` gain an S3 upload + manifest-generation step.
- **Infra**: new `dl.enjoy.bot` subdomain (S3 + CDN), signing keys for appcast (Sparkle ed signatures) alongside existing Authenticode/notarization.
- **Docs**: new ADR (update channels + feed schema + flavors); updates to [`docs/packaging.md`](docs/packaging.md).
- **Settings**: new `settings_kv` keys (last-check timestamp, snooze-until); new l10n strings.
- **Constraints**: native desktop/mobile only (no web/`kIsWeb`); no `print()` (use `Log`); no store-policy-violating forced updates on `store` flavor.
