# Optimization backlog (updated 2026-11-18)

## In progress this run
- **Subscription status card formatter caches** — `subscription_status_card.dart` built `DateFormat.yMMMMd(locale)` per `_formatDate` call (1–2 per card build + 2 per cancel confirm) and `NumberFormat.decimalPattern()` per build (credits label). Fix shipped: per-locale `_statusDateCache` + `cachedDecimalPattern()` (helper from #1394). Branch `perf-assist/subscription-card-formatter-cache`. Measured (one process per arm, 3 rounds, sinks identical): status date 0.937–0.962 → 0.070 ms per 502-call pass (~13.4x); credits number 0.407–0.415 → 0.131–0.136 (~3.1x); paid card build (25 builds × 3 calls) 0.117–0.132 → 0.019–0.042 (~3.1–6.2x round-paired).

## Ready-to-ship (validated on main)
- `vocabulary_review_options.dart`: `VocabularyCustomReview.build` recomputes `languages` (map+set+sort over all items) + builds 2 full session queues (`queueLength` for due+all) per rebuild; `_DueReviewCard.build` builds a third queue; Start button builds a 4th. All per tap (setState). LOW.
- Same-surface follow-up: `balance_to_credits.dart:63` builds `NumberFormat.simpleCurrency(name: 'USD')` per call (legacy-balance card, same quiet screen).

## Maintainer-decision items (unchanged)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile.
- P8: position tracker + `position_buckets` both decide seek/bucket rule; at 2× speed a bucket crossing reads as a seek (faster than documented 400 ms cadence).
- P10b: take timeline length from SQL revision projection instead of re-deriving from row (changes decode-memo keys).
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` (every vocabulary row incl. explanation blob) and filters in Dart — NOT absorbed by #1386. Parent #968 closed.

## Context
- 17 perf-improver PRs merged (latest #1403 craft text gates — merged to main 2026-11-18 as commit 0469f394; was drafted 2026-11-17).
- Third-party perf PRs #1381–#1388 + #1393/#1394/#1397/#1402 all landed. The deferred feature re-sweep of touched surfaces is still due.
- #1394 added `lib/core/format/cached_number_format.dart` (shared per-locale NumberFormat cache) — reuse for future format candidates.
