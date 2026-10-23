part of '../app_database.dart';

@DriftAccessor(tables: [Videos])
class VideoDao extends DatabaseAccessor<AppDatabase>
    with
        _$VideoDaoMixin,
        BulkPkRowsMixin<AppDatabase, VideoRow>,
        MediaLibraryProjection<AppDatabase>,
        MediaRowWritesMixin<AppDatabase, VideoRow> {
  VideoDao(super.db);

  @override
  TableInfo<Table, VideoRow> get bulkPkTable => videos;

  @override
  String Function(VideoRow row) get bulkPkRowId =>
      (row) => row.id;

  @override
  TableInfo<Table, dynamic> get mediaLibraryTable => videos;

  @override
  GeneratedColumn<String> get mediaLibraryContentHash => videos.vid;

  @override
  TableInfo<Table, VideoRow> get mediaRowTable => videos;

  Future<VideoRow?> getYoutubeByVid(String youtubeVid) =>
      (select(videos)..where(
            (t) => t.provider.equals('youtube') & t.vid.equals(youtubeVid),
          ))
          .getSingleOrNull();

  Future<List<VideoRow>> listAll() => select(videos).get();

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
}
