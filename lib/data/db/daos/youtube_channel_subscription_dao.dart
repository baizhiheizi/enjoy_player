part of '../app_database.dart';

@DriftAccessor(tables: [YoutubeChannelSubscriptions])
class YoutubeChannelSubscriptionDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubeChannelSubscriptionDaoMixin {
  YoutubeChannelSubscriptionDao(super.db);

  Stream<List<YoutubeChannelSubscriptionRow>> watchAll() => (select(
    youtubeChannelSubscriptions,
  )..orderBy([(t) => OrderingTerm.asc(t.displayName)])).watch();

  Future<List<YoutubeChannelSubscriptionRow>> listAll() =>
      select(youtubeChannelSubscriptions).get();

  Future<YoutubeChannelSubscriptionRow?> getByChannelId(String channelId) =>
      (select(
        youtubeChannelSubscriptions,
      )..where((t) => t.channelId.equals(channelId))).getSingleOrNull();

  Future<void> upsert(YoutubeChannelSubscriptionRow row) => into(
    youtubeChannelSubscriptions,
  ).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteChannelId(String channelId) => (delete(
    youtubeChannelSubscriptions,
  )..where((t) => t.channelId.equals(channelId))).go();

  Future<void> touchLastFetched(String channelId, DateTime fetchedAt) async {
    await (update(
      youtubeChannelSubscriptions,
    )..where((t) => t.channelId.equals(channelId))).write(
      YoutubeChannelSubscriptionsCompanion(lastFetchedAt: Value(fetchedAt)),
    );
  }

  Future<void> updateDisplayName(String channelId, String displayName) async {
    await (update(
      youtubeChannelSubscriptions,
    )..where((t) => t.channelId.equals(channelId))).write(
      YoutubeChannelSubscriptionsCompanion(displayName: Value(displayName)),
    );
  }

  Future<void> updateThumbnail(String channelId, String? thumbnailUrl) async {
    await (update(
      youtubeChannelSubscriptions,
    )..where((t) => t.channelId.equals(channelId))).write(
      YoutubeChannelSubscriptionsCompanion(thumbnailUrl: Value(thumbnailUrl)),
    );
  }

  Future<void> updateLanguage(String channelId, String language) async {
    await (update(youtubeChannelSubscriptions)
          ..where((t) => t.channelId.equals(channelId)))
        .write(YoutubeChannelSubscriptionsCompanion(language: Value(language)));
  }
}
