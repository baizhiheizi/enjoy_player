## Why

When a user opens media, transcript fetching runs in the background but the UI treats “no lines yet” as “no subtitles exist.” The CC button, transcript panel, and subtitle picker give no consistent loading feedback during cloud or YouTube Worker fetches (which can take up to ~60 seconds). Local sidecar `.srt`/`.vtt` files are never discovered automatically, and tracks already in SQLite may not appear in the panel if no primary transcript is assigned. This feels broken compared to pro media apps and undermines the echo/shadow-reading workflow.

## What Changes

- Introduce an observable **transcript fetch lifecycle** (idle → loading → success / empty / error) shared by background open fetch and manual “Refresh from cloud.”
- **CC transport button** shows a loading spinner while fetch is in progress; keeps the existing badge when tracks are available.
- **Transcript panel** distinguishes loading, empty (confirmed), and error states instead of showing “No transcript” during an active fetch.
- **Subtitle picker** reflects background fetch status (not only manual refresh spinners).
- **Auto-select primary transcript** on open when tracks exist in SQLite but `echo_sessions.transcript_id` is unset (same source-priority rule as delete-reassign).
- **Auto-import sidecar subtitles** on open for local media: discover adjacent `.srt`/`.vtt` (same basename) and import silently.
- **Align empty-state actions** (Extract / Add subtitle) with picker loading spinners during long operations.
- **Friendly error + Retry** in the transcript panel (match picker patterns).
- Embedded subtitle **ffmpeg extract remains manual** on open (too heavy for automatic background work).
- Cloud / YouTube fetch remains **signed-in only** (no scope change to auth policy).

## Capabilities

### New Capabilities

- `transcript-loading`: Observable fetch lifecycle, auto-load on open (cloud, YouTube, sidecar), primary auto-selection, and coordinated loading UI across CC button, transcript panel, and subtitle picker.

### Modified Capabilities

<!-- No existing openspec/specs capabilities yet. Feature behavior delta will be captured in the new spec and docs/features/transcript.md during implementation. -->

## Impact

- **Application**: `player_open_side_effects.dart`, new fetch-status provider(s), `TranscriptRepository.fetchCloudTranscripts` coordination.
- **Presentation**: `transport_cc_fullscreen.dart`, `transcript_panel.dart`, `transcript_empty_state.dart`, `subtitle_track_picker_sheet.dart`.
- **Data**: Possible extension of `transcript_fetch_states` (status / last error) or in-memory + DB hybrid; sidecar discovery in repository or open side effects.
- **Localization**: New strings for fetching subtitles, retry hints.
- **Docs**: Update `docs/features/transcript.md` when behavior changes.
- **Tests**: Repository fetch lifecycle, primary auto-select, sidecar discovery, widget tests for loading states.
