/// HTTP client for the worker RSSHub proxy.
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
final _channelIdFromUrl = RegExp(
  r'youtube\.com/channel/(UC[a-zA-Z0-9_-]{22})',
);

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

/// HTTP client that fetches YouTube feeds from the worker RSSHub proxy.
class WorkerFeedClient {
  WorkerFeedClient({
    http.Client? httpClient,
    JsonFeedParser? feedParser,
    this.baseUrl = _kDefaultWorkerBaseUrl,
  }) : _client = httpClient ?? http.Client(),
       parser = feedParser ?? JsonFeedParser();

  static const _kDefaultWorkerBaseUrl = 'https://worker.enjoy.bot';

  final http.Client _client;
  final JsonFeedParser parser;
  final String baseUrl;

  /// Fetches a feed from [feedUrl], parses it, and returns a [WorkerFeedFetchResult].
  ///
  /// If [feedUrl] is relative, it's resolved relative to [baseUrl].
  /// If it's absolute, it's used as-is.
  Future<WorkerFeedFetchResult> fetchFeed(String feedUrl) async {
    final uri = Uri.tryParse(feedUrl);
    if (uri == null || !uri.hasScheme) {
      throw WorkerFeedException(
        kind: WorkerFeedErrorKind.httpError,
        message: 'Invalid feed URL: $feedUrl',
      );
    }

    _log.info('Fetching worker feed: $feedUrl');

    http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      _log.warning('Worker feed network error: $e');
      throw WorkerFeedException.networkError();
    }

    if (response.statusCode != 200) {
      _log.warning('Worker feed HTTP ${response.statusCode}: $feedUrl');
      throw _mapHttpError(response.statusCode);
    }

    // Parse JSON Feed
    final body = response.body;
    final JsonFeedResult feedResult;
    try {
      feedResult = parser.parse(body);
    } catch (e) {
      _log.warning('Worker feed parse error: $e');
      throw WorkerFeedException.parseError();
    }

    // For handle URLs, extract the canonical channel ID from home_page_url
    String? canonicalChannelId;
    if (feedResult.homePageUrl.isNotEmpty) {
      canonicalChannelId = extractChannelIdFromUrl(feedResult.homePageUrl);
      if (canonicalChannelId != null) {
        _log.info(
          'Resolved handle to channel ID: $canonicalChannelId',
        );
      }
    }

    return WorkerFeedFetchResult(
      feedResult: feedResult,
      canonicalChannelId: canonicalChannelId,
    );
  }
}
