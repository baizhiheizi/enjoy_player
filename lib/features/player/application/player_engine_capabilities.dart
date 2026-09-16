/// Per-engine capability interfaces of the player seam (issue #720).
///
/// [PlayerEngine] is the transport contract every engine implements. What only
/// *some* engines can do lives here as capability interfaces call sites branch
/// on with `is` — never on a concrete engine class (player.md "Engine
/// contract", issue #595). The only places allowed to name a concrete engine
/// class remain the stage widgets + resolver, the YouTube WebView host, and
/// the engine construction sites (`PlayerController` / engine binding / swap
/// coordinator).
library;

import 'dart:typed_data';

import 'package:media_kit/media_kit.dart' as mk;

/// Frame-capture capability (issue #720).
///
/// Only engines that decode frames natively can produce a still image
/// ([MediaKitPlayerEngine]); the YouTube WebView screenshot captures the HTML
/// chrome, not the composited video frame — it renders as a solid black
/// rectangle — so YouTube does not implement this.
abstract interface class PosterCapture {
  /// Whether [screenshot] can produce stored video thumbnails.
  bool get supportsVideoPosterCapture;

  /// Encoded frame capture (`image/jpeg`, `image/png`, or raw when [format]
  /// is null).
  Future<Uint8List?> screenshot({String? format});
}

/// Embedded-subtitle control capability (issue #720).
///
/// Only engines with a libmpv-style track list implement it
/// ([MediaKitPlayerEngine]). YouTube has no embedded subtitle track to
/// disable — native YouTube CC is force-suppressed in the WebView inject
/// script instead (see docs/features/youtube.md Captions).
abstract interface class SubtitleTrackControl {
  /// Whether [disableRenderedSubtitles] does anything.
  bool get supportsSubtitleDisabling;

  Future<void> disableRenderedSubtitles();

  /// libmpv / media_kit subtitle tracks; `null` before a player exists. The
  /// media_kit type is intentional here: this capability IS the vendor track
  /// list, and keeping it off [PlayerEngine] keeps the transport contract
  /// vendor-free (issue #720).
  Stream<mk.Tracks>? get mkTracksStream;
}

/// Marker capability: this engine plays YouTube sources through the WebView
/// (ADR-0015). The de-facto type tag `supportsYouTubePlayback` became this
/// interface so call sites ask `engine is YoutubePlaybackEngine` instead of
/// reading a boolean off the transport contract (issue #720).
abstract interface class YoutubePlaybackEngine {}
