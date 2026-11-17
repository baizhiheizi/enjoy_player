# Optimization backlog (updated 2026-11-17)

## In progress this run
- **P24: Craft per-rebuild text gates** — translate_tool/synthesize_tool/rewrite_stage run full regex `collapseWhitespace` per rebuild (per keystroke: `setSourceText`/`setSynthText`/`setRawTranscript` copy text into watched state each key). `isRawTranscriptDirty` adds 2 more collapses per rewrite-stage build. Fix: exact allocation-free scans (`meetsCraftMinTextLength`, `collapsedLength`) + dirty-getter fast paths. Branch `perf-assist/craft-gate-scan`.

## Ready-to-ship (validated on main 2026-11-17)
- Subscription status card `_formatDate` (`subscription_status_card.dart:353`): `DateFormat.yMMMMd(locale)` per call, 1–2 per build + 2 per cancel confirm; also `NumberFormat.decimalPattern()` per build at line 91 (#1394 added `lib/core/format/cached_number_format.dart` — reuse it). Quiet screen.
- `vocabulary_review_options.dart`: `VocabularyCustomReview.build` recomputes `languages` (map+set+sort over all items) + builds 2 full session queues (`queueLength` for due+all) per rebuild; `_DueReviewCard.build` builds a third queue; Start button builds a 4th. All per tap (setState). LOW.
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` (every vocabulary row incl. explanation blob) and filters in Dart — NOT absorbed by #1386. Needs maintainer decision (parent #968 closed).

## Maintainer-decision items (unchanged)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile.
- P8: position tracker + `position_buckets` both decide seek/bucket rule; at 2× speed a bucket crossing reads as a seek (faster than documented 400 ms cadence).
- P10b: take timeline length from SQL revision projection instead of re-deriving from row (changes decode-memo keys).

## Context
- 16 perf-improver PRs merged (latest #1389 card-thumbnail memo, merged by an-lee 2026-11-16 23:25 UTC).
- Third-party perf PRs #1381–#1388 + #1393/#1394/#1397/#1402 ALL landed on main by 2026-11-17. The deferred feature re-sweep is now due — but this run's candidate was picked from the validated backlog instead.
- #1394 added `lib/core/format/cached_number_format.dart` (shared per-locale NumberFormat cache) — reuse for future format candidates.
