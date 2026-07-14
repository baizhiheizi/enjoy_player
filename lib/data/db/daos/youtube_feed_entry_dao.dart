part of '../app_database.dart';

@DriftAccessor(tables: [YoutubeFeedEntries])
class YoutubeFeedEntryDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubeFeedEntryDaoMixin {
  YoutubeFeedEntryDao(super.db);

  Stream<List<YoutubeFeedEntryRow>> watchTimeline() => (select(
    youtubeFeedEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])).watch();

  Stream<List<YoutubeFeedEntryRow>> watchForChannel(String channelId) =>
      (select(youtubeFeedEntries)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)]))
          .watch();

  Future<void> upsertEntry(YoutubeFeedEntryRow row) =>
      into(youtubeFeedEntries).insert(row, mode: InsertMode.insertOrReplace);

  Future<YoutubeFeedEntryRow?> getEntry({
    required String channelId,
    required String videoId,
  }) =>
      (select(youtubeFeedEntries)..where(
            (t) => t.channelId.equals(channelId) & t.videoId.equals(videoId),
          ))
          .getSingleOrNull();

  Future<void> updateDurationSeconds({
    required String channelId,
    required String videoId,
    required int durationSeconds,
  }) async {
    await (update(youtubeFeedEntries)..where(
          (t) => t.channelId.equals(channelId) & t.videoId.equals(videoId),
        ))
        .write(
          YoutubeFeedEntriesCompanion(durationSeconds: Value(durationSeconds)),
        );
  }

  Future<void> deleteForChannel(String channelId) => (delete(
    youtubeFeedEntries,
  )..where((t) => t.channelId.equals(channelId))).go();
}
