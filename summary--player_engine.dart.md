<size>7441</size>

# `lib/features/player/application/player_engine.dart`

- `abstract class PlayerEngine` — the contract implemented by `MediaKitPlayerEngine` and `YouTubePlayerEngine`.
- Streams: `position`, `duration`, `playing`, `buffering`, `videoAspectRatioStream`, `mkTracksStream` (nullable; null for WebView).
- Flags: `supportsVideoPosterCapture`, `supportsSubtitleDisabling`, `transportSnapshot`.
- Methods: `open`, `disableRenderedSubtitles`, `seek`, `setRate`, `setVolumeNormalized`, `playOrPause`, `play`, `pause`, `stop`, `screenshot`, `warmVideoSurface` (Windows only), `dispose`.
- `aspectRatioFromVideoParams` — fallback width/height from `VideoParams`.
- Hard rule: only this file and `player_controller.dart` may instantiate `media_kit Player()`.
