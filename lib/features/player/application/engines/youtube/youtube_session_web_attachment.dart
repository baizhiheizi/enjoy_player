import 'package:enjoy_player/features/player/application/engines/youtube/youtube_js_channel.dart';

/// Per-session webView attachment contract.
///
/// The session composes the audible policy and the poll loop, both of which
/// need WebView-bound actions (reapply volume, play, controller lookup,
/// first-playing ack). The webView controller builds a [YoutubeSessionWebAttachment]
/// and passes it to [YoutubeSession.attachWebView] once it owns an
/// [InAppWebViewController]. Concrete class (not abstract) so the controller
/// can adapt its existing `webController` getter without overriding.
class YoutubeSessionWebAttachment {
  YoutubeSessionWebAttachment({
    required this.jsChannel,
    required this.onFirstPlaying,
    required this.reapplyVolume,
    required this.healPlay,
  });

  /// Live controller getter (nullable — the WebView may be detached).
  final YoutubeJsChannel? Function() jsChannel;

  /// Fires on the first authoritative `playing` after open.
  final void Function() onFirstPlaying;

  /// Re-applies the session's stored normalized volume to the WebView.
  final Future<void> Function() reapplyVolume;

  /// Re-issues a play after the volume-restore heal window.
  final Future<void> Function() healPlay;
}
