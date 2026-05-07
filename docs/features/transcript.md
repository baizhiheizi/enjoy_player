# Feature: Transcript

## MVP behavior

- Primary transcript = first row returned by `TranscriptDao.watchForMedia`.
- Import `.srt` / `.vtt` via `SubtitleParserFacade` storing JSON in `lines_json`.
- Tap line → seek + optional echo region update (via `PlayerInteractions`).

## Future

- Multiple languages, editing timelines, auto-translate, export — parity with web `TranscriptDisplay`.
