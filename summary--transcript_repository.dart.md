<size>23486</size>

# `lib/features/transcript/data/transcript_repository.dart`

- `_LinesCacheEntry(updatedAt, lines)` — internal cache for lines.
- `_decodeTimeline(timelineJson)` — deserializes timeline JSON into `List<TranscriptLine>`.
- `_trackFromRow(row)` — maps a `TranscriptRow` to a `TranscriptTrack`.
- `_listEqualsTranscriptTrack(previous, current)` — element-wise equality on `TranscriptTrack` lists (`identical`, length, then per-element `==`). Used by `watchTracks` via `Stream.distinctBy` to absorb no-op Drift ticks.
- Imports `stream_distinct.dart` extension and `youtube_video_identity.dart`.
