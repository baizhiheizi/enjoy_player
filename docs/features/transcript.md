# Feature: Transcript

## MVP behavior

- Primary transcript = first row returned by `TranscriptDao.watchForMedia`.
- Import `.srt` / `.vtt` via `SubtitleParserFacade` storing JSON in `lines_json`.
- Tap line → seek + optional echo region update (via `PlayerInteractions`).
- **Track / import entry**: Use the player **CC** control (opens subtitle sheet). The transcript panel has no duplicate header row.
- Subtitle track picker uses shared bottom-sheet theming and spacing from `EnjoyThemeTokens`.
- **Windows fallback**: Embedded subtitle auto-extraction is disabled on Windows in current builds (ffmpeg plugin gap); users can still import external `.srt` / `.vtt`.

## Future

- Multiple languages, editing timelines, auto-translate, export — parity with web `TranscriptDisplay`.
