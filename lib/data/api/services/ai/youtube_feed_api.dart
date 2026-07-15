/// Worker RSSHub proxy client for YouTube feed discovery.
///
/// Thin HTTP client that fetches YouTube channel/playlist feeds from the
/// worker RSSHub proxy with bearer auth. Uses `package:http` directly
/// (not `ApiClient`) because the response format is JSON Feed v1.1, not
/// the Rails-style snake_case JSON that `ApiClient` decodes.
library;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/discover/data/json_feed_parser.dart';
import 'package:enjoy_player/features/discover/data/worker_feed_exception.dart';

final Logger _log = logNamed('discover.worker');

/// Maps HTTP status codes to typed [WorkerFeedException]s.
WorkerFeedException _mapHttpError(int statusCode, {String? channelId}) {
  switch (statusCode) {
    case 401:
      return WorkerFeedException(
        kind: WorkerFeedErrorKind.httpError,
        message: 'Authentication required. Please sign in.',
        statusCode: 401,
        channelId: channelId,
      );
    case 404:
      return WorkerFeedException.notFound(channelId: channelId);
    case 410:
      return WorkerFeedException.sourceUnavailable(channelId: channelId);
    case 429:
      return WorkerFeedException.rateLimited(channelId: channelId);
    case 502:
      return WorkerFeedException.upstreamFailure(channelId: channelId);
    default:
      return WorkerFeedException.httpError(statusCode, channelId: channelId);
  }
}

/// Regex to extract channel ID from a YouTube channel URL.
final _channelIdFromUrl = RegExp(r'youtube\.com/channel/(UC[a-zA-Z0-9_-]{22})');

/// Extracts the canonical channel ID from a YouTube channel URL.
/// Returns `null` if the URL doesn't match.
String? extractChannelIdFromUrl(String url) {
  final match = _channelIdFromUrl.firstMatch(url);
  return match?.group(1);
}

/// Result of a worker feed fetch, including the parsed feed data and
/// any extracted canonical channel ID (for handle-to-ID resolution).
class WorkerFeedFetchResult {
  const WorkerFeedFetchResult({
    required this.feedResult,
    this.canonicalChannelId,
  });

  final JsonFeedResult feedResult;

  /// The canonical channel ID extracted from `home_page_url`.
  /// Only set when the feed was fetched from a `/youtube/user/@handle` URL.
  final String? canonicalChannelId;
}

/// HTTP client that fetches YouTube feeds from the worker RSSHub proxy
/// with bearer auth.
class YoutubeFeedClient {
  YoutubeFeedClient({
    http.Client? httpClient,
    JsonFeedParser? feedParser,
    Future<String?> Function()? getToken,
  }) : _client = httpClient ?? http.Client(),
       parser = feedParser ?? JsonFeedParser(),
       // ignore: prefer_initializing_formals
       _getToken = getToken;

  final http.Client _client;
  final JsonFeedParser parser;
  final Future<String?> Function()? _getToken;

  /// Fetches a feed from [feedUrl], parses it, and returns a [WorkerFeedFetchResult].
  ///
  /// If a token provider is configured, includes the bearer auth header
  /// required by the worker.
  Future<WorkerFeedFetchResult> fetchFeed(String feedUrl) async {
    final uri = Uri.tryParse(feedUrl);
    if (uri == null || !uri.hasScheme) {
      throw WorkerFeedException(
        kind: WorkerFeedErrorKind.httpError,
        message: 'Invalid feed URL: $feedUrl',
      );
    }

    _log.info('Fetching worker feed: $feedUrl');

    final request = http.Request('GET', uri);

    // Add bearer auth if token provider is available
    final tokenGetter = _getToken;
    if (tokenGetter != null) {
      final token = await tokenGetter();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } catch (e) {
      _log.warning('Worker feed network error: $e');
      throw WorkerFeedException.networkError();
    }

    if (response.statusCode != 200) {
      _log.warning('Worker feed HTTP ${response.statusCode}: $feedUrl');
      throw _mapHttpError(response.statusCode);
    }

    final body = response.body;
    final JsonFeedResult feedResult;
    try {
      feedResult = parser.parse(body);
    } catch (e) {
      _log.warning('Worker feed parse error: $e');
      throw WorkerFeedException.parseError();
    }

    String? canonicalChannelId;
    if (feedResult.homePageUrl.isNotEmpty) {
      canonicalChannelId = extractChannelIdFromUrl(feedResult.homePageUrl);
      if (canonicalChannelId != null) {
        _log.info('Resolved handle to channel ID: $canonicalChannelId');
      }
    }

    return WorkerFeedFetchResult(
      feedResult: feedResult,
      canonicalChannelId: canonicalChannelId,
    );
  }
}
