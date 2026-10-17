# Performance backlog — Enjoy Player

**MAJOR UPDATE 2026-10-17:** Maintainer an-lee has shipped an authoritative
performance-first architecture review that **supersedes most of the prior P1–P5
backlog**. Issue #968 ("Architecture review (pass 4): performance deepening
candidates") names five targets — TranscriptContent (C1), LibraryViews (C2),
TakeAssessmentNotes (C3), RulerGeometry (C4), SurfaceStallProbe (C5) — and
the maintainer has opened 5 implementation PRs:

- **#969** C1 TranscriptContent — CI green, MERGEABLE
- **#970** C2 LibraryViews — CI green, MERGEABLE
- **#971** C4 RulerGeometry — locally 6733 passed (CI pending)
- **#972** C5 SurfaceStallProbe — locally 6730 passed (CI pending)
- **#973** C3 TakeAssessmentNotes — locally 6733 passed (CI pending)

All branches target `main` at `e6d067f` and were authored by the maintainer
(not Perf Improver). P1, P2, P5 in this file are largely **addressed** by
#969, #970, #971, #972, #973 — drop them from the next batch and reorient on
the items the maintainer named but did NOT PR: the three "Also verified,
smaller" candidates at the bottom of #968. See new P6–P8 below.

Crosswalk (old backlog → maintainer's plan):

| Old | Mapped to | Status |
|---|---|---|
| P1 (transcript count O(n×m)) | C1 (#969) | addressed |
| P2 (TranscriptStreamGroup double-resolve) | C1 (#969) | addressed |
| P3 (vocabulary_item_dao.listDue) | (not in #968) | keep, lower priority |
| P4 (transcript_dao.listForTarget) | C1 (#969) | addressed |
| P5 (SentenceRuler 50 ms realloc) | C4 (#971) | addressed |
| Considered: karaoke 50 ms rebuild | (not in #968) | keep, tuning territory |
| Considered: subtitle `_parseCache` FIFO | (not in #968) | LOW cosmetic |
| Considered: position-tracker enforceTick | overlaps P8 below | keep as P8 |

Prioritized by impact × feasibility × measurability. Source: Explore subagent
sweep (2026-10-08) over transcript rendering, subtitle parsing, search,
position ticks, DB queries, memory; refreshed against #968 on 2026-10-17.

## ~~P1~~ Transcript recording-count O(n×m)  → #969 (ADDRESSED)
- File: `lib/features/transcript/domain/transcript_recording_counts.dart:22-38`
- Replaced by the maintainer's C1 revision-keyed seam. Drop from backlog.

## ~~P2~~ TranscriptStreamGroup double-resolve → #969 (ADDRESSED)
- File: `lib/features/transcript/data/transcript_repository_lines.dart:48-60`
- Replaced by the maintainer's C1 fix. Drop from backlog.

## P3 — vocabulary_item_dao.listDue over-fetches (NOT in #968)
- File: `lib/data/db/daos/vocabulary_item_dao.dart:45-56` — broad
  `nextReviewAt <= now` SELECT, then filters `lastReviewedAt` in Dart. Push
  second predicate into SQL.
- Measure: structural — rows considered vs rows returned on a seeded table.
- Impact: MED, Confidence: HIGH. Keep as Perf Improver candidate.

## ~~P4~~ transcript_dao.listForTarget materializes full timelineJson → #969 (ADDRESSED)
- Addressed by the maintainer's C1 revision-keyed projection (`selectOnly` /
  LIMIT 1 for revision miss). Drop from backlog.

## ~~P5~~ SentenceRuler reallocates List<double> every 50 ms tick → #971 (ADDRESSED)
- `lib/features/player/presentation/widgets/transport/sentence_ruler.dart:97-101`
- Replaced by the maintainer's C4 RulerGeometry memoization + pixel-quantized
  playhead paint-only path. Drop from backlog.

## P6 — Startup preferences: 4 sequential readSetting gates skeleton  [NEW, top candidate]
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

## P7 — Auto-translate fan-out: 40–80 tile rebuilds per flush  [NEW]
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

## P8 — Position tracker seek misclassification (overlaps "Playback tick" smaller)  [NEW]
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

## Repo-wide context (from repo-assist 2026-10-10 run #841)
- The #827 perf audit (#828–#832) absorbed the active perf queue and all merged.
- Repo Assist shipped the eight Oct 1–8 drafts (#848 YouTube caption alias,
  #849 CHANGELOG, #851 shared timeline threshold, #852 language descriptor
  tests, #859 haptics tests, #860 `--changed-only` CI flag, lookup equality
  tightening, ai_kind_policies tests).
- Polish phase: #872/#873/#874/#875/#876 (lookup banner / library cloud / shell
  nav / player echo) + #884 (EnjoyThemeTokens split) + #885 (lookup credits chip).
- The #870 follow-up #793 (macOS integrated title bar) still needs hardware.
- **2026-10-17 update:** maintainer an-lee shipped the perf deepening pass
  (#968 → #969–#973). My P1/P2/P4/P5 in this file map to those PRs.
- Remaining open issues (#771, #797, #840, #841, #850, #864, #886, #968) are
  automation / auto-managed. #968 is the active perf roadmap.