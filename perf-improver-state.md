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

### Local SDK on agentic runner

- The host copy at `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/flutter` is read-only (the SDK's `update_engine_version.sh` writes to `bin/cache/`).
- The runner copies it to `/tmp/flutter_sdk/flutter/` so `flutter pub get` / `flutter test` / `flutter analyze` can write.
- `export PATH="/tmp/flutter_sdk/flutter/bin:$PATH"` is enough to make the rest of the workflow go.

### Validation status

- **Per CI config, commands succeed on the self-hosted `Linux` runner** AND on the agentic runner once the SDK is copied.
- No benchmark / perf-regression CI job exists in this repo today — measurement infrastructure is a follow-up gap.
- 1 pre-existing test failure on the agentic runner: `extractEntireFileMonoF32 returns null when media file is missing` throws `MissingPluginException(No implementation found for method getLogLevel on channel flutter.arthenica.com/ffmpeg_kit)` because `ffmpeg_kit_flutter_new` has no native Linux implementation. Unrelated to any perf-improver work; leave alone.

### Git push from this agentic runner

- `git push` requires credentials that are intentionally not available. Branch + commit are produced locally; safe-outputs `create_pull_request` and `create_issue` save the patch/bundle under `/tmp/gh-aw/aw-*.patch` and `/tmp/gh-aw/aw-*.bundle` for the workflow's post-processing step.

## Optimization Backlog (prioritized)

### Addressed

- **Library re-emit storms** (issue #13, PR-draft, 2026-06-23) — `MediaLibraryRepository.watchAll()` re-emits on every Drift table change. Adds `==`/`hashCode` to `Media`, caches `lastEmitted` in the repo. Branch: `perf-assist/library-watchall-dedupe-80208220c381b787` (merged as #56).

- **Library derived providers rebuild on no-op ticks** (issue #37, 2026-06-25) — `libraryHomeRecentsProvider` (top-12 sort) and `libraryFilteredListsProvider` (filter + 2 × title sort) both produce new containers on every upstream emission. Adds `Stream<T>.distinctBy(equals)` extension in `lib/core/utils/stream_distinct.dart` + element-wise `Media.==` comparison. Branch: `perf-assist/library-provider-dedupe-2026-06-25-dec50df573b5f428` (merged as #64).

- **Discover feed Drift re-emissions** (2026-06-26) — `DiscoverRepository.watchSubscriptions()`, `watchTimeline()`, and `watchChannelFeed()` are pure `.map(...)` chains. Reuses the same `Stream<T>.distinctBy(equals)` extension with element-wise `FeedEntry.==` / `DiscoverChannel.==` comparison. Branch: `perf-assist/discover-feed-dedupe-2026-06-26` (merged as #65).

- **Recordings Drift re-emissions** (2026-06-27) — `RecordingDao.watchByTarget()` and `RecordingDao.watchByEchoRegion()` pure Drift watch chains. Applies the same `Stream<T>.distinctBy(equals)` extension with element-wise `_listEqualsRecordingRow` compare helper. Reuses the `stream_distinct.dart` extension from #37. Branch: `perf-assist/recording-watch-dedupe-2026-06-27` (local commit; PR went via patch).

- **Transcript lines provider re-decode** (PR #137, merged 2026-06-28) — `_computeLines` now fetches only the active row by id (`transcriptDao.getById(activeId)`) instead of `listForTarget`, and the merged stream ends in `Stream.distinctBy(_listEqualsTranscriptLine)`. Saves a full timeline_json decode on every Drift tick.

- **Discover refresh fan-out** (already in main, prior round) — `refreshFeeds` runs `_kRefreshChannelConcurrency = 4` channel refreshes in parallel via `Future.wait`. 20-channel refresh is ~5 RTTs instead of 20.

- **Grid stable item keys + findChildIndexCallback** (this run, 2026-06-29) — `home_screen.dart`, `discover_screen.dart`, `channel_feed_screen.dart` now assign `ValueKey(entity.id)` to every row's `Align` wrapper and provide `findChildIndexCallback` to the `SliverChildBuilderDelegate` / `GridView.builder`. Lets the sliver framework re-use already-built `Element`s across reorders. New `lib/core/utils/sliver_key_index.dart` (`findSliverIndexByPrefixedId<T>`) centralises the prefix-key lookup. Branch: `perf-assist/grid-stable-keys-2026-06-29`. PR opened.

### Confirmed hot paths / opportunities

1. **Artwork palette extraction on main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`)
   - `PaletteGenerator.fromImageProvider` decodes + analyses pixels on the UI isolate.
   - `home_screen.dart` already documents that the grid uses `generativeAccentForSeed(coverSeed)` to avoid per-tile extraction.
   - Active player + transport bar still call `currentArtworkPaletteProvider` → `extractArtworkPalette`.
   - LRU cache (max 32) is in place, so revisit hits are free; the first extract for a fresh thumbnail is the cost.
   - **Idea**: read file bytes on the main isolate, `compute()` the `PaletteGenerator` work to a worker isolate. `palette_generator` 0.3.x predates isolate support so the call itself must move.

2. **JSON decode in API client** (`lib/data/api/api_client.dart`)
   - Already uses `compute(decodeJsonToCamel, raw)` for the response body when raw length > 48 KB.
   - Small responses (<48 KB) still decode on the UI isolate. For per-list endpoints that fan out many small JSONs in sequence, this is suboptimal.
   - Audit: are there any per-list endpoints that decode in parallel via `Future.wait`? (Look for `_sendMap` chains in `lib/data/api/services/*_api.dart`.)

3. **Per-tile `select` rebuilds** — `transcript_scrollable_list.dart` uses `select((i) => i)` on the active highlight index. Already tuned (ValueKey on items, scroll key caching, scroll-cache-extent pixels). Probably a wash at this point.

4. **Dictations DAO has no `==`** — `DictationDao.watchByTarget` is not consumed today but if it gets used, it will need the same dedupe treatment.

### Investigation needed

- Whether `_positionSub` / `_durationSub` in `PlayerController` use `where((p) => p.inSeconds != _last)` style debounce. (Confirmed earlier: position is already bucketed to 400ms in `_subscribeStreams`.)
- `youtube_player_engine.dart` poll-loop timer: confirm it pauses when the engine is detached. (Confirmed earlier: `_stopPolling()` is called from `dispose()`, `idleAfterClear()`, `onWebViewDisposed()`, and the `ended` event.)

## Run History (reverse chronological)

- 2026-06-29 16:46 UTC — run 28387064065 — drafted `[perf-improver] perf(ui): stable item keys + findChildIndexCallback on home and discover grids`. New `lib/core/utils/sliver_key_index.dart` (`findSliverIndexByPrefixedId<T>`) + 10 unit tests. `ValueKey(entity.id)` on every grid row's `Align` wrapper across `home_screen.dart`, `discover_screen.dart`, `channel_feed_screen.dart` + matching `findChildIndexCallback` on the `SliverChildBuilderDelegate` / `GridView.builder`. +237 / −14 across 5 files. Branch: `perf-assist/grid-stable-keys-2026-06-29`. Patch at `/tmp/gh-aw/aw-perf-assist-grid-stable-keys-2026-06-29.patch` (16,041 bytes / 392 lines).
- 2026-06-28 22:47 UTC — run 28387064065 — opened PR #137 `[perf-improver] perf(transcript): dedupe identical transcript_lines_provider emissions and drop listForTarget scan`. Merged 2026-06-28 by @an-lee.
- 2026-06-27 14:30 UTC — run 28291742117 — drafted `[perf-improver] perf(recordings): dedupe identical watchByTarget / watchByEchoRegion emissions`. Reused the `Stream<T>.distinctBy(equals)` extension from #37 / #65. Element-wise `_listEqualsRecordingRow` compare helper. 9 new unit tests. +412/-2 across 2 files.
- 2026-06-26 15:30 UTC — run 28247168356 — drafted `[perf-improver] perf(discover): dedupe identical watchSubscriptions / watchTimeline / watchChannelFeed emissions`. Reused the `Stream<T>.distinctBy(equals)` extension from issue #37. Added `==`/`hashCode` to `FeedEntry` and `DiscoverChannel`. 6 unit tests + 6 integration tests. +548/-9 across 6 files. → merged 2026-06-27 as #65.
- 2026-06-25 16:04 UTC — run 28181651032 — drafted `[perf-improver] perf(library): dedupe identical home/filter list emissions` (issue #37). New `Stream<T>.distinctBy(equals)` extension + element-wise dedupe on `libraryHomeRecentsProvider` and `libraryFilteredListsProvider`. 6 + 3 new tests. +385/-1 across 4 files.
- 2026-06-23 15:58 UTC — run 28037649581 — opened draft PR `[perf-improver] perf(library): dedupe identical watchAll emissions` (issue #13). Media value-equality + per-listener emit dedupe + regression test.
- 2026-06-22 14:37 UTC — run 27960568022 — initial discovery, no PR yet (commands not locally runnable).