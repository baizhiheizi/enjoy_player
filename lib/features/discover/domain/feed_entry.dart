/// Cached RSS feed item (not a library row until imported).
library;

class FeedEntry {
  const FeedEntry({
    required this.videoId,
    required this.channelId,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.publishedAt,
  });

  final String videoId;
  final String channelId;
  final String title;
  final String? thumbnailUrl;

  /// When known (RSS enrichment or library row); omitted from YouTube Atom feeds.
  final int? durationSeconds;
  final DateTime publishedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedEntry &&
        other.videoId == videoId &&
        other.channelId == channelId &&
        other.title == title &&
        other.thumbnailUrl == thumbnailUrl &&
        other.durationSeconds == durationSeconds &&
        other.publishedAt == publishedAt;
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    channelId,
    title,
    thumbnailUrl,
    durationSeconds,
    publishedAt,
  );
}
