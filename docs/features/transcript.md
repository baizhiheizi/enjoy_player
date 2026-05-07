# Feature: Transcript

## MVP behavior

- Primary transcript = first row returned by `TranscriptDao.watchForMedia`.
- Import `.srt` / `.vtt` via `SubtitleParserFacade` storing JSON in `lines_json`.
- Tap line → seek + optional echo region update (via `PlayerInteractions`).
- Subtitle track picker uses shared bottom-sheet theming and spacing from `EnjoyThemeTokens`.

## Future

- Multiple languages, editing timelines, auto-translate, export — parity with web `TranscriptDisplay`.
