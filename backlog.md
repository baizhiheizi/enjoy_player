# Performance backlog — Enjoy Player

**UPDATE 2026-10-20:** Issue #968 was **CLOSED** by `@an-lee` on 2026-10-20
10:58 UTC with all five candidates shipped as #969–#973. The "Also verified,
smaller" candidates (P6 startup prefs, P7 auto-translate fan-out, P8 position
tracker) remain out of scope and unclaimed.

**UPDATE 2026-10-20 (2nd):** The "networked runner" precondition for P3/P6/P7/P8
is **no longer required** — see the offline harness recipe in `commands.md`.
Code-changing perf PRs can be authored and measured from this sandbox. P9
(subtitle SRT parse) shipped this way.

**Open items below are Perf Improver candidates.**

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
- **Re-verified 2026-10-27:** still present, unchanged.

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
- Files: **STALE — `transcript_scrollable_list.dart` was split by #1007**
  into `transcript_virtual_items.dart`, `transcript_auto_scroll_controller.dart`,
  `transcript_line_item_builder.dart` and a reduced
  `transcript_scrollable_list.dart`; also
  `auto_translate_resolved_text.dart`,
  `transcript_repository_auto_translate.dart`.
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
- **Status:** offered to an-lee via #968 comment on 2026-10-17. #968 was
  closed by an-lee on 2026-10-20; the offer stands but needs a fresh
  channel. **Not re-verified on the post-#1007 tree** — the Explore
  subagent tasked with that failed with a 503 on 2026-10-25. Re-check the
  file layout before acting.
- Note: `resolveAutoTranslateTextForDisplay` in
  `auto_translate_resolved_text.dart` still calls
  `resolveAutoTranslateSecondaryText` per line — the per-tile
  re-resolution cost is still visible in the current tree.

## P8 — Position tracker seek misclassification (NARROWED 2026-10-27)
- Files: `raw_engine_position_stream_provider.dart`,
  `display_position_provider.dart`,
  `transport_slider_position_provider.dart`,
  `karaoke_position_provider.dart`,
  `player_position_tracker.dart:124-132`,
  `position_buckets.dart`.
- Problem (from #968 "Also verified, smaller"): display, scrubber, karaoke
  and the tracker each re-derive one `engine.position` tick; the tracker also
  hand-rolls the bucket rule. At 2× the media delta between emits can exceed
  `kLikelySeekDeltaSeconds` (0.35 s), so bucket-crossing ticks read as seeks
  and can emit the session faster than the documented 400 ms cadence.
- **Update 2026-10-27:** the *shared raw engine position stream* half has
  **landed** (`raw_engine_position_stream_provider.dart` — "Single shared raw
  engine position stream so display/scrubber/tracker all derive from one
  canonical source"). What remains is the **classification**: the tracker
  still computes `bucket = pos.inMilliseconds ~/ positionBucketMs` by hand
  and applies its own `kLikelySeekDeltaSeconds` threshold, so the rule lives
  in two places. Optimize: centralize the seek/bucket classification so only
  one place decides it; tighten the bucket rule.
- Measure: structural — pump 20 engine ticks with realistic deltas, count
  session emissions (today can exceed 20 if a bucket crosses the 0.35 s line);
  assert the bucket rule returns false for sub-threshold delta.
- Risk: MED (player cadence contract). Confidence: MED (test coverage gap).
- **Status:** offered to an-lee via #968 comment on 2026-10-17. No human
  response yet. Conditional on maintainer green-light.

## P9 — Subtitle SRT parse throughput (SHIPPED 2026-10-20 — PR #1006 MERGED)
- File: `lib/data/subtitle/subtitle_parser.dart` — `SrtParser.parse`, reached
  from `transcript_repository_subtitle_import.dart` and
  `embedded_subtitle_service.dart` on the UI isolate.
- Problem: every parse ran two whole-string `replaceAll` passes to normalize
  line endings (even LF-only input), matched the cue-index line with a regex
  per cue, and re-parsed every timestamp through `tryParseHmsDuration`
  (allocating a `Duration` per timestamp).
- Fix: `_splitLines` skips normalization when the content has no `\r` (with a
  fallback to the original path for lone-CR / mixed endings); `_isAllDigits`
  replaces the index regex; `_parseTs` + `_digitsToInt` read the timestamp
  digits directly.
- Measured (isolated processes, 100 warmup + 200 measured, median of 3 round
  medians): 5000 cues 10.34 → 5.50 ms (1.88x LF), 11.98 → 6.15 ms (1.95x
  CRLF); 20000 cues 39.48 → 22.85 ms (1.73x LF), 40.11 → 23.35 ms (1.72x CRLF).
- Correctness: 60,055 differential cases vs the pre-change parser, 0
  mismatches; the new structural tests also pass against the original parser.
- **Status: MERGED by an-lee on 2026-10-20** (PR #1006,
  "perf(subtitle): parse SRT ~1.9x faster"). Shipped in v0.10.0.
- **Do not extend to VTT without a fresh measurement** — a VTT variant was
  tried and measured ≈1.5 % (noise), then reverted.

## P10 — Timeline revision character count (SHIPPED 2026-10-25, draft PR open)
- Files: `lib/features/transcript/data/transcript_timeline_codec.dart`
  (`timelineJsonCharacterCount`), `transcript_repository.dart`,
  `transcript_repository_lines.dart`,
  `transcript_repository_auto_translate.dart`.
- Problem: the decode memo is keyed on `(updatedAt, timelineJson character
  count)`. The count was `json.runes.length` — a rune-by-rune walk of the
  whole `timelineJson` blob (documented as 1–10 MB in
  `docs/features/transcript.md`) — and the repository derived that same
  revision **three times per tick** (twice in `_preloadLinesForRow`, once in
  `_linesForRow`), plus once more on every auto-translate flush (every
  300 ms during translation).
- Fix: a UTF-16 code-unit scan (surrogate pair = 1 character, unpaired
  surrogate = 1 — identical to `String.runes.length` and SQLite `length()`),
  and the revision is derived once per row and threaded through the private
  preload/decode helpers. Public API unchanged.
- Measured (isolated processes, 100 warmup + 200 measured, 3 rounds):
  5000 cues (573 KB) 3.138 → 0.137 ms (22.9x); 20000 cues (2.3 MB)
  9.763 → 0.483 ms (20.2x). Scan-only 6.7–9.5x, redundancy-only 6.7–7.8x.
- Correctness: 20,000 fuzz cases + curated edge cases against
  `String.runes.length`, 0 mismatches.
- Status: draft PR open on `perf-assist/timeline-revision-scan` (commit
  `fda2e6c`). The PR number is assigned when the framework pushes the
  bundle — it was not known during the run.
- **UPDATE 2026-10-27: PR #1071 was MERGED by an-lee on 2026-10-26**
  ("perf(transcript): count timeline characters ~20x faster", landed as
  commit `5a4a6c1`). Perf Improver's second merged code-changing PR.
- **This supersedes the "P4" style of scan cost noted in #968** — the SHA-1
  removal in issue #810 D5 left an O(n) walk behind, which is what P10
  removed.

## P11 — Familiar-form IPA derivation (SHIPPED 2026-10-27, draft PR open)
- File: `lib/data/subtitle/ipa_mapping.dart` (pure Dart, no Flutter
  imports — the only hot-path file so far that is fully measurable offline).
- Problem: `wordIpaSpelling` is called **per word** from
  `TranscriptAlignedWords.build` (`transcript_word_ipa_layer.dart:93`) on
  every line rebuild, and `transcript_line_tile.dart:214` calls
  `transcriptWordsHavePhones(words)` to decide whether the overlay applies.
  The tile watches the karaoke highlight provider, so the active line's
  words are re-derived on every highlight change. The derivation did three
  expensive things per phoneme:
  1. `_matchesCatalog` copied and re-sorted the whole consonant/vowel
     catalog on every call — but the answer is "does any entry prefix this
     value", so the sort never changed the result. The first pass over the
     unsorted catalog was also redundant with the sorted prefix scan.
  2. A `RegExp('[ˈˌ]')` was compiled per phoneme, in `convertIpaToNormal`
     and again in `convertWordIpaToNormal`.
  3. `_matchPhonemeAt` walked all ~160 phoneme keys for every character,
     though only keys starting with that character can match.
- Fix: the catalog is answered from a cached `Set` with the prefix scan as
  the fallback; the stress mark is found by a code-unit scan; the phoneme
  table is bucketed by its first code unit (each bucket keeps the
  longest-first order, so the longest-match rule is unchanged); the tokenizer
  and converters read code units instead of allocating one-character
  strings. Public API unchanged.
- Measured (isolated processes, 100 warmup + 200 measured, n=8 process runs
  per implementation): 2400-word corpus (200 lines x 12 words) 34.4 ms ->
  5.6 ms per pass — ~6.1x at the median, 4.3x in the worst pairing. The
  in-repo microbenchmark reports 8.15 ms/pass (single warmup, so colder).
  The "after" figures are bimodal across processes (5.3 vs 7.8 ms): a
  given process lands in one of two JIT tiers — report the range, not one
  number. The output is byte-identical (the sink matches exactly).
- Correctness: 160,000 differential cases against the previous
  implementation over the full IPA alphabet, 0 mismatches; plus 120 golden
  vectors captured from the previous implementation and the curated edge
  cases (trailing stress mark, second stress mark, longest-match phoneme,
  unknown character, astral character) pinned in
  `test/data/subtitle/ipa_mapping_perf_test.dart`.
- Status: draft PR open on `perf-assist/ipa-familiar-form-derivation`
  (commit `4ebeffa`). The PR number is assigned when the framework pushes
  the bundle — it was not known during the run.
- **Next in this area:** `wordIpaSpelling` is still recomputed for every
  word on every rebuild of the same line. Memoizing it per `TranscriptWord`
  (a Freezed value type, so hashable) would remove the repeated work
  entirely, but it needs a cache-eviction story — do not add one without a
  measurement.

## P10b — Remove the remaining character-count scan (NEXT, needs a maintainer call)
- File: `lib/features/transcript/data/transcript_timeline_codec.dart` +
  `transcript_repository_lines.dart`.
- Problem: even after P10 the count is still an O(n) walk of the payload.
  `TranscriptDao.watchRevisionById` / `metaById` already compute
  `length(timeline_json)` **in SQLite**, so the watch path could take the
  length from the SQL revision projection instead of re-deriving it from
  the row.
- Why it was NOT done in P10: it changes which value keys the decode memo.
  The SQL revision and the row-derived revision agree by construction today,
  but in the race between the SQL read and the row fetch the two can
  differ, and the memo would then be keyed by the stale revision. That is
  still correct (the next tick re-decodes) but it is a semantic change to
  the memo-key contract, so it needs maintainer sign-off.
- Measure: structural — count `timelineJsonCharacterCount` calls per
  revision tick (today 1; target 0 on the watch path).
- Risk: MED (memo-key contract). Confidence: MED.

## Measurement-infrastructure gaps (docs/perf-measurement.md confirms deferred)
- ~~No subtitle-parser throughput test.~~ **DONE 2026-10-20**:
  `test/data/subtitle/subtitle_parser_perf_test.dart` — deterministic 5000-cue
  scale fixture, LF/CRLF/lone-CR/mixed-ending equivalence, accepted timestamp
  forms, plus a `skip:`-marked local-only microbenchmark with a loose ceiling.
  Linked from `docs/perf-measurement.md`.
- ~~No timeline character-count test.~~ **DONE 2026-10-25**:
  `test/features/transcript/transcript_timeline_character_count_perf_test.dart`.
- ~~No familiar-form IPA test.~~ **DONE 2026-10-27**:
  `test/data/subtitle/ipa_mapping_perf_test.dart` — 120 golden vectors
  captured from the pre-optimization implementation, the stress-mark and
  longest-match semantics, a 2400-word scale fixture, and a `skip:`-marked
  local-only microbenchmark (8.15 ms/pass, ceiling 100 ms). Linked from
  `docs/perf-measurement.md`.
- No dedicated test/perf/ dir or benchmark CI smoke job (deferred by
  maintainers — still open as of #968). Do not add unilaterally.
- Only other `*perf*` test in the repo:
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
- **2026-10-19 update:** HEAD on main at `8d283ae` (PR #989 tier_catalog
  split). Maintainer an-lee shipped two adjacent refactors (#988 ASR
  cancellation guard, #989 tier_catalog) earlier today. Repo Assist opened
  #991 as a follow-up test for #989. No new human engagement on #968;
  P6/P7/P8 still conditional on maintainer green-light or networked runner.
- **2026-10-20 update:** HEAD on main at `0174699` (bump v0.10.0, #999).
  **#968 CLOSED by an-lee** at 10:58 UTC. Open draft PRs #1000 / #1003 are
  Repo Assist's. Perf Improver opened its first code-changing PR in 13 runs
  (P9, subtitle SRT parse) using the offline harness — see `commands.md`.
- **2026-10-21 → 2026-10-25 update:** heavy maintainer activity — #1007
  (transcript_scrollable_list split), #1010 (release pipelines), #1015
  (DST-safe relative-day label), #1023 (docs drift), #1038 (YouTube WebView
  mount gate), #1043 (code-health audit), #1046 (disposed WidgetRef),
  #1048 (macOS secure storage), #1062 (duplicate-code fixes), #1047 (bump
  v0.10.1). **P9 / PR #1006 was MERGED by an-lee on 2026-10-20** and
  shipped in v0.10.0 — Perf Improver's first merged code-changing PR.
  On 2026-10-25 Perf Improver shipped P10 (timeline revision character
  count) as a second code-changing PR, via the offline harness.
- **Issue visibility on 2026-10-25:** the MCP integration now returns **no
  readable open issues** — the 9 open issues the API lists are all dropped
  by the integrity policy, including #864. A `performance`-label query
  returns `[]`. Task 5 therefore has no target; do not manufacture one.
- **2026-10-27 update:** still no readable issues (#864 among them). The
  Perf Improver **Actions** API *is* readable, so the monthly summary's run
  history can be rebuilt from
  `actions_list(method=list_workflow_runs, resource_id=perf-improver.lock.yml)`
  — filter the JSON for `workflow_runs` and take `created_at` + `id`.
  October 2026 runs are #58–#72 (2026-10-12 → 2026-10-27); the workflow was
  idle between 2026-08-31 and 2026-10-12.
- Remaining open issues with `performance` label: #864 (my monthly summary).
  #968 is closed. All others were either auto-managed or absorbed.
