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

Default filename: `EnjoyPlayer-diagnostics-<date>.zip`. User chooses save location via the platform file picker.

## Privacy

- Authorization headers, bearer tokens, and common cookie names are redacted before write.
- Long absolute paths are truncated to `.../<basename>`.
- Logs may include YouTube video IDs and media UUIDs needed for playback/sync debugging.
- Turn off diagnostic logging after collecting a report unless actively troubleshooting.

## YouTube stall warning

If YouTube page load completes (`load_stop`) but playback never reaches `first_playing` within 30 seconds, one **WARNING** is logged at default tier:

`youtube playback stalled after load_stop vid=<id>`

This surfaces release-only WebView stalls without enabling verbose mode.

## Related docs

- [ADR-0026](../decisions/0026-local-production-diagnostics.md) — local-only default, opt-in verbose
- [YouTube playback](youtube.md) — WebView engine and navigation policy
