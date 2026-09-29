part of '../app_database.dart';

@DriftAccessor(tables: [Videos])
class VideoDao extends DatabaseAccessor<AppDatabase> with _$VideoDaoMixin {
  VideoDao(super.db);

  List<GeneratedColumn<Object>> get _libraryColumns => [
    videos.id,
    videos.title,
    videos.localUri,
    videos.mediaUrl,
    videos.thumbnailUrl,
    videos.durationSeconds,
    videos.language,
    videos.vid,
    videos.size,
    videos.source,
    videos.provider,
    videos.syncStatus,
    videos.createdAt,
    videos.updatedAt,
  ];

  MediaLibraryRow _libraryRow(TypedResult r) => MediaLibraryRow(
    id: r.read(videos.id)!,
    title: r.read(videos.title)!,
    localUri: r.read(videos.localUri),
    mediaUrl: r.read(videos.mediaUrl),
    thumbnailUrl: r.read(videos.thumbnailUrl),
    durationSeconds: r.read(videos.durationSeconds)!,
    language: r.read(videos.language)!,
    contentHash: r.read(videos.vid)!,
    size: r.read(videos.size),
    source: r.read(videos.source),
    provider: r.read(videos.provider)!,
    syncStatus: r.read(videos.syncStatus),
    createdAt: r.read(videos.createdAt)!,
    updatedAt: r.read(videos.updatedAt)!,
  );

  /// Library-wide watch projecting only the columns `Media` needs
  /// (`createdAt`-descending; issue #810 D6 — skips `description` and
  /// `bookmarkData` blobs).
  Stream<List<MediaLibraryRow>> watchAll() {
    return (selectOnly(videos)
          ..addColumns(_libraryColumns)
          ..orderBy([OrderingTerm.desc(videos.createdAt)]))
        .map(_libraryRow)
        .watch();
  }

  /// Up to [limit] rows with the newest [Videos.updatedAt] first
  /// (`updated_at DESC, created_at DESC` tiebreak), for the Home recents
  /// query (issue #810 D6).
  Stream<List<MediaLibraryRow>> watchRecentByUpdatedAt(int limit) {
    return (selectOnly(videos)
          ..addColumns(_libraryColumns)
          ..orderBy([
            OrderingTerm.desc(videos.updatedAt),
            OrderingTerm.desc(videos.createdAt),
          ])
          ..limit(limit))
        .map(_libraryRow)
        .watch();
  }

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
