# Optimization backlog (updated 2026-11-27)

## Ready-to-ship (validated on main)
- (none — 2026-11-27 shipped the hot RegExp scans; draft branch perf-assist/hot-regex-scan awaits review)

## Minor (not PR-worthy alone; bundle candidates if a related surface is touched)
- 2026-11-23 sweep findings (third-party perf PR surfaces + 11-19..11-23 refactors) — REMAINING after 2026-11-27 shipped the two RegExp sites:
  - LOW-MEDIUM: `echoReferencePlainText` (transcript_echo_region_merged_card.dart:119, impl transcript_line_alignment.dart:93-104) re-strips markup + joins all region lines per cue transition (~3-5 s during echo playback); output depends only on (lines identity, echo window) — memoizable; feeds EchoRegionKey.fromSeconds → recordings query. 2026-11-24 re-check: PlaybackChrome excludes clock fields, so the card does NOT rebuild per position tick — cadence is cue changes only; cost per call is µs. Truly minor.
  - LOW: dock practised-count `(watch(...) ?? {}).values.where((c) => c > 0).length` per cue tick (player_dock_primitives.dart:94-99); small map.
  - LOW: discover avatar strip `.where(!subscribedChannelIds.contains(...))` O(n×m) List scan per build (discover_recommended_avatar_strip.dart:63-65); rebuilds only on data change — hoist a Set.
  - NEGLIGIBLE: newest-publishedAt reduce per feed data-build (discover_screen.dart:213-215).
- 2026-11-27: `findSliverIndexByPrefixedId` (lib/core/utils/sliver_key_index.dart, from #1478) is O(n) per alive child via findChildIndexCallback on grid re-emission; it REPLACES an O(n) default fallback and re-emissions are infrequent — parked; a memoized id→index map per items identity would make it O(1) if grids grow.
- `semver_compare.dart:6` + proxy_parsers.dart inline RegExps — cold.

## Maintainer-decision items (re-verified present on main 2026-11-22)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile.
- P8: position tracker + `position_buckets` both decide seek/bucket rule; 2× speed bucket crossing reads as a seek.
- P10b: take timeline length from SQL revision projection instead of re-deriving (changes decode-memo keys).
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` and filters in Dart (vocabulary_review_session_lifecycle.dart:10).

## Context
- Twenty-three perf-improver PRs merged (latest #1471 MFCC typed-data = commit a31dcb03, merged 2026-11-25/26); 2026-11-27 draft (hot RegExp scans, perf-assist/hot-regex-scan ff2eaab0) awaits review.
- 2026-11-27 survey: #1487 (skeleton split) byte-identical pure move; #1478 (shared media-grid scaffolding) perf-positive (stable ValueKeys + findChildIndexCallback element reuse on re-emission).
- 2026-11-24 DSP sweep: packages/forced_alignment internals now CLEAN — DTW optimal since #827 (rolling rows + band + Uint8 dirs), MFCC extractor rewritten (merged as #1471), eSpeak synth/phonemize are FFI-bound not Dart-loop-bound. alignment_isolate batches cues into ONE isolate already; PCM crosses the boundary per job (TransferableTypedData could shave a copy — likely negligible vs DSP).
- 2026-11-23 deferred re-sweep DONE (presentation surfaces clean; minor bundle candidates listed above; mispronouncedWordIndexes dead code).
- Provider-cache sweep method + house decode-memo pattern (L1Store + _Hit wrapper + @visibleForTesting counter) proven; typed-data DSP rewrite pattern (pub-package oracle differential + DTW-map pin + sampler-strip sinks) proven; exact-scan pattern (curated edges + exhaustive BMP + fuzz, sink-checked bench pairs) proven again 2026-11-27.
- Dead code noted: mispronouncedWordIndexes (word_note_indexes.dart) has no production callers.
- Possible future DSP candidates if alignment grows: share one _MfccTables across the ref+source extracts of a pipeline run (tables are per-call now, ~30 µs each — negligible), plan-cache keyed by fftSize if call counts rise.
