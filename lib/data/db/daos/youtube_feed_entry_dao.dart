part of '../app_database.dart';

@DriftAccessor(tables: [YoutubeFeedEntries])
class YoutubeFeedEntryDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubeFeedEntryDaoMixin {
  YoutubeFeedEntryDao(super.db);

  /// Newest-first window served to the merged Discover feed watch (issue
  /// #810 G): the table is append-only (ADR-0046, worst case ~10k rows) and
  /// every write re-runs this query, re-maps every row and re-dedupes the
  /// emission. 300 covers one refresh cycle of every subscription at the
  /// spec budget (20 × 15 RSS entries). One-shot queries stay unbounded.
  static const int timelineWatchLimit = 300;

  Stream<List<YoutubeFeedEntryRow>> watchTimeline() =>
      (select(youtubeFeedEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])
            ..limit(timelineWatchLimit))
          .watch();

  Stream<List<YoutubeFeedEntryRow>> watchForChannel(String channelId) =>
      (select(youtubeFeedEntries)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)]))
          .watch();

  Future<List<YoutubeFeedEntryRow>> getForChannel(String channelId) =>
      (select(youtubeFeedEntries)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)]))
          .get();

  Future<void> upsertEntry(YoutubeFeedEntryRow row) =>
      into(youtubeFeedEntries).insert(row, mode: InsertMode.insertOrReplace);

  /// Batch upsert of many entries in a single Drift `batch` (one SQLite
  /// transaction, one COMMIT). Compared to calling [upsertEntry] in a loop,
  /// this collapses N round-trips and N `watchTimeline` re-emissions into
  /// one of each — the row content of the final list is identical, but the
  /// refresh path stops paying N× per-entry fsync + map + elementwise equals
  /// costs. Empty input is a no-op (Drift's `batch` requires non-empty).
  Future<void> upsertEntries(List<YoutubeFeedEntryRow> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(youtubeFeedEntries, rows, mode: InsertMode.insertOrReplace);
    });
  }

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
