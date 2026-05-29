## 1. Spikes & decisions (de-risk before building)

- [ ] 1.1 Spike `auto_updater` (WinSparkle) against the real `EnjoyPlayerSetup-vX.Y.Z.exe` Inno installer; confirm appcast-driven install works
- [ ] 1.2 Spike `auto_updater` (Sparkle) against the notarized macOS `.zip`; confirm update + relaunch
- [x] 1.3 Decide flavor vs runtime kill-switch (resolve design Open Question) and record in ADR
- [x] 1.4 Decide Sparkle update-signing key strategy (EdDSA) and Android ABI selection policy

## 2. Distribution infrastructure (`dl.enjoy.bot`)

- [ ] 2.1 Provision S3 bucket + CDN for `dl.enjoy.bot`, public read on `player/*`, short TTL on feed files
- [x] 2.2 Define `latest.json` schema (version, build, minSupportedVersion, notes, assets{url, sha256})
- [x] 2.3 Define `appcast.xml` template (macOS + Windows items, version, enclosure URL, signature)
- [x] 2.4 Add a feed-generation script that emits `appcast.xml` + `latest.json` from a release's renamed artifacts + checksums

## 3. CI publishing

- [x] 3.1 Add S3 upload + feed-generation + CDN-invalidation step to `release_windows.yml`
- [x] 3.2 Add the same step to `release_apple.yml` (macOS notarized zip) and Android sideload APK path
- [ ] 3.3 Inject Sparkle signing into the desktop release flow (after Authenticode/notarization, before upload)
- [ ] 3.4 Verify a dry-run tagged release publishes immutable `player/<version>/` + overwritten feeds

## 4. Build flavors

- [x] 4.1 Add `store` and `direct` flavors for Android (and dart-define / config for desktop)
- [x] 4.2 Wire iOS/macOS schemes and Windows config to the flavor axis
- [x] 4.3 Default dev/run: desktop → `direct`, mobile test builds → `store`
- [x] 4.4 Expose the active flavor + feed base URL to the app (constant in `app_links.dart`)

## 5. Domain & data layer

- [x] 5.1 Add domain models: `AppRelease`, `PlatformAsset`, `UpdateSeverity` (optional/mandatory), `UpdateCheckResult`
- [x] 5.2 Add semver comparison + `minSupportedVersion` evaluation (UI-free, unit-testable)
- [x] 5.3 Add `VersionManifestRepository` (fetch + parse `latest.json`; HTTP via existing client)
- [x] 5.4 Add `settings_kv` keys for last-check timestamp and snooze-until; reuse `Log` (no `print`)

## 6. Update strategies (delegated, behind one interface)

- [x] 6.1 Define `UpdateStrategy` interface (checkLatest, presentAndInstall)
- [x] 6.2 Implement `NoOpUpdateStrategy` for `store` flavor
- [x] 6.3 Implement desktop strategy via `auto_updater` (setFeedURL appcast + checkForUpdates)
- [x] 6.4 Implement Android sideload strategy via `ota_update` (download + install + SHA-256 verify + progress)
- [x] 6.5 Add SHA-256 verification helper for direct downloads (abort on mismatch)

## 7. Application & presentation

- [x] 7.1 Add `UpdateService` Riverpod notifier: pick strategy by flavor+platform, run debounced startup check + manual
- [x] 7.2 Implement optional-update prompt (dismiss / snooze 24h / update now) with release notes
- [x] 7.3 Implement mandatory-update blocking dialog (no dismiss/snooze) when below `minSupportedVersion`
- [x] 7.4 Add "Check for updates" entry + result feedback to the About/Settings card; wire `go_router` navigatorKey if using a prompt widget
- [x] 7.5 Add l10n strings (en + zh) for all update UI; guard against mid-playback / offline prompting

## 8. Verification & docs

- [x] 8.1 Unit tests: semver compare, min-version floor, snooze logic, manifest parsing, checksum verify
- [ ] 8.2 Manual end-to-end: Windows installer update, macOS zip update, Android sideload APK update against a staging bucket
- [ ] 8.3 Confirm `store` builds perform no custom update action (TestFlight / Play test verified)
- [x] 8.4 Write ADR (update channels + feed schema + flavors) and link from `docs/decisions/README.md`
- [x] 8.5 Update `docs/packaging.md` with the publish step and how users get notified
- [x] 8.6 Run `dart format`, `flutter analyze`, `flutter test`
