---
name: perf-improver-state
description: Perf Improver persistent state — discovered commands, opportunities backlog, run history
metadata:
  type: project
---

# Perf Improver — State

## Discovered Commands

CI pinned in `.github/workflows/ci.yml`; Flutter version in `.github/flutter-version` (currently `3.44.0`).

```bash
export PATH="/tmp/flutter_sdk/flutter/bin:$PATH"  # SDK copied from /opt/hostedtoolcache
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
# Path packages: (cd packages/<name> && flutter pub get && flutter test)
```

Codegen: `dart run build_runner build` (or `bash .github/scripts/check_codegen_drift.sh --fix`). No benchmark / perf-regression CI job. 1 pre-existing Linux failure unrelated to perf work (`extractEntireFileMonoF32` ffmpeg_kit MissingPlugin).

## Optimization Backlog

### Addressed (chronological)

- #13 → #56 media library re-emit storms — `Media` `==`/`hashCode` + cache.
- #37 → #64 library derived providers — `Media.==` + `Stream<T>.distinctBy(equals)`.
- #46/#47 → #65 discover feed re-emissions — `FeedEntry.==`/`DiscoverChannel.==`.
- #79 → #79 recordings re-emissions — `_listEqualsRecordingRow`.
- #131 → #137 transcript lines re-decode — `getById(activeId)` + `distinctBy(_listEqualsTranscriptLine)`.
- #150 → grid stable keys + `findChildIndexCallback` (`lib/core/utils/sliver_key_index.dart`).
- #106 (closed) — discover perf parent: semaphore, `List.unmodifiable`, scheduler gating.
- #188 (2026-07-02) — artwork palette LRU on `(path, size, mtime)`.
- #208+#238 (2026-07-07) — `TranscriptTrack` `==`/`hashCode` (7 fields) + `TranscriptRepository.watchTracks` ends `.distinctBy(_listEqualsTranscriptTrack)`. Closes #219.
- #291 (2026-07-11) — `PlaybackSession` `==`/`hashCode` (12 fields, excludes `lastActiveAt`); `EchoState` `==`/`hashCode` (5 fields); new `rawEnginePositionStreamProvider` is the single shared `engine.position` subscription consumed by `display_position_provider.dart:14` + `transport_slider_position_provider.dart:11`; every `playerControllerProvider` consumer uses `.select(playbackChromeOf)`/scope selectors (`root_shell.dart:62`, `global_transport_bar.dart:228/230`, `expanded_player_screen.dart:40`, `transcript_panel.dart:79`, `subtitle_track_picker_sheet.dart:657`, `transcript_echo_region_merged_card.dart:51`); every `autoTranslateCtrlProvider` consumer uses `.select(...)` on stable fields (`transcript_scrollable_list.dart:405`, `transcript_echo_region_merged_card.dart:58`); `PlayerInteractions._lines()` per-session cached (lines 65-85). Closes P5/P7/P10/P11/M6/P12/M8.

### Remaining

1. **Artwork palette off main isolate** (`lib/core/theme/dynamic_color/artwork_palette.dart`) — `palette_generator` 0.3.x has no isolate-safe API; needs maintainer sign-off for major bump or hand-rolled quantiser. Home grid routes around it; `expanded_player_screen` + `global_transport_bar` pay the cost. **Reassessed 2026-07-11, deferred.**
2. ✅ Artwork palette cache staleness (PR #188).
3. ✅ Transcript tracks dedupe (PR #208+#238).
4. **JSON decode concurrency audit** (`lib/data/api/api_client.dart`) — `_decodeResponseBody` uses `compute()` for >48 KB. `audio_api.audios()` / `transcript_api.transcripts()` are simple one-shots; threshold correct as-is.
5. **Dictations DAO** — `DictationDao.watchByTarget` has no consumer in `lib/` today (`app_database.dart:650`; only generated `.g.dart` references it). When hooked up, needs the same `.distinctBy(equals)` treatment.
6. **Cosmetic** — `recommendedChannelAvatar` redundantly `ref.watch(discoverSubscriptionsProvider)` (`discover_providers.dart:158-180`). Out of scope here.

## Measurement infrastructure status

- All work to date measures via structural unit-test assertions (`emissions.length` before/after Drift write). Cheap, deterministic, runs in `flutter test`.
- For compute-bound work the natural extension is `Stopwatch` microbenchmarks in `test/perf/` gated on `--dart-define=PERF=1`. Not yet built.
- No CI perf regression job. Assessment 2026-07-07.

## Investigation completed

- `_positionSub` / `_durationSub` — already bucketed to 400 ms in `_subscribeStreams`.
- `youtube_player_engine.dart` poll-loop timer — `_stopPolling()` confirmed in `dispose()` / `idleAfterClear()` / `onWebViewDisposed()` / `ended`.
- #131 transcript lines — closed 2026-06-28 by #137.
- #106 discover perf parent — closed 2026-06-28 by `@an-lee`.
- #219 transcript tracks dedupe — closed 2026-07-07 by #208+#238.
- #188 artwork palette cache staleness — merged 2026-07-02.
- #291 transcript/player rebuild storms — all post-#291 auditable paths deduped; PR captured by maintainer on 2026-07-11.

## Run History

- **2026-07-11** 14:30 UTC — run 29155553769. Investigation only. Audited #291 / #292 / #293 / #295. Confirmed `PlaybackSession` + `EchoState` `==`/`hashCode`; every chrome provider consumer uses `.select(...)`; one shared `rawEnginePositionStreamProvider`; `PlayerInteractions._lines()` cached. `transcriptLinesForMediaProvider` still ends `.distinctBy(_listEqualsTranscriptLine)`; `TranscriptRepository.watchTracks` still ends `.distinctBy(_listEqualsTranscriptTrack)`. `DictationDao.watchByTarget` still has no `lib/` consumer. No new `performance`-labeled issues. No new PR. Updated issue #189 + memory.
- **2026-07-09** 15:51 UTC — run 29030763563. Investigation only. `AutoTranslateUiState` (lib/features/transcript/domain/auto_translate.dart:54) + `TapRevealHold` (lib/features/transcript/domain/transcript_blur.dart:36) ship with `==`/`hashCode`. Dedupe chain still complete.
- **2026-07-07** 15:30 UTC — run 28878529792. Investigation only. PR #208+#238 shipped. Remaining items out of scope.
- **2026-07-06** 15:30 UTC — run 28805344315. Drafted transcript-tracks dedupe → PR #208+#238 (merged 2026-07-07).
- **2026-07-02** 15:30 UTC — run 28599784313. Drafted artwork-palette LRU → PR #188 (merged).
- 2026-06-30 — #137 + audit.
- 2026-06-29 — #150 grid stable keys (merged).
- 2026-06-28 — #137 transcript lines (merged).
- 2026-06-27 — #79 recordings dedupe (merged).
- 2026-06-26 — #65 discover dedupe (merged).
- 2026-06-25 — #64 library dedupe (merged).
- 2026-06-23 — #56 library dedupe (merged).
- 2026-06-22 — discovery.

## Per-run safe-output checklist

Always update issue #189 (monthly summary, current month) with a new Run History entry prepended; update memory; if no actionable findings call `noop`. Use `update_issue` with `replace` operation when replacing body (keep within 10 KB); prefer trimming Run History entries when memory exceeds 12 KB total.
