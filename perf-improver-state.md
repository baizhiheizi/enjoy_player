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
- No benchmark / perf-regression CI job exists in this repo today — measurement infrastructure is a follow-up gap.

## Optimization Backlog (prioritized)

### Addressed

- **Library re-emit storms** (PR #13, 2026-06-23) — `MediaLibraryRepository.watchAll()` re-emits on every Drift table change. Landed draft `[perf-improver] perf(library): dedupe identical watchAll emissions`. Adds `==`/`hashCode` to `Media`, caches `lastEmitted` in the repo, regression test in `library_repository_test.dart`.

- **Library derived providers rebuild on no-op ticks** (PR draft, 2026-06-25) — `libraryHomeRecentsProvider` (top-12 sort) and `libraryFilteredListsProvider` (filter + 2 × title sort) both produce new containers on every upstream emission. Even with the merged-list dedupe from PR #13, a real change to a non-recent row produces a different merged list but identical derived lists, causing redundant rebuilds. New `Stream<T>.distinctBy(equals)` extension in `lib/core/utils/stream_distinct.dart` is applied to both providers with element-wise `Media.==` comparison. New regression tests in `test/core/utils/stream_distinct_test.dart` (6 unit tests) + `test/features/library/library_media_provider_test.dart` (3 integration tests with in-memory Drift). Branch: `perf-assist/library-provider-dedupe-2026-06-25` (patch saved at `/tmp/gh-aw/aw-perf-assist-library-provider-dedupe-2026-06-25.patch`).

### Confirmed hot paths / opportunities

1. **Artwork palette extraction on main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`)
   - `PaletteGenerator.fromImageProvider` decodes + analyses pixels on the UI isolate.
   - `home_screen.dart` already documents that the grid uses `generativeAccentForSeed(coverSeed)` to avoid per-tile extraction.
   - Active player + transport bar still call `currentArtworkPaletteProvider` → `extractArtworkPalette`.
   - LRU cache (max 32) is in place, so revisit hits are free; the first extract for a fresh thumbnail is the cost.
   - **Idea**: hand-rolled 16×16 decode + simple `findMaxPopulationRank`. Avoids the image-decoder round-trip.

2. **JSON decode in API client** (`lib/data/api/api_client.dart`)
   - Already uses `compute(decodeJsonToCamel, raw)` for the response body — good.
   - Audit whether per-list endpoints (`features/`, `discover/feed`, `library`) decode in parallel via `Future.wait` to overlap I/O.

3. **Discover feed Drift re-emissions** (`lib/features/discover/data/discover_repository.dart`)
   - `watchTimeline()` and `watchChannelFeed()` are pure Drift `.map(...)` chains; a single duration enrichment write causes the entire timeline to re-emit.
   - The new `Stream<T>.distinctBy(...)` extension is now reusable here.

4. **Library grid / discover feed** — `GridView.builder` everywhere with stable item keys would let `SliverChildBuilderDelegate.findChildIndexCallback` cache placements. Worth checking if `itemExtent`/`prototypeItem` is feasible.

5. **Per-tile `select` rebuilds** — `transcript_scrollable_list.dart` uses `select((i) => i)` on the active highlight index. Check whether `findChildIndexCallback` plus `addAutomaticKeepAlives: false` reduces offscreen rebuilds in long transcript lists.

### Investigation needed

- Whether `home_screen.dart`'s home recents is also re-filtering on every provider tick. (Addressed by PR draft 2026-06-25: `libraryHomeRecentsProvider` now dedupes.)
- Whether `_positionSub` / `_durationSub` in `PlayerController` use `where((p) => p.inSeconds != _last)` style debounce. (Confirmed: position is already bucketed to 400ms in `_subscribeStreams`.)
- `youtube_player_engine.dart` poll-loop timer: confirm it pauses when the engine is detached. (Confirmed: `_stopPolling()` is called from `dispose()`, `idleAfterClear()`, `onWebViewDisposed()`, and the `ended` event.)

## Run History (reverse chronological)

- 2026-06-25 16:04 UTC — run 28181651032 — drafted `[perf-improver] perf(library): dedupe identical home/filter list emissions` (new `Stream<T>.distinctBy` extension + element-wise dedupe on `libraryHomeRecentsProvider` and `libraryFilteredListsProvider`; 6 + 3 new tests; +385/-1 lines across 4 files). Patch + bundle saved via safe-outputs. Will update issue #14 once MCP propagation lands.
- 2026-06-23 15:58 UTC — run 28037649581 — opened draft PR `[perf-improver] perf(library): dedupe identical watchAll emissions` (Media value-equality + per-listener emit dedupe + regression test). Updated monthly activity issue for 2026-06.
- 2026-06-22 14:37 UTC — run 27960568022 — initial discovery, no PR yet (commands not locally runnable).
