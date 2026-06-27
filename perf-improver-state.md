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
- The runner copies it to `/tmp/flutter_sdk/` so `flutter pub get` / `flutter test` / `flutter analyze` can write.
- `export PATH="/tmp/flutter_sdk/bin:$PATH"` is enough to make the rest of the workflow go.

### Validation status

- **Per CI config, commands succeed on the self-hosted `Linux` runner** AND on the agentic runner once the SDK is copied (this run: `flutter test` 473/475 pass; 2 pre-existing failures on main are unchanged from prior runs).
- No benchmark / perf-regression CI job exists in this repo today — measurement infrastructure is a follow-up gap.

### Git push from this agentic runner

- `git push` requires credentials that are intentionally not available. Branch + commit are produced locally; safe-outputs `create_pull_request` and `create_issue` save the patch/bundle under `/tmp/gh-aw/aw-*.patch` and `/tmp/gh-aw/aw-*.bundle` for the workflow's post-processing step.

## Optimization Backlog (prioritized)

### Addressed

- **Library re-emit storms** (issue #13, PR-draft, 2026-06-23) — `MediaLibraryRepository.watchAll()` re-emits on every Drift table change. Adds `==`/`hashCode` to `Media`, caches `lastEmitted` in the repo. Branch: `perf-assist/library-watchall-dedupe-80208220c381b787` (on origin, merged).

- **Library derived providers rebuild on no-op ticks** (issue #37, PR-draft, 2026-06-25) — `libraryHomeRecentsProvider` (top-12 sort) and `libraryFilteredListsProvider` (filter + 2 × title sort) both produce new containers on every upstream emission. Adds `Stream<T>.distinctBy(equals)` extension in `lib/core/utils/stream_distinct.dart` + element-wise `Media.==` comparison. Branch: `perf-assist/library-provider-dedupe-2026-06-25-dec50df573b5f428` (merged).

- **Discover feed Drift re-emissions** (2026-06-26) — `DiscoverRepository.watchSubscriptions()`, `watchTimeline()`, and `watchChannelFeed()` are pure `.map(...)` chains that re-emit on every Drift table change. The same `Stream<T>.distinctBy(equals)` extension is applied with element-wise `FeedEntry.==` / `DiscoverChannel.==` comparison. Adds value-equality to `FeedEntry` and `DiscoverChannel`. Branch: `perf-assist/discover-feed-dedupe-2026-06-26` (merged as #65).

- **Recordings Drift re-emissions** (this run, 2026-06-27) — `RecordingDao.watchByTarget()` (used by `recordingsForTargetProvider` in `transcript_line_recording_counts_provider` + `share_practice_poster_button`) and `RecordingDao.watchByEchoRegion()` (used by `shadow_reading_panel`'s raw `StreamBuilder`) are pure Drift watch chains. Apply the same `Stream<T>.distinctBy(equals)` extension with element-wise `_listEqualsRecordingRow` compare helper. Reuses the `stream_distinct.dart` extension from #37. Branch: `perf-assist/recording-watch-dedupe-2026-06-27` (local commit; patch at `/tmp/gh-aw/aw-perf-assist-recording-watch-dedupe-2026-06-27.patch`).

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

3. **Library grid / discover feed** — `GridView.builder` everywhere with stable item keys would let `SliverChildBuilderDelegate.findChildIndexCallback` cache placements. Worth checking if `itemExtent`/`prototypeItem` is feasible.

4. **Per-tile `select` rebuilds** — `transcript_scrollable_list.dart` uses `select((i) => i)` on the active highlight index. Check whether `findChildIndexCallback` plus `addAutomaticKeepAlives: false` reduces offscreen rebuilds in long transcript lists.

5. **Transcript lines provider re-decode** (`lib/features/transcript/application/transcript_lines_provider.dart`)
   - `StreamGroup.merge` of `watchLatestForTarget` and `watchAllForTarget` re-runs `_computeLines` on every tick, which calls `linesForRow` → `_decodeTimeline` (full JSON parse of the timeline column).
   - When only a single row's `updatedAt` changes, the entire merged list re-decodes.
   - A signature-based dedupe (compare `(transcriptId, secondaryTranscriptId, updatedAt)` tuple + the active row's id) could skip the JSON decode work.

6. **Discover refresh fan-out** (`lib/features/discover/data/discover_repository.dart` `refreshFeeds`)
   - Per-channel `_refreshChannel` is awaited in a serial `for` loop.
   - A typical user with 5-10 subscriptions is 5-10 sequential RSS round-trips, each with 1-2 s of latency.
   - `Future.wait` over the independent channels would let the user-perceived refresh time be `max(channel)`, not `sum(channel)`. `_enrichMissingDurations` is already backgrounded.

7. **Dictations DAO has no `==`** — `DictationDao.watchByTarget` is not consumed today but if it gets used, it will need the same dedupe treatment.

### Investigation needed

- Whether `_positionSub` / `_durationSub` in `PlayerController` use `where((p) => p.inSeconds != _last)` style debounce. (Confirmed earlier: position is already bucketed to 400ms in `_subscribeStreams`.)
- `youtube_player_engine.dart` poll-loop timer: confirm it pauses when the engine is detached. (Confirmed earlier: `_stopPolling()` is called from `dispose()`, `idleAfterClear()`, `onWebViewDisposed()`, and the `ended` event.)

## Run History (reverse chronological)

- 2026-06-27 14:30 UTC — run 28291742117 — drafted `[perf-improver] perf(recordings): dedupe identical watchByTarget / watchByEchoRegion emissions`. Reused the `Stream<T>.distinctBy(equals)` extension from #37 / #65. Element-wise `_listEqualsRecordingRow` compare helper. 9 new unit tests. +412/-2 across 2 files. Patch at `/tmp/gh-aw/aw-perf-assist-recording-watch-dedupe-2026-06-27.patch` (16,391 bytes).
- 2026-06-26 15:30 UTC — run 28247168356 — drafted `[perf-improver] perf(discover): dedupe identical watchSubscriptions / watchTimeline / watchChannelFeed emissions`. Reused the `Stream<T>.distinctBy(equals)` extension from issue #37 (local commit; patch saved at `/tmp/gh-aw/aw-perf-assist-discover-feed-dedupe-2026-06-26.patch` for workflow post-processing). Added `==`/`hashCode` to `FeedEntry` and `DiscoverChannel`. 6 unit tests + 6 integration tests. +548/-9 across 6 files. → merged 2026-06-27 as #65.
- 2026-06-25 16:04 UTC — run 28181651032 — drafted `[perf-improver] perf(library): dedupe identical home/filter list emissions` (issue #37). New `Stream<T>.distinctBy(equals)` extension + element-wise dedupe on `libraryHomeRecentsProvider` and `libraryFilteredListsProvider`. 6 + 3 new tests. +385/-1 across 4 files.
- 2026-06-23 15:58 UTC — run 28037649581 — opened draft PR `[perf-improver] perf(library): dedupe identical watchAll emissions` (issue #13). Media value-equality + per-listener emit dedupe + regression test.
- 2026-06-22 14:37 UTC — run 27960568022 — initial discovery, no PR yet (commands not locally runnable).
