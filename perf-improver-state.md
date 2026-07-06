---
name: perf-improver-state
description: Perf Improver persistent state — discovered commands, opportunities backlog, run history
metadata:
  type: project
---

# Perf Improver — State

## Discovered Commands (from .github/workflows/ci.yml)

Flutter version pinned in `.github/flutter-version` (currently `3.44.0`).
Self-hosted Linux runner executes via `.github/actions/setup-flutter`.

### Build / test / lint (match CI exactly)

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
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
```

### Local SDK on agentic runner

- The host copy at `/opt/hostedtoolcache/flutter/stable-3.44.0-x64/flutter` is read-only (the SDK's `update_engine_version.sh` writes to `bin/cache/`).
- The runner copies it to `/tmp/flutter_sdk/flutter/` so `flutter pub get` / `flutter test` / `flutter analyze` can write.
- `export PATH="/tmp/flutter_sdk/flutter/bin:$PATH"` is enough to make the rest of the workflow go.

### Validation status

- Per CI config, commands succeed on the self-hosted `Linux` runner AND on the agentic runner once the SDK is copied.
- No benchmark / perf-regression CI job exists in this repo today.
- 1 pre-existing test failure on the agentic runner: `extractEntireFileMonoF32` throws `MissingPluginException(... flutter.arthenica.com/ffmpeg_kit)` because `ffmpeg_kit_flutter_new` has no native Linux implementation. Unrelated to perf-improver work; leave alone.

## Optimization Backlog

### Addressed (in chronological merge order)

- **Library re-emit storms** (#13 → PR #56, merged) — `MediaLibraryRepository.watchAll()` re-emits on every Drift table change. Adds `==`/`hashCode` to `Media`, caches `lastEmitted`.
- **Library derived providers rebuild on no-op ticks** (#37 → PR #64, merged) — `libraryHomeRecentsProvider` + `libraryFilteredListsProvider`. Adds `Stream<T>.distinctBy(equals)` extension + element-wise `Media.==`.
- **Discover feed Drift re-emissions** (#46/#47 → PR #65, merged) — `watchSubscriptions`/`watchTimeline`/`watchChannelFeed` chains. Element-wise `FeedEntry.==`/`DiscoverChannel.==`.
- **Recordings Drift re-emissions** (#79 → PR #79, merged) — `RecordingDao.watchByTarget`/`watchByEchoRegion`. `_listEqualsRecordingRow` helper.
- **Transcript lines provider re-decode** (#131 → PR #137, merged) — `_computeLines` uses `getById(activeId)` not `listForTarget`; merged stream ends in `distinctBy(_listEqualsTranscriptLine)`.
- **Discover refresh fan-out** (prior round) — `_kRefreshChannelConcurrency = 4`, `_kAvatarCacheCapacity = 256` LRU.
- **Grid stable keys + findChildIndexCallback** (#150, merged 2026-06-29) — `ValueKey(entity.id)` + `findChildIndexCallback` on home/discover/channel-feed grids. New `lib/core/utils/sliver_key_index.dart`.
- **Discover perf parent** (#106, closed) — semaphore, `List.unmodifiable`, scheduler gating.
- **Artwork palette cache staleness** (#188, merged 2026-07-02) — LRU key `(path, size, mtime)`. `_lookupFresh` walks order list, drops stale entries.
- **Transcript tracks Drift re-emissions** (this run, 2026-07-06) — `TranscriptRepository.watchTracks` (consumed in always-mounted `transport_cc_fullscreen`). Adds `==`/`hashCode` to `TranscriptTrack` (7 fields). `.distinctBy(_listEqualsTranscriptTrack)` over mapped stream. 9 new unit tests. Branch `perf-assist/transcript-tracks-dedupe-2026-07-06`.

### Confirmed hot paths / opportunities

1. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `PaletteGenerator.fromImageProvider` decodes + analyses pixels on the UI isolate. `home_screen.dart` already routes around it via `generativeAccentForSeed`. `expanded_player_screen` + `global_transport_bar` pay the cost. LRU cache (32) makes revisits free. `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off per "no new dependencies without discussion" rule.
2. **API client JSON decode** (`lib/data/api/api_client.dart`) — `_decodeResponseBody` uses `compute()` for >48 KB. Audit (2026-06-30) confirmed `audio_api.audios()`/`transcript_api.transcripts()` are simple one-shots; no fan-out. Correct as-is.
3. **Dictations DAO** — `DictationDao.watchByTarget` is not consumed in `lib/` today (only referenced in generated code). When hooked up, needs the same `.distinctBy(equals)` treatment.
4. **Cosmetic** — `recommendedChannelAvatar` provider does `ref.watch(discoverSubscriptionsProvider)` redundantly (`discover_providers.dart:158-180`).

## Measurement infrastructure status

- No benchmark suite, no CI perf regression job, no profiler integration exists today.
- All perf-improver work to date measures via **emission-count assertions** in unit tests: `emissions.add(...)` into a `List`, compare lengths before/after a Drift write. Cheap, deterministic, runs in `flutter test`. This is the only measurement infrastructure available — adequate for dedupe / rebuild hot-path PRs but not for compute-bound work (e.g. palette decode).
- For compute-bound work, the natural extension would be `Stopwatch`-based microbenchmarks in `test/perf/`, gated on `--dart-define=PERF=1` to keep them out of the default `flutter test` path. Not yet built.

## Investigation completed

- `_positionSub` / `_durationSub` in `PlayerController` — already bucketed to 400ms in `_subscribeStreams`.
- `youtube_player_engine.dart` poll-loop timer — `_stopPolling()` confirmed in `dispose()`, `idleAfterClear()`, `onWebViewDisposed()`, and `ended`.
- Issue #131 (transcript lines) — closed 2026-06-28 by PR #137.
- Issue #106 (Discover perf parent) — closed 2026-06-28 by `@an-lee`.
- Artwork palette cache staleness (2026-07-02) — fixed by PR #188.

## Run History (recent; older entries archived)

- 2026-07-06 — run 28805344315 — drafted `[perf-improver] perf(transcript): dedupe identical watchTracks emissions`. `TranscriptTrack` gains `==`/`hashCode` over 7 fields. `TranscriptRepository.watchTracks` ends in `.distinctBy(_listEqualsTranscriptTrack)`. Reuses shared `Stream.distinctBy(equals)` extension from #64/#65/#79/#137. 9 new unit tests. Branch `perf-assist/transcript-tracks-dedupe-2026-07-06`. `dart format` clean, `flutter analyze` clean, `flutter test` 793 pass / 2 pre-existing skip. PR draft created.
- 2026-07-03 15:00 UTC — run 28668255781 — drafted `[perf-improver] perf(transcript): dedupe identical watchTracks emissions` (first attempt; branch was lost on cleanup). → re-attempted this run.
- 2026-07-02 15:30 UTC — run 28599784313 — drafted `[perf-improver] perf(theme): key artwork palette LRU on path + size + mtime` → merged as PR #188.
- 2026-06-30 — run 28455287886 — investigation only. Audited post-dedupe-wave state.
- 2026-06-29 — run 28387064065 — drafted `[perf-improver] perf(ui): stable item keys + findChildIndexCallback` → merged as PR #150.
- 2026-06-28 — run 28387064065 — opened PR #137 transcript lines dedupe → merged.
- 2026-06-27 — run 28291742117 — drafted recordings dedupe → merged as PR #79.
- 2026-06-26 — run 28247168356 — drafted discover dedupe → merged as PR #65.
- 2026-06-25 — run 28181651032 — drafted library dedupe (#37) → merged as PR #64.
- 2026-06-23 — run 28037649581 — drafted library dedupe (#13) → merged as PR #56.
- 2026-06-22 — run 27960568022 — initial discovery.