/// Drift table: Enjoy-local YouTube channel subscriptions for Discover feeds.
library;

import 'package:drift/drift.dart';

import '../youtube_subscription_source.dart';

@DataClassName('YoutubeChannelSubscriptionRow')
class YoutubeChannelSubscriptions extends Table {
  @override
  String get tableName => 'youtube_channel_subscriptions';

  TextColumn get channelId => text()();
  TextColumn get displayName => text()();
  TextColumn get thumbnailUrl => text().nullable()();

  /// Bundled catalog vs user-initiated subscription.
  TextColumn get source => textEnum<YoutubeSubscriptionSource>().withDefault(
    const Constant('user'),
  )();

  DateTimeColumn get subscribedAt => dateTime()();
  DateTimeColumn get lastFetchedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}
