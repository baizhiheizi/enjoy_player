# Performance backlog — Enjoy Player

Prioritized by impact × feasibility × measurability. Source: Explore subagent sweep (2026-10-08)
over transcript rendering, subtitle parsing, search, position ticks, DB queries, memory.

IMPORTANT calibration note: several findings were initially rated "high/per-frame", but on
verification the Riverpod providers are cached and recompute on DATA change (lines/recordings
change), NOT on every position tick. Ratings below reflect the VERIFIED recompute trigger.

## P1 — Transcript recording-count O(n×m)  [first implementation candidate]
- File: `lib/features/transcript/domain/transcript_recording_counts.dart:22-38`
  `countRecordingsPerLineIndex(lines, recordings)` is a nested loop: for each of `n` lines it
  scans all `m` recordings calling `recordingOverlapsLine`. Real O(n×m).
- Trigger (verified): `transcriptLineRecordingCountsProvider` (transcript_line_recording_counts_provider.dart:73)
  watches transcriptLines + recordingsForTarget. Recomputes when lines OR recordings change
  (e.g. after each shadow-reading save, media open) — cached otherwise. NOT per playback tick.
- Consumers: transcript_scrollable_list.dart:459, sentence_ruler.dart:105,
  transcript_echo_region_merged_card.dart:72, share_poster (practice_poster_data.dart:86,169).
- Optimize: sweep-line / interval approach. Sort recordings by referenceStart; sort lines by
  startMs; maintain an active set while advancing line startMs; O((n+m) log(n+m)) vs O(n×m).
  MUST preserve exact overlap rule `max(startA,startB) < min(endA,endB)` (boundary semantics,
  zero-duration intervals) — `test/features/transcript/transcript_recording_counts_test.dart`
  pins zero-duration line/recording semantics + boundary cases.
- Structural test (additive, low-risk before/after):
  - Wrap `recordingOverlapsLine` in a counter (only the helper, not the public API) and assert
    the count is bounded by ~n×(active-window size) on 10k lines × 200 random recordings.
  - Existing `transcript_recording_counts_test.dart` will catch any semantics regression.
- Wall-clock (local-only): 10k lines × 200 recordings, loose ceiling (docs/perf-measurement.md template).
- Risk: MED (algorithmic change, edge cases). Only attempt where tests can run (network runner).

## P2 — TranscriptStreamGroup double-resolve on every DB tick
- File: `lib/features/transcript/data/transcript_repository_lines.dart:48-60`
  `StreamGroup.merge([watchLatestForTarget, watchSummariesForTarget]).asyncMap(...)` on BOTH
  sides; a write touching both tables triggers two independent full `_computeActiveLines` resolves
  + a stale intermediate emission. `.distinctBy(listEquals)` dedupes output, not work.
- Measure: extend transcript_lines_provider_dedupe_test.dart — write once, assert the resolve
  runs exactly once (barrier counter).
- Impact: MED, Confidence: HIGH.

## P3 — vocabulary_item_dao.listDue over-fetches (Dart-side filter that SQL can do)
- File: `lib/data/db/daos/vocabulary_item_dao.dart:45-56` — broad `nextReviewAt <= now` SELECT,
  then filters `lastReviewedAt` in Dart. Push second predicate into SQL.
- Measure: structural — rows considered vs rows returned on a seeded table.

## P4 — transcript_dao.listForTarget materializes full timelineJson for existence checks
- `lib/features/transcript/data/transcript_repository_resolve.dart:19,25,40` calls
  `_ensurePrimaryTranscript`/`listForTarget` 2-3× per resolve; `lib/data/db/daos/transcript_dao.dart:90-101`
  pulls every row's big `timelineJson`. Use `selectOnly` + LIMIT 1 for existence (pattern already
  exists in watchSummariesForTarget).
- Measure: counter on listForTarget calls per resolve; payload bytes with a 1 MB blob row.

## P5 — SentenceRuler reallocates List<double> every 50 ms tick
- `lib/features/player/presentation/widgets/transport/sentence_ruler.dart:97-101,153-159` rebuilds
  on 50 ms provider and reallocates `[for line … ] List<double>` each time. Hoist into a
  `Selector` keyed on (linesIdentity, durationSec).
- Measure: extend transport_progress_strip_perf_test.dart paint/allocation counter.
- Impact: LOW-MED, Confidence: HIGH, Risk: LOW.

## Measurement-infrastructure gaps (docs/perf-measurement.md confirms deferred)
- No subtitle-parser throughput test. Add a deterministic 5k-line SRT parse microbenchmark
  (`lib/data/subtitle/subtitle_parser.dart`), loose ceiling. LOW risk, closes a real gap.
- No dedicated test/perf/ dir or benchmark CI smoke job (deferred by maintainers).

## Considered and de-prioritized
- Karaoke 50 ms rebuild path (transcript_scrollable_list active tile rebuilds ~20 Hz). Cached
  provider; real but tuning territory, needs DevTools profiling, not a blind change.
- Subtitle `_parseCache` FIFO eviction looseness (subtitle_markup_parser.dart) — LOW, cosmetic cap.
- Position-tracker double enforceTick (player_position_tracker.dart) — LOW-MED, needs profiling.
