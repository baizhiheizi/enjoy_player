/// Thrown when [YoutubePlayerEngine] cannot run on this device (ADR-0048,
/// specs/047).
library;

import 'package:enjoy_player/core/platform/linux_platform_availability.dart';

/// YouTube playback is unavailable on this device: the player surfaces a
/// localized notice (with a browser fallback when the video URL is known)
/// instead of the generic open-failure body.
class YouTubePlaybackUnavailableException implements Exception {
  /// Build-time kill-switch failure (`youtubeEngineKillSwitchOn`): the
  /// rollback posture shipped as a normal release (specs/047 SC-008).
  const YouTubePlaybackUnavailableException.linuxOptedOut()
    : message = 'YouTube playback is disabled on this build.',
      youtubeUrl = null;

  const YouTubePlaybackUnavailableException(this.message, {this.youtubeUrl});

  factory YouTubePlaybackUnavailableException.fromAvailability(
    YouTubeUnavailable unavailable, {
    required String videoId,
  }) {
    return YouTubePlaybackUnavailableException(
      'YouTube playback unavailable: ${unavailable.reason.name}.',
      youtubeUrl: videoId.isEmpty
          ? null
          : 'https://m.youtube.com/watch?v=$videoId',
    );
  }

  /// Canonical watch URL for the video that failed to open, when known —
  /// the "open in browser" fallback action target (specs/047 FR-005, U2).
  final String? youtubeUrl;

  /// Human-readable description (already safe to log).
  final String message;

  @override
  String toString() => 'YouTubePlaybackUnavailableException: $message';
}
