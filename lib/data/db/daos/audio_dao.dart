part of '../app_database.dart';

@DriftAccessor(tables: [Audios])
class AudioDao extends DatabaseAccessor<AppDatabase>
    with
        _$AudioDaoMixin,
        BulkPkRowsMixin<AppDatabase, AudioRow>,
        MediaLibraryProjection<AppDatabase>,
        MediaRowWritesMixin<AppDatabase, AudioRow> {
  AudioDao(super.db);

  @override
  TableInfo<Table, AudioRow> get bulkPkTable => audios;

  @override
  String Function(AudioRow row) get bulkPkRowId =>
      (row) => row.id;

  @override
  TableInfo<Table, dynamic> get mediaLibraryTable => audios;

  @override
  GeneratedColumn<String> get mediaLibraryContentHash => audios.aid;

  @override
  TableInfo<Table, AudioRow> get mediaRowTable => audios;

  Future<AudioRow?> getByMd5(String md5) =>
      (select(audios)..where((t) => t.md5.equals(md5))).getSingleOrNull();
}
