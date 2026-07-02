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

- **Library re-emit storms** (issue #13 → PR #56, merged) — `MediaLibraryRepository.watchAll()` re-emits on every Drift table change. Adds `==`/`hashCode` to `Media`, caches `lastEmitted` in the repo.

- **Library derived providers rebuild on no-op ticks** (issue #37 → PR #64, merged) — `libraryHomeRecentsProvider` (top-12 sort) and `libraryFilteredListsProvider` (filter + 2 × title sort) both produce new containers on every upstream emission. Adds `Stream<T>.distinctBy(equals)` extension in `lib/core/utils/stream_distinct.dart` + element-wise `Media.==` comparison.

- **Discover feed Drift re-emissions** (issues #46 / #47 → PR #65, merged) — `DiscoverRepository.watchSubscriptions()`, `watchTimeline()`, and `watchChannelFeed()` are pure `.map(...)` chains. Reuses the same `Stream<T>.distinctBy(equals)` extension with element-wise `FeedEntry.==` / `DiscoverChannel.==` comparison.

- **Recordings Drift re-emissions** (issue #79 → PR #79, merged) — `RecordingDao.watchByTarget()` and `RecordingDao.watchByEchoRegion()` pure Drift watch chains. Applies the same `Stream<T>.distinctBy(equals)` extension with element-wise `_listEqualsRecordingRow` compare helper. Reuses the `stream_distinct.dart` extension from #37.

- **Transcript lines provider re-decode** (issue #131 → PR #137, merged) — `_computeLines` now fetches only the active row by id (`transcriptDao.getById(activeId)`) instead of `listForTarget`, and the merged stream ends in `Stream.distinctBy(_listEqualsTranscriptLine)`. Saves a full timeline_json decode on every Drift tick.

- **Discover refresh fan-out** (already in main, prior round) — `refreshFeeds` runs `_kRefreshChannelConcurrency = 4` channel refreshes in parallel via `Future.wait`. 20-channel refresh is ~5 RTTs instead of 20. Bounded avatar LRU cache (`_kAvatarCacheCapacity = 256`) with move-to-end ordering.

- **Grid stable item keys + findChildIndexCallback** (PR #150, merged 2026-06-29) — `home_screen.dart`, `discover_screen.dart`, `channel_feed_screen.dart` now assign `ValueKey(entity.id)` to every row's `Align` wrapper and provide `findChildIndexCallback` to the `SliverChildBuilderDelegate` / `GridView.builder`. Lets the sliver framework re-use already-built `Element`s across reorders. New `lib/core/utils/sliver_key_index.dart` (`findSliverIndexByPrefixedId<T>`) centralises the prefix-key lookup.

- **Discover perf parent** (#106, closed) — `_enrichMissingDurations` semaphore at `_kEnrichDurationConcurrency = 4`, `List.unmodifiable` for entries, scheduler gated on `subs.isNotEmpty` + `AppLifecycleState.resumed`. All five sub-items addressed.

### Confirmed hot paths / opportunities

1. **Artwork palette extraction on main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`)
   - `PaletteGenerator.fromImageProvider` decodes + analyses pixels on the UI isolate.
   - `home_screen.dart` already documents that the grid uses `generativeAccentForSeed(coverSeed)` to avoid per-tile extraction.
   - Active player + transport bar still call `currentArtworkPaletteProvider` → `extractArtworkPalette`.
   - LRU cache (max 32) is in place, so revisit hits are free; the first extract for a fresh thumbnail is the cost.
   - **Investigation (this run, 2026-06-30)**: `palette_generator` 0.3.x has no isolate-safe API — call-graph does not expose an analysis-only path without a major version bump or writing our own quantization on raw pixels. Need maintainer sign-off per "no new dependencies without discussion" rule.
   - **Smaller concrete win (next round candidate)**: key the LRU on `path:stat.size:stat.millisecondsSinceEpoch` so thumbnail regeneration invalidates the cached palette instead of returning a stale entry. Smallest, safest-per-PR win on this backlog.

2. **API client JSON decode** (`lib/data/api/api_client.dart`) — `_decodeResponseBody` uses `compute(decodeJsonToCamel, raw)` for >48 KB responses. Small responses decode on the UI isolate.
   - **Audit (this run, 2026-06-30)**: per-list endpoints (`AudioApi.audios()`, `TranscriptApi.transcripts()`) are simple one-shots with no sequential fan-out of small JSONs. Threshold-based decode is correct as-is; no change.

3. **Dictations DAO has no `==`** — `DictationDao.watchByTarget` is not consumed today but if it gets used, it will need the same dedupe treatment.

4. **`recommendedChannelAvatar` provider** — `discover_providers.dart:158-180` does `ref.watch(discoverSubscriptionsProvider);` redundantly. Cosmetic.

### Investigation completed

- `_positionSub` / `_durationSub` in `PlayerController` — already bucketed to 400ms in `_subscribeStreams`.
- `youtube_player_engine.dart` poll-loop timer — confirmed `_stopPolling()` is called from `dispose()`, `idleAfterClear()`, `onWebViewDisposed()`, and the `ended` event.
- Issue #131 (transcript lines perf) — closed 2026-06-28 by PR #137.
- Issue #106 (Discover perf parent) — closed 2026-06-28 by `@an-lee`.

- **Artwork palette cache staleness** (this run, 2026-07-02) — PR draft `[perf-improver] perf(theme): key artwork palette LRU on path + size + mtime`. Switches the LRU key from `String` to a `(path, size, mtime)` record. Records have structural equality so no `==`/`hashCode` override needed. `_lookupFresh` walks the order list, drops stale entries for the same path whose stat tuple no longer matches the file's current `FileStat`, and promotes the live entry on hit. Added `ArtworkPalette` value equality (small win for any future `Map<ArtworkPalette, …>`) and 5 `@visibleForTesting` cache seams. 12 new unit tests: cache-key shape (encoding, size diff, mtime diff), cache hits, three flavours of invalidation, multi-path independence, value equality, no-decode / no-cache contract. Branch `perf-assist/artwork-palette-cache-invalidation`. Full `flutter test` 743 pass / 2 pre-existing skip.

## Run History (reverse chronological)

- 2026-07-02 15:30 UTC — run 28599784313 — drafted `[perf-improver] perf(theme): key artwork palette LRU on path + size + mtime`. Cache key switched from `String path` to record `(path, size, mtime)`. Lookup walks order list, drops stale entries, returns live entry. `ArtworkPalette` gains `==`/`hashCode`. 5 `@visibleForTesting` cache seams added. 12 new unit tests (cache-key encoding, hit, three invalidation paths, multi-path independence, value equality, no-decode / no-cache). Branch `perf-assist/artwork-palette-cache-invalidation`. `dart format` clean, `flutter analyze` clean, `flutter test` 743 pass / 2 pre-existing skip.
- 2026-06-30 15:30 UTC — run 28455287886 — investigation + Monthly Activity update only. Audited post-dedupe-wave state; PR #150 (grid stable keys) confirmed merged. Investigated artwork palette isolation feasibility (deferred — needs maintainer design decision). Audited audio/transcript list endpoints (no fan-out found). No new PR or comment.
- 2026-06-29 16:46 UTC — run 28387064065 — drafted `[perf-improver] perf(ui): stable item keys + findChildIndexCallback on home and discover grids`. New `lib/core/utils/sliver_key_index.dart` (`findSliverIndexByPrefixedId<T>`) + 10 unit tests. `ValueKey(entity.id)` on every grid row's `Align` wrapper across `home_screen.dart`, `discover_screen.dart`, `channel_feed_screen.dart` + matching `findChildIndexCallback` on the `SliverChildBuilderDelegate` / `GridView.builder`. +237 / −14 across 5 files. Branch: `perf-assist/grid-stable-keys-2026-06-29`. Merged 2026-06-29 as PR #150.
- 2026-06-28 22:47 UTC — run 28387064065 — opened PR #137 `[perf-improver] perf(transcript): dedupe identical transcript_lines_provider emissions and drop listForTarget scan`. Merged 2026-06-28 by @an-lee.
- 2026-06-27 14:30 UTC — run 28291742117 — drafted `[perf-improver] perf(recordings): dedupe identical watchByTarget / watchByEchoRegion emissions`. Reused the `Stream<T>.distinctBy(equals)` extension from #37 / #65. Element-wise `_listEqualsRecordingRow` compare helper. 9 new unit tests. +412/-2 across 2 files. Merged as PR #79.
- 2026-06-26 15:30 UTC — run 28247168356 — drafted `[perf-improver] perf(discover): dedupe identical watchSubscriptions / watchTimeline / watchChannelFeed emissions`. Reused the `Stream<T>.distinctBy(equals)` extension from issue #37. Added `==`/`hashCode` to `FeedEntry` and `DiscoverChannel`. 6 unit tests + 6 integration tests. +548/-9 across 6 files. → merged 2026-06-27 as PR #65.
- 2026-06-25 16:04 UTC — run 28181651032 — drafted `[perf-improver] perf(library): dedupe identical home/filter list emissions` (issue #37). New `Stream<T>.distinctBy(equals)` extension + element-wise dedupe on `libraryHomeRecentsProvider` and `libraryFilteredListsProvider`. 6 + 3 new tests. +385/-1 across 4 files. → merged as PR #64.
- 2026-06-23 15:58 UTC — run 28037649581 — opened draft PR `[perf-improver] perf(library): dedupe identical watchAll emissions` (issue #13). Media value-equality + per-listener emit dedupe + regression test. → merged as PR #56.
- 2026-06-22 14:37 UTC — run 27960568022 — initial discovery, no PR yet (commands not locally runnable).