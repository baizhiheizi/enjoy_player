# Feature: App updates (direct distribution)

## Summary

Enjoy Player distributes **direct** updates (not via a store) on **Windows**, **macOS**, and **Android sideload** (`direct` flavor). Store-channel builds (Play / TestFlight) use a **NoOp** strategy — the store owns updates. The flow fetches a remote **version manifest**, compares against the running version, and either **silently logs up-to-date**, shows an **optional** prompt, or blocks on a **mandatory** update. Snooze is honored until a per-release deadline.

## Channel split

| Channel | Platforms | Strategy |
|---------|-----------|----------|
| Direct | Windows, macOS, Android sideload | `DirectUpdateStrategy` — fetches the remote `latest.json`, evaluates, prompts; installs via Sparkle/WinSparkle (desktop) or `ota_update` (Android). |
| Store | iOS, Android Play | `NoOpUpdateStrategy` — store handles updates; we don't prompt. |

The channel is resolved by `DISTRIBUTION_CHANNEL` env / build flag (see [ADR-0023](../decisions/0023-app-update-distribution.md)). Android product flavors are `store` / `direct`.

## Manifest schema

`latest.json` is fetched from the project's CDN; the schema is parsed by `version_manifest_repository.dart` into a `ReleaseManifest`:

```json
{
  "version": "0.2.4",
  "build": 5,
  "minSupportedVersion": "0.2.0",
  "notes": "...",
  "assets": {
    "windows": { "url": "...", "sha256": "...", "file": "EnjoyPlayer-0.2.4.exe" },
    "macos":   { "url": "...", "sha256": "...", "file": "EnjoyPlayer-0.2.4.dmg" },
    "android_arm64_v8a": { "url": "...", "sha256": "...", "file": "EnjoyPlayer-v0.2.4-arm64-v8a.apk" }
  }
}
```

`checksum_verifier.dart` normalizes SHA-256 hex from the feed. On Android, the normalized digest is passed to `ota_update` as `sha256checksum` so the plugin verifies the APK before opening the installer.

## Evaluator rules (`UpdateEvaluator.evaluateUpdate`)

- If `currentVersion >= manifest.version` → `upToDate`.
- Else if `currentVersion < manifest.minSupportedVersion` → `mandatoryUpdate`.
- Else if `snoozedVersion == manifest.version` and `clock < snoozeUntil` → `upToDate`.
- Else → `updateAvailable`.

`semver_compare.dart` provides `isVersionLessThan` (numeric component compare, ignoring pre-release tags; matches web `semverLessThan`).

## Prompt UX

`update_prompt_dialog.dart` is rendered by `update_prompt_host.dart` from inside the app shell (not a separate route), so it floats above whatever is on screen:

- **Optional**: **Update now** / **Later** / **Dismiss**. Later snoozes for 24h (`SettingsKeys.updateSnoozeUntil` + `updateSnoozeVersion`).
- **Mandatory**: **Update now** is the only available action; the dialog blocks interaction until the user accepts (barrier and back are disabled).

### Android download progress (direct flavor)

Tapping **Update now** does **not** dismiss the dialog. The prompt immediately shows:

1. **Preparing download…** (indeterminate)
2. **Downloading update… N%** with a determinate progress bar
3. **Verifying download…** (when a feed SHA-256 is present)
4. **Opening installer…** then the dialog closes as the system package installer appears

During download the user can **Cancel**:

- **Optional**: cancels the transfer and closes the prompt.
- **Mandatory**: cancels the transfer but returns to the still-blocking update prompt so the user can retry.

Failures stay inline with a localized message and **Retry** (download, checksum, permission, already-running, installation, generic). There is no system notification / background download service — the modal is the progress surface.

Desktop direct updates still hand off to Sparkle / WinSparkle (native UI) after a short preparing state.

## Android APK selection

`DirectUpdateStrategy` asks `ota_update` for the device ABI (`getAbi`) and prefers matching feed keys such as `android_arm64_v8a`, `android_armeabi_v7a`, or `android_x86_64`, then falls back to generic `android*` assets.

## Failure modes

- **Manifest fetch fails** → swallow the error (logged) on startup. Manual check shows an offline error notice. The next app launch retries (subject to the 24h startup debounce).
- **Checksum mismatch** → plugin aborts install; the prompt shows a checksum error with **Retry**.
- **Install permission denied** → prompt shows permission guidance with **Retry**.
- **Download / install handoff fails** → inline error + **Retry**; optional prompt can still use Later.
- **Out-of-date without mandatory** → Later (snooze) or Dismiss; next startup may re-prompt after snooze expires.

## Code map

| Area | Path |
|------|------|
| Manifest repository | [`lib/features/update/data/version_manifest_repository.dart`](../../lib/features/update/data/version_manifest_repository.dart) |
| Checksum verifier | [`lib/features/update/data/checksum_verifier.dart`](../../lib/features/update/data/checksum_verifier.dart) |
| Evaluator | [`lib/features/update/application/update_evaluator.dart`](../../lib/features/update/application/update_evaluator.dart) |
| Direct strategy | [`lib/features/update/application/direct_update_strategy.dart`](../../lib/features/update/application/direct_update_strategy.dart) |
| No-op strategy | [`lib/features/update/application/noop_update_strategy.dart`](../../lib/features/update/application/noop_update_strategy.dart) |
| Controller | [`lib/features/update/application/update_controller.dart`](../../lib/features/update/application/update_controller.dart) |
| Prompt UI | [`lib/features/update/presentation/update_prompt_dialog.dart`](../../lib/features/update/presentation/update_prompt_dialog.dart) |
| Prompt host | [`lib/features/update/presentation/update_prompt_host.dart`](../../lib/features/update/presentation/update_prompt_host.dart) |

## Related

- ADR: [`docs/decisions/0023-app-update-distribution.md`](../decisions/0023-app-update-distribution.md)
- Production diagnostics: [`docs/features/diagnostics.md`](diagnostics.md) (update failures feed diagnostic log)
- Packaging: [`docs/packaging.md`](../packaging.md)

## Manual verification (Android direct)

On a device/emulator with a `direct` flavor build and a reachable `latest.json`:

1. Trigger update (startup prompt or Settings → Check for updates).
2. Tap **Update now** — preparing state appears within ~100ms (no silent hang).
3. With network throttling, confirm percentage advances and Cancel works (optional closes; mandatory returns to Update now).
4. Confirm checksum failures / offline download failures show Retry.
5. On success, system installer opens and the in-app dialog dismisses.
6. On a non-arm64 ABI emulator (when a matching APK is published), confirm the ABI-specific asset is chosen.
