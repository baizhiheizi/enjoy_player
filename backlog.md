# Optimization backlog (updated 2026-11-23)

## Ready-to-ship (validated on main)
- (2026-11-23 run implementing the pron-score decode memo — branch perf-assist/pron-score-decode-memo)

## Minor (not PR-worthy alone; bundle candidates if a related surface is touched)
- 2026-11-23 sweep findings (third-party perf PR surfaces + 11-19..11-23 refactors):
  - LOW-MEDIUM: `echoReferencePlainText` (transcript_echo_region_merged_card.dart:119, impl transcript_line_alignment.dart:93-104) re-strips markup + joins all region lines per cue transition (~3-5 s during echo playback); output depends only on (lines identity, echo window) — memoizable; feeds EchoRegionKey.fromSeconds → recordings query.
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
- Twenty-one perf-improver PRs merged (latest #1446 review-panel provider counts = commit 3b8f8131, merged 2026-11-22/23).
- 2026-11-23 deferred re-sweep DONE: fork-scanned the presentation surfaces of #1381-#1388/#1393/#1394/#1397/#1402 (transcript/player/discover/cloud/dictation/shadow_reading/lookup/share_poster/core-theme-widgets). Clean: dictation band (State-memoized words), cloud tiles, core theme widgets (top-level RegExps, painter math), lookup (L1Store RegExps), share poster, transcript virtual list (identity-memoized). Post-refactor verification: #1419 consolidated the ten DateFormat memos INTO my shared caches; #1445 pitch split = pure code motion (memo intact); #1455 collapsed the pitch-analysis cache twins into bounded _CancellableCache (improvement); thumbnail memo relocated intact to lib/core/utils/remote_thumbnail_url.dart. NO regressions found.
- Provider-cache sweep method + house decode-memo pattern (L1Store + _Hit wrapper + @visibleForTesting counter) proven again this run.
- Dead code noted: mispronouncedWordIndexes (word_note_indexes.dart) has no production callers.
