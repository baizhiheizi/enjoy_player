## 1. Data layer and fetch lifecycle

- [x] 1.1 Extend `transcript_fetch_states` Drift table with `lastStatus` and `lastError`; run migration and `build_runner`
- [x] 1.2 Add `TranscriptFetchStatus` enum and `TranscriptFetchCtrl` (`@Riverpod` family by `mediaId`) with idle/loading/success/empty/error transitions
- [x] 1.3 Implement concurrency guard: coalesce duplicate in-flight `resolveOnOpen` calls for the same media id
- [x] 1.4 Persist terminal fetch outcomes to `transcript_fetch_states` on success, empty, and error

## 2. Repository orchestration

- [x] 2.1 Extract `ensurePrimaryTranscript(mediaId)` from existing `_maybeSetPrimaryTranscript` priority logic
- [x] 2.2 Implement sidecar discovery: scan adjacent `.srt`/`.vtt` for local playable URIs; skip already-imported ids; call existing import path
- [x] 2.3 Add `TranscriptRepository.resolveOnOpen(mediaId, {forceCloud})` pipeline: ensure primary → sidecar import → cloud fetch (signed-in only)
- [x] 2.4 Wire fetch ctrl status updates through `resolveOnOpen` and manual refresh entry points
- [x] 2.5 Fix YouTube Worker failure handling: do not mark fetched-on-failed; surface error status for retry

## 3. Open integration

- [x] 3.1 Replace `fetchCloudTranscripts` call in `schedulePlayerOpenSideEffects` with `resolveOnOpen`
- [x] 3.2 Add unit tests for primary auto-select, sidecar import, fetch status transitions, and Worker failure path

## 4. Presentation — CC and transcript panel

- [x] 4.1 Add `transcriptFetchStatusProvider(mediaId)` export for widgets
- [x] 4.2 Update `TransportCcButton`: spinner when loading and no tracks; keep badge when tracks exist
- [x] 4.3 Update `TranscriptPanel`: skeleton/fetching copy when loading + empty lines; friendly error + retry when error
- [x] 4.4 Add l10n strings for fetching subtitles and retry affordances (`flutter gen-l10n`)

## 5. Presentation — subtitle picker and empty state

- [x] 5.1 Show background-fetch loading indicator in `SubtitleTrackPickerSheet` (banner or shared refresh spinner state)
- [x] 5.2 Route manual “Refresh from cloud” through shared fetch ctrl (remove isolated `_refreshingCloud` duplication)
- [x] 5.3 Extract shared busy-button pattern for Extract/Import; use in picker and `TranscriptEmptyState`
- [x] 5.4 Add widget tests for CC spinner, panel loading vs empty, and picker refresh loading

## 6. Documentation and verification

- [x] 6.1 Update `docs/features/transcript.md` with auto sidecar import, fetch lifecycle UI, and primary auto-select behavior
- [x] 6.2 Run `flutter analyze` and `flutter test`; fix any regressions
