/// Domain model for a subscribed or recommended YouTube source.
library;

import 'package:enjoy_player/data/db/youtube_subscription_source.dart';

class DiscoverChannel {
  const DiscoverChannel({
    required this.channelId,
    required this.displayName,
    this.thumbnailUrl,
    required this.source,
    this.sourceType = YoutubeSourceType.channel,
    this.feedUrl,
    required this.subscribedAt,
    this.lastFetchedAt,
  });

  final String channelId;
  final String displayName;
  final String? thumbnailUrl;
  final YoutubeSubscriptionSource source;
  final YoutubeSourceType sourceType;
  final String? feedUrl;
  final DateTime subscribedAt;
  final DateTime? lastFetchedAt;

  bool get isSubscribed => true;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoverChannel &&
        other.channelId == channelId &&
        other.displayName == displayName &&
        other.thumbnailUrl == thumbnailUrl &&
        other.source == source &&
        other.sourceType == sourceType &&
        other.feedUrl == feedUrl &&
        other.subscribedAt == subscribedAt &&
        other.lastFetchedAt == lastFetchedAt;
  }

  @override
  int get hashCode => Object.hash(
    channelId,
    displayName,
    thumbnailUrl,
    source,
    sourceType,
    feedUrl,
    subscribedAt,
    lastFetchedAt,
  );
}
