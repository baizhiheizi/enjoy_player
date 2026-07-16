<!-- hash: engine-2026-07-16 -->

# lib/features/player/application/player_engine.dart

Abstract `PlayerEngine` contract implemented by `MediaKitPlayerEngine` and `YouTubePlayerEngine`. Exposes:

- `Stream<Duration> position`, `Stream<Duration> duration`, `Stream<bool> playing`, `Stream<bool> buffering`
- `Stream<void> completed` (ADR-0044 deterministic loop)
- `Stream<mk.Tracks>? mkTracksStream`, `bool supportsVideoPosterCapture`, `bool supportsSubtitleDisabling`
- `videoAspectRatioStream` (letterboxing), `transportSnapshot`
- `buildVideoStage(...)`, `open(PlayableSource)`, `seek`, `disableRenderedSubtitles`, `screenshot`

Only `MediaKitPlayerEngine` / `PlayerController` may construct `media_kit` `Player()` (ADR-0003, ADR-0015). YouTube uses `flutter_inappwebview`, not media_kit.
