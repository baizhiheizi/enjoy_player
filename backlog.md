# Optimization backlog (updated 2026-11-24)

## Ready-to-ship (validated on main)
- (2026-11-24 run implementing the MFCC typed-data pipeline — branch perf-assist/mfcc-typed-data)

## Minor (not PR-worthy alone; bundle candidates if a related surface is touched)
- 2026-11-23 sweep findings (third-party perf PR surfaces + 11-19..11-23 refactors):
  - LOW-MEDIUM: `echoReferencePlainText` (transcript_echo_region_merged_card.dart:119, impl transcript_line_alignment.dart:93-104) re-strips markup + joins all region lines per cue transition (~3-5 s during echo playback); output depends only on (lines identity, echo window) — memoizable; feeds EchoRegionKey.fromSeconds → recordings query. 2026-11-24 re-check: PlaybackChrome excludes clock fields, so the card does NOT rebuild per position tick — cadence is cue changes only; cost per call is µs. Truly minor.
  - LOW: dock practised-count `(watch(...) ?? {}).values.where((c) => c > 0).length` per cue tick (player_dock_primitives.dart:94-99); small map.
  - LOW: discover avatar strip `.where(!subscribedChannelIds.contains(...))` O(n×m) List scan per build (discover_recommended_avatar_strip.dart:63-65); rebuilds only on data change — hoist a Set.
  - NEGLIGIBLE: newest-publishedAt reduce per feed data-build (discover_screen.dart:213-215).
- `languageCodeLabel` (lib/core/presentation/language_labels.dart:107) builds `RegExp('[-_]')` per call (compact chips, warm).
- `formatRateCore` (lib/features/player/presentation/widgets/player_dock_primitives.dart:33) lookbehind RegExp per call.
- `semver_compare.dart:6` + proxy_parsers.dart inline RegExps — cold.

## Maintainer-decision items (re-verified present on main 2026-11-22)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile.
- P8: position tracker + `position_buckets` both decide seek/bucket rule; 2× speed bucket crossing reads as a seek.
- P10b: take timeline length from SQL revision projection instead of re-deriving (changes decode-memo keys).
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` and filters in Dart (vocabulary_review_session_lifecycle.dart:10).

## Context
- Twenty-two perf-improver PRs merged (latest #1457 pron-score decode memo = commit fda2ed0a, merged 2026-11-23/24).
- 2026-11-24 DSP sweep: packages/forced_alignment internals now CLEAN — DTW optimal since #827 (rolling rows + band + Uint8 dirs), MFCC extractor rewritten this run (see notes), eSpeak synth/phonemize are FFI-bound not Dart-loop-bound. alignment_isolate batches cues into ONE isolate already; PCM crosses the boundary per job (TransferableTypedData could shave a copy — likely negligible vs DSP).
- 2026-11-23 deferred re-sweep DONE (presentation surfaces clean; 4 minor bundle candidates listed above; mispronouncedWordIndexes dead code).
- Provider-cache sweep method + house decode-memo pattern (L1Store + _Hit wrapper + @visibleForTesting counter) proven again; typed-data DSP rewrite pattern (pub-package oracle differential + DTW-map pin + sampler-strip sinks) proven this run.
- Dead code noted: mispronouncedWordIndexes (word_note_indexes.dart) has no production callers.
- Possible future DSP candidates if alignment grows: share one _MfccTables across the ref+source extracts of a pipeline run (tables are per-call now, ~30 µs each — negligible), plan-cache keyed by fftSize if call counts rise.
