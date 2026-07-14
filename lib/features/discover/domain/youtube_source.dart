/// Parsed YouTube URL result and source type definitions.
library;

import 'package:enjoy_player/data/db/youtube_subscription_source.dart';

/// Result of parsing a user-provided YouTube URL or identifier.
class ParsedYoutubeUrl {
  const ParsedYoutubeUrl({
    required this.sourceType,
    required this.canonicalId,
    required this.feedUrl,
  });

  /// What kind of source this is (channel or playlist).
  final YoutubeSourceType sourceType;

  /// The canonical identifier:
  /// - `UC...` for channels (after handle resolution)
  /// - `PL...` for playlists
  /// - `@handle` before handle resolution
  final String canonicalId;

  /// Constructed worker feed URL with `?format=json`.
  final String feedUrl;
}
