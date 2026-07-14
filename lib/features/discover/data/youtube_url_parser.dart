/// Pure URL validation and canonical ID extraction for YouTube sources.
library;

import 'package:enjoy_player/data/db/youtube_subscription_source.dart';
import 'package:enjoy_player/features/discover/domain/youtube_source.dart';

/// Validates user-provided YouTube URLs or identifiers and constructs
/// the corresponding worker RSSHub feed URL.
class YoutubeUrlParser {
  YoutubeUrlParser({this.workerBaseUrl = _kDefaultWorkerBaseUrl});

  static const _kDefaultWorkerBaseUrl = 'https://worker.enjoy.bot';

  final String workerBaseUrl;

  /// Regex for YouTube channel IDs (UC followed by 22 chars).
  static final _channelIdRegex = RegExp(r'^UC[a-zA-Z0-9_-]{22}$');

  /// Regex for YouTube playlist IDs (PL, OL, FL, RD, UL, etc. followed by 16+ chars).
  static final _playlistIdRegex = RegExp(r'^(PL|OL|FL|RD|UL|UU|PU|LL)[a-zA-Z0-9_-]{16,}$');

  /// Regex for YouTube @handles.
  static final _handleRegex = RegExp(r'^@[a-zA-Z0-9_.-]+$');

  /// Parses user input and returns a [ParsedYoutubeUrl] or throws [FormatException].
  ParsedYoutubeUrl parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Input is empty');
    }

    // Try raw channel ID
    final channelMatch = _channelIdRegex.firstMatch(trimmed);
    if (channelMatch != null) {
      final id = channelMatch.group(0)!;
      return ParsedYoutubeUrl(
        sourceType: YoutubeSourceType.channel,
        canonicalId: id,
        feedUrl: '$workerBaseUrl/youtube/channel/$id?format=json',
      );
    }

    // Try raw playlist ID
    final playlistMatch = _playlistIdRegex.firstMatch(trimmed);
    if (playlistMatch != null) {
      final id = playlistMatch.group(0)!;
      return ParsedYoutubeUrl(
        sourceType: YoutubeSourceType.playlist,
        canonicalId: id,
        feedUrl: '$workerBaseUrl/youtube/playlist/$id?format=json',
      );
    }

    // Try @handle
    if (trimmed.startsWith('@')) {
      final handleMatch = _handleRegex.firstMatch(trimmed);
      if (handleMatch != null) {
        final handle = handleMatch.group(0)!;
        return ParsedYoutubeUrl(
          sourceType: YoutubeSourceType.channel,
          canonicalId: handle,
          feedUrl: '$workerBaseUrl/youtube/user/$handle?format=json',
        );
      }
    }

    // Try URL parsing
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.host.contains('youtube.com')) {
      throw const FormatException('Not a YouTube URL or identifier');
    }

    // /channel/UC...
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'channel') {
      final id = uri.pathSegments[1];
      if (_channelIdRegex.hasMatch(id)) {
        return ParsedYoutubeUrl(
          sourceType: YoutubeSourceType.channel,
          canonicalId: id,
          feedUrl: '$workerBaseUrl/youtube/channel/$id?format=json',
        );
      }
    }

    // /@handle or /user/handle
    if (uri.pathSegments.isNotEmpty) {
      final first = uri.pathSegments[0];
      if (first.startsWith('@')) {
        final handle = first;
        return ParsedYoutubeUrl(
          sourceType: YoutubeSourceType.channel,
          canonicalId: handle,
          feedUrl: '$workerBaseUrl/youtube/user/$handle?format=json',
        );
      }
      if (first == 'user' && uri.pathSegments.length >= 2) {
        final handle = '@${uri.pathSegments[1]}';
        return ParsedYoutubeUrl(
          sourceType: YoutubeSourceType.channel,
          canonicalId: handle,
          feedUrl: '$workerBaseUrl/youtube/user/$handle?format=json',
        );
      }
    }

    // /playlist?list=PL...
    if (uri.queryParameters.containsKey('list')) {
      final list = uri.queryParameters['list']!;
      if (_playlistIdRegex.hasMatch(list)) {
        return ParsedYoutubeUrl(
          sourceType: YoutubeSourceType.playlist,
          canonicalId: list,
          feedUrl: '$workerBaseUrl/youtube/playlist/$list?format=json',
        );
      }
    }

    throw FormatException('Unrecognized YouTube URL format: $trimmed');
  }
}
