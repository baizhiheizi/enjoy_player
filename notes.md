# Repo Assist — Enjoy Player

## Backlog progress
- Issues commented on: #309, #310, #355, #383, #474, **#501**
- PRs created (merged by an-lee): #486 stream subscription leak, #496 PlayerLaunchRequest tests, #498 setup_logging dedupe, #499 perf transport-bar/surface-host, #500 sync_types tests, **#503 ci/setup-flutter warm-cache invariant (closed #501)**
- PR created (draft, awaiting review): `repo-assist/perf-regex-hoist-disableanim-dateformat-cache-2026-07-29` — bundled perf refactors (regex hoist + MediaQuery scope + per-locale DateFormat cache). PR number pending apply.

## Pending actions for maintainer
- **Review PR** (draft): bundled perf refactors — branch `repo-assist/perf-regex-hoist-disableanim-dateformat-cache-2026-07-29` @ `b233b322`, 7 files / +59 / -19.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes. This is exactly the invariant #501 / #503 now documents.
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — confirmed cosmetic, NOT blocking merges (verified via PR #499, #500, #503).

## Carry-over coding-impl candidates
- `logNamed` consistency in `transcript_line_recording_counts_provider.dart` (1 site with `Logger(...)` direct).
- `throw Exception(...)` → typed errors in `youtube_caption_fetcher.dart` (4 sites).
- Testing coverage queue: `hotkey_definitions.dart`, `asr_generation_job.dart`, `launch_pay_url.dart`.

## Task 8 perf candidates (all shipped in 2026-07-29-run2 bundled PR)
- PR-A ✅ DiscoverFeedTile per-locale DateFormat cache.
- PR-B ✅ Transport bar `MediaQuery.disableAnimationsOf` (drops full MediaQuery dep).
- PR-C ✅ Hoisted regex allocations (transcript_markup + transcript_line_alignment + vocabulary_context_builder + auto_translate + global_transport_bar._formatRateCore). Also deduped the duplicate `_tagStripRegExp` between `subtitle_markup_parser.dart` and `transcript_markup.dart` by exposing public `tagStripRegExp` / `whitespaceSplitRegExp` constants.

## Future investigations
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (prior proposal expired).
