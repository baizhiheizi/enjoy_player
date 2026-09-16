part of '../app_database.dart';

@DriftAccessor(tables: [Videos])
class VideoDao extends DatabaseAccessor<AppDatabase> with _$VideoDaoMixin {
  VideoDao(super.db);

  Stream<List<VideoRow>> watchAll() => (select(
    videos,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<VideoRow?> getById(String id) =>
      (select(videos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<VideoRow?> getYoutubeByVid(String youtubeVid) =>
      (select(videos)..where(
            (t) => t.provider.equals('youtube') & t.vid.equals(youtubeVid),
          ))
          .getSingleOrNull();

  Future<List<VideoRow>> listAll() => select(videos).get();

  Future<void> insertRow(VideoRow row) =>
      into(videos).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> updateLocalThumbnail(String id, String absoluteThumbPath) async {
    await (update(videos)..where((t) => t.id.equals(id))).write(
      VideosCompanion(
        thumbnailUrl: Value(absoluteThumbPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateYoutubeMetadata({
    required String id,
    required String title,
    String? thumbnailUrl,
  }) async {
    await (update(videos)..where((t) => t.id.equals(id))).write(
      VideosCompanion(
        title: Value(title),
        thumbnailUrl: thumbnailUrl == null
            ? const Value.absent()
            : Value(thumbnailUrl),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateLanguage({
    required String id,
    required String language,
  }) async {
    await (update(videos)..where((t) => t.id.equals(id))).write(
      VideosCompanion(
        language: Value(language),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Bumps [Videos.updatedAt] so Home "Recent media" can resurface the row.
  Future<void> touchUpdatedAt(String id) async {
    await (update(videos)..where((t) => t.id.equals(id))).write(
      VideosCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  /// Conditionally writes [durationSeconds] (bumping `updatedAt`) **only when
  /// the stored value is still zero** — the WHERE guard makes the operation
  /// race-free: a concurrent backfill that landed first is no longer
  /// overwritten by a stale probe, and an unrelated field change between the
  /// caller's read and this write is preserved (we touch `duration_seconds`
  /// and `updated_at` only).
  ///
  /// Returns `true` when one row was patched, `false` when no row matched
  /// (unknown id) **or** the row already had a non-zero duration.
  Future<bool> setDurationIfZero(String id, int durationSeconds) async {
    final affected =
        await (update(
          videos,
        )..where((t) => t.id.equals(id) & t.durationSeconds.equals(0))).write(
          VideosCompanion(
            durationSeconds: Value(durationSeconds),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return affected == 1;
  }

  Future<void> deleteId(String id) =>
      (delete(videos)..where((t) => t.id.equals(id))).go();

  /// Whether any row's [Videos.localUri] equals [localUri] (exact match).
  ///
  /// Uses `SELECT 1 … LIMIT 1` (EXISTS) instead of materialising full rows
  /// just to count them — paired with the `idx_videos_local_uri` index added
  /// in migration 16 (issue #469).
  Future<bool> existsByLocalUri(String localUri) async {
    final row =
        await (selectOnly(videos)
              ..addColumns([videos.id])
              ..where(videos.localUri.equals(localUri))
              ..limit(1))
            .map((r) => r.read(videos.id))
            .getSingleOrNull();
    return row != null;
  }
}
