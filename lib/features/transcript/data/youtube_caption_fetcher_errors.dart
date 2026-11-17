part of 'youtube_caption_fetcher.dart';

/// Stage at which a [YoutubeCaptionFetchException] was raised.
///
/// Lets callers / tests distinguish InnerTube `/player` failures from
/// per-track `timedtext` fetches without string-parsing the message.
enum YoutubeCaptionErrorStage {
  /// InnerTube `/player` HTTP call returned a non-200 status.
  innertubePlayer,

  /// InnerTube `/player` returned a `playabilityStatus.status` other than
  /// 'OK' (e.g. `ERROR`, `LOGIN_REQUIRED`, `UNPLAYABLE`).
  innertubePlayability,

  /// Per-track `timedtext?v=…&fmt=json3` HTTP call returned a non-200
  /// status.
  timedTextGet,

  /// Per-track `timedtext` body could not be parsed as JSON.
  timedTextJson,
}

/// Typed exception thrown by [YoutubeCaptionFetcher] when a YouTube
/// captions fetch fails at an HTTP / parse boundary.
///
/// All throw sites in `youtube_caption_fetcher.dart` raise this type so
/// callers can catch it explicitly (`on YoutubeCaptionFetchException`) to
/// distinguish InnerTube / `timedtext` failures from the broader
/// `CaptionFetchResult.error` strings produced by the fallback chain.
/// Implements [Exception] for compatibility with existing `on Object catch`
/// blocks.
class YoutubeCaptionFetchException implements Exception {
  YoutubeCaptionFetchException({
    required this.stage,
    required this.message,
    this.statusCode,
  });

  /// Where the failure occurred.
  final YoutubeCaptionErrorStage stage;

  /// Human-readable description (already safe to log).
  final String message;

  /// HTTP status code when [stage] is an HTTP boundary; null otherwise.
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' ($statusCode)';
    return 'YoutubeCaptionFetchException(${stage.name}$code): $message';
  }
}
