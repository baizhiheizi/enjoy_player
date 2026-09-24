# ADR-0003: media_kit as sole player engine

## Status

Accepted

> **Wording refresh** (issue #751, post-#720): contract wording updated to the
> current engine seam — the `Player` instance lives in `MediaKitPlayerEngine`,
> and `PlayerEngine` is transport + streams + swap-lifecycle only. **No
> decision change.**

## Context

We need reliable cross-platform A/V playback (Android, iOS, Windows, macOS) with a single API surface and good codec coverage.

## Decision

Use **media_kit** + **media_kit_video** + **media_kit_libs_video**. Instantiate **one** `Player`, owned by **`MediaKitPlayerEngine`** — the only code that may construct `package:media_kit`'s `Player()` — and expose its `VideoController` to the video stage the surface host mounts.

## Scope

The single-`Player` rule applies to **lesson playback** (`MediaKitPlayerEngine`, driven by `PlayerController` through the `PlayerEngine` seam). A **second** `media_kit` `Player` used only for **shadow-reading take previews** is allowed — see `lib/core/audio/recording_preview_player.dart` — so previews never replace the loaded lesson media.

## Consequences

- YouTube and other web-only sources are **out of scope** for this engine (handled later with `flutter_inappwebview`, separate ADR).
- Volume is mapped from 0–1 app settings to 0–100 `media_kit` API.
- `PlayerEngine` itself carries **transport + streams + swap-lifecycle only** (issue #720): subtitles (`SubtitleTrackControl`) and poster capture (`PosterCapture`) are capability interfaces in `player_engine_capabilities.dart`, not contract members. Stage mounting stays with the permanent `PlayerSurfaceHost` per [ADR-0057](0057-permanent-player-surface-host.md); which engine is live resolves through the single `PlayerEngineIdentity` precedence (issue #751).
