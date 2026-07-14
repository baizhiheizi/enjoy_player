/// Drift table: Enjoy-local YouTube channel/playlist subscriptions for Discover feeds.
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

  /// What kind of source this is: `channel` or `playlist`.
  TextColumn get sourceType => textEnum<YoutubeSourceType>().withDefault(
    const Constant('channel'),
  )();

  /// Constructed worker feed URL, e.g.
  /// `https://worker.enjoy.bot/youtube/channel/UC...?format=json`.
  TextColumn get feedUrl => text().nullable()();

  DateTimeColumn get subscribedAt => dateTime()();
  DateTimeColumn get lastFetchedAt => dateTime().nullable()();

  /// Channel content language for Discover filtering and import defaults.
  TextColumn get language => text().withDefault(const Constant('und'))();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}
