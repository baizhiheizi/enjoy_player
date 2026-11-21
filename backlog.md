# Optimization backlog (updated 2026-11-21)

## Ready-to-ship (validated on main)
- (none — the two validated candidates shipped as drafts on 2026-11-21; next candidates need a fresh sweep)

## Maintainer-decision items (unchanged)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile.
- P8: position tracker + `position_buckets` both decide seek/bucket rule; at 2× speed a bucket crossing reads as a seek (faster than documented 400 ms cadence).
- P10b: take timeline length from SQL revision projection instead of re-deriving from row (changes decode-memo keys).
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` (every vocabulary row incl. explanation blob) and filters in Dart — NOT absorbed by #1386. Parent #968 closed.

## Context
- 18 perf-improver PRs merged (latest #1412 subscription-card formatter caches — commit 68ab6189; drafted 2026-11-18).
- 2026-11-21 run re-shipped the review-tab due preview (branch `perf-assist/vocab-review-tab-due-preview`, commit 59a253ae) and shipped the balance-card currency cache (branch `perf-assist/balance-currency-cache`, commit 4e431339). The 2026-11-20 run's version of the due-preview PR never published — work was redone from scratch.
- Third-party perf PRs #1381–#1388 + #1393/#1394/#1397/#1402 all landed. The deferred feature re-sweep of touched surfaces is still due.
- #1394 added `lib/core/format/cached_number_format.dart` (shared per-locale NumberFormat cache; `cachedSimpleCurrency` added 2026-11-21) — reuse for future format candidates.
- Provider-cache candidates: grep presentation `build` methods that watch `vocabularyItemsProvider` (or similar item streams) and derive inline (map/set/sort/filter/copy). The #827 C2 pass covered the word list; the Review tab was covered 2026-11-21; other surfaces likely clean but a fresh sweep per feature is cheap.
- Maintainer-decision items unchanged (P7 auto-translate flush, P8 seek/bucket rule, P10b timeline length from SQL projection, P3-reframed review-session listAll over-fetch) — re-verify on current main before escalating.
