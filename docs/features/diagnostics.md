# Production diagnostics

Local-only diagnostic logging and export for support handoff. Phase 1 does **not** upload logs to Enjoy servers.

## Default logging

- All builds write redacted logs to `{applicationSupport}/logs/enjoy-player.log`.
- Rotation: ~2 MB per file, keep 3 files (`enjoy-player.log`, `.1`, `.2`).
- Default level: **INFO** and above for all loggers.
- Each cold start writes a session header (version, platform, distribution channel, locale, verbose flag).

## Diagnostic logging toggle

Settings → About → **Diagnostic logging** (off by default).

When enabled, allowlisted loggers also persist **FINE** records:

- `YouTubePlayerEngine`, `YouTubeWebView` (and other `YouTube*` prefixes)
- `sync`, `api`, `auth`, `update`

Root level stays INFO for everything else to limit disk use.

## Export diagnostic report

Settings → About → **Export diagnostic report**.

Builds a zip containing:

- Rotated log files under `logs/`
- `manifest.json` (app version, build number, platform, distribution channel, build mode, export time, verbose flag, optional locale)

Default filename: `EnjoyPlayer-diagnostics-<date>.zip`. On iOS and Android, the system share sheet is used (save to Files, AirDrop, etc.). On desktop, the user chooses save location via the platform file picker.

## Privacy

- Authorization headers, bearer tokens, and common cookie names are redacted before write.
- Long absolute paths are truncated to `.../<basename>`.
- Logs may include YouTube video IDs and media UUIDs needed for playback/sync debugging.
- Turn off diagnostic logging after collecting a report unless actively troubleshooting.

## Framework error routing

`lib/main.dart` wraps the entire bootstrap in `runZonedGuarded(_bootstrap, _onZoneError)` and installs `FlutterError.onError` + `PlatformDispatcher.instance.onError` before running the app. This means widget-tree errors (`FlutterError.onError`), engine/platform-channel errors (`PlatformDispatcher.onError`), and any uncaught error in the bootstrap zone (`_onZoneError`) all funnel through the same `Log.named('bootstrap')` pipeline instead of crashing silently or only surfacing in the debug console. `FlutterError.onError` still calls `FlutterError.presentError` afterward, so the existing red error box / release banner behavior is unchanged — the handler adds logging, it does not suppress the error.

In a diagnostic zip (see **Export diagnostic report** above), look for `severe`-level `FlutterError:` or `PlatformDispatcher error` lines in the rotated log files to find a framework-level crash that a user reported.

## YouTube stall warning

If YouTube page load completes (`load_stop`) but playback never reaches `first_playing` within 30 seconds, one **WARNING** is logged at default tier:

`youtube playback stalled after load_stop vid=<id>`

This surfaces release-only WebView stalls without enabling verbose mode.

## Related docs

- [ADR-0026](../decisions/0026-local-production-diagnostics.md) — local-only default, opt-in verbose
- [YouTube playback](youtube.md) — WebView engine and navigation policy
