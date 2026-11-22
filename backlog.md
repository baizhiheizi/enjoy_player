# Optimization backlog (updated 2026-11-22)

## Ready-to-ship (validated on main)
- (none — review-panel candidate shipped as draft 2026-11-22; sweep of formatter/RegExp/provider-derivation patterns found only tiny/cold leftovers, see below)

## Minor (not PR-worthy alone; bundle candidates if a related surface is touched)
- `languageCodeLabel` (lib/core/presentation/language_labels.dart:107) builds `RegExp('[-_]')` per call (compact chips, warm).
- `formatRateCore` (lib/features/player/presentation/widgets/player_dock_primitives.dart:33) builds a lookbehind RegExp per call (rate labels, handful per rebuild).
- `semver_compare.dart:6` replaceFirst(RegExp) + proxy_parsers.dart inline RegExps — cold paths (update check, proxy settings).

## Maintainer-decision items (re-verified present on main 2026-11-22)
- P7: auto-translate flush rebuilds 40–80 tiles + re-resolves secondary text per tile (files still on main).
- P8: position tracker + `position_buckets` both decide seek/bucket rule; at 2× speed a bucket crossing reads as a seek (tracker still imports buckets).
- P10b: take timeline length from SQL revision projection instead of re-deriving from row (changes decode-memo keys).
- P3-reframed: `VocabularyReviewSessionLifecycle.start()` still calls `repo.listAll()` (vocabulary_review_session_lifecycle.dart:10) and filters in Dart — NOT absorbed by #1386. Parent #968 closed.

## Context
- Twenty perf-improver PRs merged (latest: #1438 review-tab due preview = commit ca03d62a, #1439 balance-card currency cache = 60d742fd, both merged 2026-11-21/22).
- 2026-11-22 run shipped the review-panel provider counts (branch `perf-assist/review-panel-provider-counts`, commit 6ad97796, draft): due tile reads vocabularyDuePreviewProvider.select(count), all tile = items.length, languages watch vocabularyListLanguagesProvider.
- #1394 `lib/core/format/cached_number_format.dart` — all remaining DateFormat/NumberFormat call sites already go through the caches (re-swept 2026-11-22); RegExp highlight sites are L1Store-cached.
- Provider-cache sweep method: grep presentation `build` methods that watch item streams and derive inline (map/set/sort/filter/copy). Word list (#827 C2), Review tab header (#1438) and custom-review panel (2026-11-22) covered; anki-export dialog derives languages inline but is cold. Other features likely clean but unverified.
- Deferred feature re-sweep of the surfaces touched by third-party perf PRs (#1381–#1388, #1393/#1394/#1397/#1402) is still due.
