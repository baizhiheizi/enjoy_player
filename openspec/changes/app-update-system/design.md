## Context

Enjoy Player targets Android, iOS, macOS, Windows (Linux later); **no Flutter web** (AGENTS.md). Releases are produced per-platform by CI ([`docs/packaging.md`](../../../docs/packaging.md)) with versioned filenames derived from `pubspec.yaml` (`0.1.0+1`). The app already shows its version via `package_info_plus` and links out via `url_launcher` ([`about_section_card.dart`](../../../lib/features/settings/presentation/widgets/about_section_card.dart)). API defaults live at `https://enjoy.bot` / `https://worker.enjoy.bot` ([`settings_keys.dart`](../../../lib/data/db/settings_keys.dart)); a sibling `dl.enjoy.bot` download host fits the existing domain model.

**Early-days reality** shapes the design: iOS ships via **TestFlight** and Android via a **Play test track**, both of which notify testers and auto-update natively. The only channels with **no** update path are **Windows, macOS, and Android sideload APKs**. A custom updater on store builds would also violate Apple/Google policy. So the system we build is scoped to **direct-download channels**, with store channels explicitly no-op.

Unlike Electron (`electron-updater` bundles hosting + metadata + native install in one library), Flutter has no single equivalent. Best practice is **shared static hosting + a shared manifest + proven per-platform packages**, with a thin app-side coordinator.

## Goals / Non-Goals

**Goals:**

- Notify direct-download users of newer versions and help them install, on **Windows, macOS, Android sideload**.
- Single source of truth for "latest": one release → one feed pair (`appcast.xml` + `latest.json`) on `dl.enjoy.bot`.
- Reuse battle-tested packages (Sparkle/WinSparkle, Android install intent); avoid reinventing update logic.
- Support optional + mandatory (`minSupportedVersion`) prompts with snooze and SHA-256 verification.
- Be forward-compatible: flipping a `store`-flavor no-op into a soft store-nudge later requires no rework of the direct channel.

**Non-Goals:**

- No custom updater for iOS / Android Play in early days (platform owns it).
- No delta/staged-rollout updates in v1.
- No silent/background auto-install on mobile sideload (user confirmation required).
- No Linux auto-update (no `auto_updater` support; defer).
- No code push (Shorebird is a different problem; out of scope).

## Decisions

### 1. Channel split via build flavors (`store` vs `direct`), not runtime detection

The same Android OS hosts two channels (Play test vs sideload APK); reliably detecting "installed from Play?" at runtime is fragile. Instead, a **compile-time flavor** selects the update strategy.

- `store` → `NoOpUpdateStrategy` (TestFlight / Play test own updates; future App Store / Play prod).
- `direct` → appcast (desktop) / `latest.json` (Android sideload) against `dl.enjoy.bot`.

CI already emits distinct artifacts per platform; flavor adds a clean channel axis.
*Alternative considered:* runtime install-source sniffing (`InstallReferrer`, package installer name) — rejected as brittle and platform-specific.

### 2. Feed: Sparkle **appcast.xml** (desktop) + **latest.json** (Android sideload)

Desktop uses `auto_updater` (Sparkle/WinSparkle), which **requires** an appcast RSS feed. Android `ota_update` just needs a plain APK URL, so a small `latest.json` carries version, `minSupportedVersion`, per-ABI APK URLs, and SHA-256. Both are **generated in CI from the same tag** — two views, one truth.

```
https://dl.enjoy.bot/player/
├── appcast.xml          # desktop: auto_updater (+ optional upgrader)
├── latest.json          # android sideload: ota_update
└── 0.2.0/
    ├── EnjoyPlayerSetup-v0.2.0.exe
    ├── EnjoyPlayer-macOS-v0.2.0.zip
    └── EnjoyPlayer-v0.2.0-arm64-v8a.apk
```

Versioned folders are immutable (cache-forever, rollback-friendly); only the two feed files are overwritten + CDN-invalidated per release.
*Alternative considered:* a single custom JSON for all platforms — rejected because desktop auto_updater can't consume it; we'd lose native Sparkle UX/signing.

### 3. Per-platform package matrix

| Channel | Package | Role |
|---------|---------|------|
| Windows `direct` | `auto_updater` (WinSparkle) | check + download + install via appcast |
| macOS `direct` | `auto_updater` (Sparkle) | same appcast feed |
| Android sideload `direct` | `ota_update` | download APK + system install intent + progress |
| iOS / Play `store` | none (later: `upgrader`) | no-op early; soft store nudge in prod |

The app owns only an `UpdateService` (Riverpod) that: picks strategy by flavor+platform, runs check on startup (debounced) + manual, compares semver, enforces `minSupportedVersion`, and stores last-check / snooze-until in `settings_kv`. All native update mechanics are delegated.

### 4. UX policy

- **Optional** update → dismissible banner/dialog with notes; **snooze 24h** persisted in `settings_kv`. Never interrupt mid-playback; only when online.
- **Mandatory** (running version < `minSupportedVersion`) → blocking dialog, no dismiss. Reserved for security or destructive schema migrations (the discover ADR flagged destructive-migration risk).
- **Integrity** → SHA-256 from feed verified before install for direct downloads (mirrors the existing Windows FFmpeg checksum-verify pattern).
- One prompt per platform: desktop may use native Sparkle UI **or** a Flutter prompt, not both.

### 5. CI publishing

Each `release_*` workflow, after building + renaming artifacts, runs an `aws s3 sync` to `player/{version}/`, regenerates `appcast.xml` + `latest.json`, and invalidates the CDN manifest path. Signing (Authenticode, notarization, Sparkle ed signatures) happens **before** upload.

## Risks / Trade-offs

- **`auto_updater` + Inno Setup `.exe` on Windows** → WinSparkle expects specific installer/feed behavior; **spike** with the real `EnjoyPlayerSetup-vX.Y.Z.exe` before committing. macOS Sparkle + notarized zip is well-trodden.
- **Sparkle update signing (ed/EdDSA keys)** → new key to manage. Mitigation: store with existing release secrets; document in ADR/packaging alongside notarization.
- **`auto_updater` maintenance is "average" on pub.dev** → pin version; isolate behind our strategy interface so it can be swapped without touching callers.
- **Android sideload install UX** → user must allow "install unknown apps"; cannot be silent for non-system apps. Mitigation: clear in-app guidance; `ota_update` surfaces progress + errors.
- **Flavor proliferation** → adds `store`/`direct` variants across 4 platforms. Mitigation: keep flavor differences minimal (only update strategy + feed URL); reuse one entrypoint.
- **Stale `latest.json` cache** → users miss updates. Mitigation: short TTL / explicit CDN invalidation on the two feed files only.
- **iOS no-op feels like a gap** → acceptable: TestFlight already nags; revisit with a soft `upgrader` nudge at App Store launch.

## Migration Plan

1. Stand up `dl.enjoy.bot` (S3 + CDN, public read on `player/*`, short TTL on feeds).
2. Add `store`/`direct` flavors; default existing dev/run to `direct` for desktop, `store` for mobile test builds.
3. Land `UpdateService` + strategies behind the flavor switch (no-op safe default).
4. Extend one CI workflow (Windows first) to publish + generate feeds; verify the spike; then macOS and Android.
5. Document ADR + packaging update.

**Rollback:** the feature is additive and gated by flavor; reverting the app build (or shipping a `direct` build whose `UpdateService` is disabled via a kill-switch flag) restores prior behavior. Versioned folders are never deleted, so older installers remain available.

## Open Questions

- Do we add `store`/`direct` flavors now, or ship a single flavor with a runtime kill-switch until store prod launch?
- Sparkle signing: EdDSA per-platform keys, or reuse a single signing identity where possible?
- Android sideload ABI selection: app picks by device ABI from a `latest.json` map, or feed exposes a single arm64 build for v1?
- Should `store` builds show a passive "you're on TestFlight/Play test" info row, or stay fully silent?
