# ADR-0007 — Dynamic color from media artwork

**Status**: Accepted  
**Date**: 2026-05-09

## Context

The "Cinematic Editorial" design direction requires the player chrome, transport ring, transcript active-line, and ambient backdrop to reflect the dominant hue of the currently playing media's artwork. This creates an immersive, content-driven experience akin to Apple Music and Spotify.

## Decision

Use `package:palette_generator` to extract a dominant swatch and a vibrant accent from the local thumbnail file on demand. Results are cached in memory in an **LRU-bounded in-process cache** (cap = 32) keyed by `(path, size, mtime)` so repeated extractions are free *and* a re-thumbnailed or re-encoded artwork file invalidates the cached palette instead of masking the stale result. Lookup walks the LRU order list, evicts any entry for the same path whose `(size, mtime)` no longer matches the file's stat, and returns the matching live entry when one exists. The palette is exposed as `@riverpod` providers: `currentArtworkPaletteProvider` (active player) and `artworkPaletteProvider(path)` (arbitrary path). Both return a nullable `ArtworkPalette`, which has value-equality on its four `Color` fields.

Consumers apply the palette as an overlay/tint (never as a hard surface replacement) so that the app remains coherent when no artwork is available (falls back to theme primary).

## Consequences

- Adds `palette_generator` dependency.
- Extraction runs on an `Isolate` via the package — does not block the UI thread.
- Discontinued package notice accepted (no maintained alternative with equivalent API in 2026; can be replaced with custom FFI extraction later).
- Dynamic color only applies to player surfaces; library/home/settings always use the static brand amber.
- LRU cache invalidates on `(size, mtime)` change, not on path alone — re-thumbnailing or rewriting the file in place is enough to force a fresh extraction. `@visibleForTesting` seams (`debugResetArtworkPaletteCache`, `debugArtworkPaletteCacheSize`, `debugArtworkPaletteCacheContainsPath`, `debugLookupArtworkPalette`, `debugPutArtworkPalette`) expose the cache for tests; production code must not call them.
