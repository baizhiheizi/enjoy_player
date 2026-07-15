/// Typed exceptions for worker feed API errors.
library;

/// Thrown when a worker feed request fails.
class WorkerFeedException implements Exception {
  const WorkerFeedException({
    required this.kind,
    this.message,
    this.statusCode,
    this.channelId,
  });

  /// Creates a "source not found" error (HTTP 404).
  factory WorkerFeedException.notFound({String? channelId}) =>
      WorkerFeedException(
        kind: WorkerFeedErrorKind.notFound,
        message: 'This source could not be found.',
        statusCode: 404,
        channelId: channelId,
      );

  /// Creates a "source unavailable" error (HTTP 410).
  factory WorkerFeedException.sourceUnavailable({String? channelId}) =>
      WorkerFeedException(
        kind: WorkerFeedErrorKind.sourceUnavailable,
        message: 'This source is no longer available.',
        statusCode: 410,
        channelId: channelId,
      );

  /// Creates a "rate limited" error (HTTP 429).
  factory WorkerFeedException.rateLimited({String? channelId}) =>
      WorkerFeedException(
        kind: WorkerFeedErrorKind.rateLimited,
        message: 'Too many requests. Try again later.',
        statusCode: 429,
        channelId: channelId,
      );

  /// Creates an "upstream failure" error (HTTP 502).
  factory WorkerFeedException.upstreamFailure({String? channelId}) =>
      WorkerFeedException(
        kind: WorkerFeedErrorKind.upstreamFailure,
        message: 'Could not reach YouTube. Try again later.',
        statusCode: 502,
        channelId: channelId,
      );

  /// Creates a generic HTTP error.
  factory WorkerFeedException.httpError(int statusCode, {String? channelId}) =>
      WorkerFeedException(
        kind: WorkerFeedErrorKind.httpError,
        message: 'Something went wrong (HTTP $statusCode). Try again.',
        statusCode: statusCode,
        channelId: channelId,
      );

  /// Creates a "no internet" error.
  factory WorkerFeedException.networkError({String? channelId}) =>
      WorkerFeedException(
        kind: WorkerFeedErrorKind.networkError,
        message: 'No internet connection.',
        channelId: channelId,
      );

  /// Creates a "parse error" error.
  factory WorkerFeedException.parseError({
    String? channelId,
  }) => WorkerFeedException(
    kind: WorkerFeedErrorKind.parseError,
    message:
        'Could not parse the feed. The worker might be experiencing issues.',
    channelId: channelId,
  );

  final WorkerFeedErrorKind kind;
  final String? message;
  final int? statusCode;
  final String? channelId;

  @override
  String toString() => 'WorkerFeedException($kind): $message';
}

/// Categorizes the type of worker feed error.
enum WorkerFeedErrorKind {
  /// HTTP 404 — source not found.
  notFound,

  /// HTTP 410 — source deleted/private/terminated.
  sourceUnavailable,

  /// HTTP 429 — rate limited.
  rateLimited,

  /// HTTP 502 — YouTube upstream failure.
  upstreamFailure,

  /// Other 4xx/5xx HTTP response.
  httpError,

  /// Network unreachable (no internet).
  networkError,

  /// Failed to parse the JSON Feed response.
  parseError,
}
