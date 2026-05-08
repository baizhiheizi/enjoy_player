# Feature: Transcript

## MVP behavior

- Primary transcript = `echo_sessions.transcript_id` for the latest session on `(targetType, targetId)` (same id as library media row).
- Import `.srt` / `.vtt` via `SubtitleParserFacade` storing JSON in `transcripts.timeline_json`.
- Tap line → seek + optional echo region update (via `PlayerInteractions`).
- **Track / import entry**: Use the player **CC** control (opens subtitle sheet). The transcript panel has no duplicate header row.
- Subtitle track picker uses shared bottom-sheet theming and spacing from `EnjoyThemeTokens`.
- **Windows embedded subtitles**: Demux uses **`ffmpeg.exe`** next to `enjoy_player.exe` (installed from [`windows/ffmpeg/ffmpeg.exe`](../../windows/ffmpeg/ffmpeg.exe) when present at build time) or **`ffmpeg` on PATH**. If neither is available, embedded auto-extraction no-ops; users can still import `.srt` / `.vtt`. Details: [`windows/ffmpeg/README.md`](../../windows/ffmpeg/README.md).
- **On-video subtitles**: Disabled by default (`SubtitleTrack.no()` after open + `SubtitleViewConfiguration.visible: false` on [`Video`](../../lib/features/player/presentation/layouts/video_player_layout.dart)); cues are shown in the transcript panel instead.
- **Markup**: SSA/HTML-like cues (`<font color="…">`, `<b>`, `<i>`, `<br>`, etc.) are parsed in the transcript panel via `parseSubtitleMarkup` (`lib/data/subtitle/subtitle_markup_parser.dart`); colors and styles render as rich text instead of raw tags.
- **Line UI**: Each cue has a **header row** (timestamp first; room for more labels). Body text follows on the next lines. Row backgrounds are **transparent** by default; **hover**, **active playback**, **echo-range**, and **active inside echo** use distinct tints (playback within the echo region blends echo orange with primary vs plain active vs echo-only lines).
- **Auto-follow**: While the engine is **playing**, the list scrolls the **active cue** into view when it would be off-screen (`Scrollable.ensureVisible` on the active line). When paused, the list does not auto-scroll.
- **Echo region** (echo mode on): **Expand / shrink** controls sit **between** the transcript list and the shadow panel as separate rows (not inside the cue card). **Cue lines** use one merged rounded **transcript card**; **shadow reading** is a **second card** below with recording list, pitch contour (collapsible), and record/stop — see [`ShadowReadingPanel`](../../lib/features/shadow_reading/presentation/shadow_reading_panel.dart). Take duration is derived from the **WAV header** (see [`wav_duration_ms`](../../lib/core/audio/wav_duration_ms.dart)). Playback uses [`shadow_recording_playback`](../../lib/core/audio/shadow_recording_playback.dart): **Windows** uses `winmm` `PlaySound` (no NuGet); **Linux** uses `paplay`/`aplay`; **macOS / iOS / Android** use **`just_audio`**. **`audioplayers_windows`** is avoided — it pulls NuGet (`Microsoft.Windows.ImplementationLibrary`) and fails in many CI/local setups.

## Future

- Multiple languages, editing timelines, auto-translate, export — parity with web `TranscriptDisplay`.
