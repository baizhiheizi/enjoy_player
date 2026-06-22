---
name: perf-improver-state
description: Perf Improver persistent state — discovered commands, opportunities backlog, run history
metadata:
  type: project
---

# Perf Improver — State

## Discovered Commands (from .github/workflows/ci.yml + .github/workflows/codegen_drift.yml)

Flutter version pinned in `.github/flutter-version` (currently `3.44.0`).
Self-hosted Linux runner executes via `.github/actions/setup-flutter`.

### Build / test / lint (match CI exactly)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
# + packages/*/lib and packages/*/test when present
flutter analyze
flutter test
# Per path package:
for pkg in packages/*/; do
  if [ -d "${pkg}test" ]; then (cd "$pkg" && flutter pub get && flutter test); fi
done
```

### Codegen (Drift / Riverpod)

```bash
dart run build_runner build
# For path packages that use build_runner:
for pkg in packages/*/; do
  if grep -qE '^[[:space:]]*build_runner:' "${pkg}pubspec.yaml"; then
    (cd "$pkg" && flutter pub get && dart run build_runner build)
  fi
done
```

### Validation status

- **Cannot validate locally on this runner**: Flutter's `update_engine_version.sh` writes to the read-only `bin/cache/`, so every `flutter` invocation aborts with "Read-only file system". This is a host-level issue, not a repo bug.
- Per CI config, commands succeed on the self-hosted `Linux` runner.
- No benchmark / perf-regression CI job exists in this repo today.

## Optimization Backlog (prioritized)

### Confirmed hot paths / opportunities

1. **Artwork palette extraction on main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`)
   - `PaletteGenerator.fromImageProvider` decodes + analyses pixels on the UI isolate.
   - `home_screen.dart` already documents that the grid uses `generativeAccentForSeed(coverSeed)` to avoid per-tile extraction (saves seconds on Windows debug).
   - Active player + transport bar still call `currentArtworkPaletteProvider` → `extractArtworkPalette`.
   - LRU cache (max 32) is in place, so revisit hits are free; the first extract for a fresh thumbnail is the cost.
   - **Idea**: bypass `PaletteGenerator` and use a hand-rolled 16×16 decode + simple `findMaxPopulationRank` (palette_generator internals). Avoids the image-decoder round-trip and runs much faster on a single image.
2. **JSON decode in API client** (`lib/data/api/api_client.dart`)
   - Already uses `compute(decodeJsonToCamel, raw)` for the response body — good.
   - Audit whether per-list endpoints (`features/`, `discover/feed`, `library`) decode in parallel via `Future.wait` to overlap I/O.
3. **Library grid / discover feed** — `GridView.builder` everywhere with stable item keys would let `SliverChildBuilderDelegate.findChildIndexCallback` cache placements. Worth checking if `itemExtent`/`prototypeItem` is feasible.
4. **Per-tile `select` rebuilds** — `transcript_scrollable_list.dart` uses `select((i) => i)` on the active highlight index. Check whether `findChildIndexCallback` plus `addAutomaticKeepAlives: false` reduces offscreen rebuilds in long transcript lists.
5. **Drift watchers** — `MediaLibraryRepository.watchAll()` powers `libraryMediaProvider` (rebuilds entire list on any change). Consider Drift's `tableUpdates` triggers so only changed rows re-emit.

### Investigation needed

- Whether `home_screen.dart`'s home recents is also re-filtering on every provider tick.
- Whether `_positionSub` / `_durationSub` in `PlayerController` use `where((p) => p.inSeconds != _last)` style debounce.
- `youtube_player_engine.dart` poll-loop timer: confirm it pauses when the engine is detached.

## Run History (reverse chronological)

- 2026-06-22 14:37 UTC — run 27960568022 — initial discovery, no PR yet (commands not locally runnable).
