# Repo Assist — Enjoy Player

## Backlog progress
- Issues commented on: #309, #310, #355, #383, #474, **#501**
- PRs created (merged by an-lee): #486 stream subscription leak, #496 PlayerLaunchRequest tests, #498 setup_logging dedupe, **#499 perf transport-bar/surface-host**, **#500 sync_types tests**
- PR created (draft, awaiting review): `repo-assist/setup-flutter-load-bearing-note-2026-07-29` — addresses #501

## Pending actions for maintainer
- **Review PR** (draft): setup-flutter load-bearing `flutter --version` comments — issue #501. PR number assigned post-apply.

## Known environment limitations
- Agentic runner Flutter SDK read-only → `dart format` / `analyze` / `test` may fail on cache writes. This is exactly the invariant #501 now documents.
- No git credentials for network operations.
- Linter pass may revert working-tree changes after a safe-outputs PR creates — confirmed cosmetic, NOT blocking merges (verified via PR #499, #500).

## Carry-over coding-impl candidates
- `logNamed` consistency in `transcript_line_recording_counts_provider.dart` (1 site with `Logger(...)` direct).
- `throw Exception(...)` → typed errors in `youtube_caption_fetcher.dart` (4 sites).
- Testing coverage queue: `hotkey_definitions.dart`, `asr_generation_job.dart`, `launch_pay_url.dart`.

## Task 8 perf candidates queued from 2026-07-29 Explore agent (3 LOW-risk PRs)

**PR-A** `perf(discover): per-locale DateFormat cache in DiscoverFeedTile` — `discover_feed_tile.dart:201-217`. Avoids ~6–36 `DateFormat` allocs/rebuild (each ~1 KB + ICU `DateSymbols`).

**PR-B** `perf(player): disableAnimationsOf() in transport bar` — `global_transport_bar.dart:451`. Avoids transport-bar rebuilds on keyboard / padding / DPI ticks. Aligns with existing pattern in `enjoy_tappable.dart:43`, `skeleton.dart`, `library_screen.dart:144`.

**PR-C** `perf(transcript): hoist inline RegExp allocations` (bundle of 4) —
`global_transport_bar.dart:39-42` `_formatRateCore`, `transcript_line_alignment.dart:76` `echoReferencePlainText`, `vocabulary_context_builder.dart:23-28` `plainCueText`, `auto_translate.dart:200` `normalizeAutoTranslateSourceText`. Trivial top-level `final` hoists. See `notes-2026-07-29.md` for citations.

## Future investigations
- Architectural dedupe (#17, #39, #40).
- `settings_screen.dart` below ~120 LOC requires per-section sliver extraction (prior proposal expired).
