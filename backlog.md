# Performance backlog — Enjoy Player

**MAJOR UPDATE 2026-10-18:** All 5 maintainer PRs from #968 are now MERGED on
`main`. The architecture review pass-4 (transcript content, library views, ruler,
frame probe, assessment notes) is fully shipped. Repo Assist (run 39099034539)
recommended closing #968 at 2026-10-18 05:09 UTC since "the architecture review
pass-4 work is done." The "Also verified, smaller" candidates (P6 startup prefs,
P7 auto-translate fan-out, P8 position tracker) were explicitly out of scope.

**Open items below are Perf Improver candidates for a future NETWORKED runner run.**

## ~~P1~~ Transcript recording-count O(n×m)  → #969 MERGED
## ~~P2~~ TranscriptStreamGroup double-resolve → #969 MERGED
## ~~P4~~ transcript_dao.listForTarget materializes full timelineJson → #969 MERGED
## ~~P5~~ SentenceRuler reallocates List<double> every 50 ms tick → #971 MERGED
## C2 LibraryViews (#970) MERGED
## C3 TakeAssessmentNotes (#973) MERGED
## C5 SurfaceStallProbe (#972) MERGED
## C1 TranscriptContent (#969) MERGED
**All 5 maintainer candidates from #968 shipped. P1, P2, P4, P5 absorbed.**

## P3 — vocabulary_item_dao.listDue over-fetches (NOT in #968)
- File: `lib/data/db/daos/vocabulary_item_dao.dart:45-56` — broad
  `nextReviewAt <= now` SELECT, then filters `lastReviewedAt` in Dart. Push
  second predicate into SQL.
- Measure: structural — rows considered vs rows returned on a seeded table.
- Impact: MED, Confidence: HIGH. Keep as Perf Improver candidate.

## P6 — Startup preferences: 4 sequential readSetting gates skeleton
- Files: `lib/core/application/app_preferences_provider.dart:113-159`,
  `lib/app.dart:297-299`.
- Problem (from #968 "Also verified, smaller"): four sequential `readSetting`
  round trips (locale, learning, native, theme) plus up to three
  canonicalization writes gate the skeleton on every signed-in cold start.
- Optimize: one bulk `WHERE key IN (...)` read plus post-frame writes.
- Measure: structural — count `readSetting` calls during a synthetic cold start
  path; today = 4 sequential awaits, target = 1.
- Risk: LOW (single seam). Impact: cold-start latency on first paint.
- Confidence: HIGH (single-file, well-bounded).
- **Status:** offered to an-lee via #968 comment on 2026-10-17. No human
  response yet. Awaiting maintainer green-light or networked-runner pick-up.

## P7 — Auto-translate fan-out: 40–80 tile rebuilds per flush
- Files: `transcript_scrollable_list.dart:439-443, 553-566`,
  `auto_translate_resolved_text.dart:26-34`,
  `transcript_repository_auto_translate.dart:115-143`.
- Problem (from #968 "Also verified, smaller"): one flush swaps the secondary
  list identity, so the virtualized window rebuilds 40–80 tiles and each
  re-resolves its secondary text (including a fresh source-key hash); the
  echo card duplicates the projection.
- Optimize: stabilize the secondary list identity so unchanged secondary text
  is delivered to unchanged tiles; dedupe the source-key hash; collapse the
  echo-card projection.
- Measure: structural — count tile rebuilds (and `Resolver` lookups) during
  one synthetic translate flush over a 1k-line transcript with ~50% untranslated.
- Risk: MED (UI correctness around translate race). Confidence: HIGH.
- **Status:** offered to an-lee via #968 comment on 2026-10-17. No human
  response yet. Conditional on maintainer green-light.

## P8 — Position tracker seek misclassification
- Files: `raw_engine_position_stream_provider.dart:11-14`,
  `display_position_provider.dart:12-16`,
  `transport_slider_position_provider.dart:10-10`,
  `karaoke_position_provider.dart:12-16`,
  `player_position_tracker.dart:107-149`,
  `position_buckets.dart:47`.
- Problem (from #968 "Also verified, smaller"): display, scrubber, karaoke
  and the tracker each re-derive one `engine.position` tick; the tracker also
  hand-rolls the bucket rule. At 2× the media delta between emits can exceed
  `kLikelySeekDeltaSeconds` (0.35 s), so bucket-crossing ticks read as seeks
  and can emit the session faster than the documented 400 ms cadence.
- Optimize: share a single derived-tick provider; centralize the seek/bucket
  classification so only one place decides it; tighten the bucket rule.
- Measure: structural — pump 20 engine ticks with realistic deltas, count
  session emissions (today can exceed 20 if a bucket crosses the 0.35 s line);
  assert the bucket rule returns false for sub-threshold delta.
- Risk: MED (player cadence contract). Confidence: MED (test coverage gap).
- **Status:** offered to an-lee via #968 comment on 2026-10-17. No human
  response yet. Conditional on maintainer green-light.

## Measurement-infrastructure gaps (docs/perf-measurement.md confirms deferred)
- No subtitle-parser throughput test. Add a deterministic 5k-line SRT parse
  microbenchmark (`lib/data/subtitle/subtitle_parser.dart`), loose ceiling.
  LOW risk, closes a real gap.
- No dedicated test/perf/ dir or benchmark CI smoke job (deferred by
  maintainers — still open as of #968).
- Only existing `*perf*` test in the repo:
  `test/features/transcript/transcript_blur_long_list_perf_test.dart`.

## Considered and de-prioritized
- Karaoke 50 ms rebuild path (transcript_scrollable_list active tile rebuilds
  ~20 Hz). Cached provider; real but tuning territory, needs DevTools
  profiling, not a blind change.
- Subtitle `_parseCache` FIFO eviction looseness (`subtitle_markup_parser.dart`)
  — LOW, cosmetic cap.
- ~~Position-tracker double enforceTick (player_position_tracker.dart)~~ —
  subsumed by P8.

## Repo-wide context
- The #827 perf audit (#828–#832) absorbed the active perf queue and all merged.
- Repo Assist shipped the eight Oct 1–8 drafts (#848 YouTube caption alias,
  #849 CHANGELOG, #851 shared timeline threshold, #852 language descriptor
  tests, #859 haptics tests, #860 `--changed-only` CI flag, lookup equality
  tightening, ai_kind_policies tests).
- Polish phase: #872/#873/#874/#875/#876 + #884 + #885.
- **2026-10-17 update:** maintainer an-lee shipped the perf deepening pass
  (#968 → #969–#973). All five PRs MERGED on 2026-10-17.
- **2026-10-18 update:** Repo Assist recommended closing #968; #968 still
  `OPEN`. Perf Improver's P6/P7/P8 remain offered but conditional.
- Remaining open issues with `performance` label: #864 (my monthly summary),
  #968 (maintainer roadmap, recommended closure). All others were either
  auto-managed or absorbed.