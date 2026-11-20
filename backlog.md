# Optimization backlog (updated 2026-11-20)

## Ready-to-ship (validated on main)
- `balance_to_credits.dart:63` (subscription widgets) builds `NumberFormat.simpleCurrency(name: 'USD')` per call — legacy-balance card on the same quiet screen #1412 covered; `cachedNumberFormat` from #1394 applies. Small, measured precedent from #1412 (~3x on number formatting).

## Maintainer-decision items (unchanged)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile.
- P8: position tracker + `position_buckets` both decide seek/bucket rule; at 2× speed a bucket crossing reads as a seek (faster than documented 400 ms cadence).
- P10b: take timeline length from SQL revision projection instead of re-deriving from row (changes decode-memo keys).
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` (every vocabulary row incl. explanation blob) and filters in Dart — NOT absorbed by #1386. Parent #968 closed.

## Context
- 18 perf-improver PRs merged (latest #1412 subscription-card formatter caches — commit 68ab6189; drafted 2026-11-18).
- 2026-11-20 run: PR (draft) `perf-assist/vocab-review-tab-due-preview` — review tab due preview provider (the #827 C2 pattern applied to the Review tab, which that pass missed). If merged, that becomes #19.
- Third-party perf PRs #1381–#1388 + #1393/#1394/#1397/#1402 all landed. The deferred feature re-sweep of touched surfaces is still due.
- #1394 added `lib/core/format/cached_number_format.dart` (shared per-locale NumberFormat cache) — reuse for future format candidates.
- Provider-cache candidates: grep presentation `build` methods that watch `vocabularyItemsProvider` (or similar item streams) and derive inline (map/set/sort/filter/copy). The #827 C2 pass covered the word list; 2026-11-20 covered the Review tab; other surfaces likely clean but a fresh sweep per feature is cheap.
