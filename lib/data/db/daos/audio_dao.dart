part of '../app_database.dart';

@DriftAccessor(tables: [Audios])
class AudioDao extends DatabaseAccessor<AppDatabase> with _$AudioDaoMixin {
  AudioDao(super.db);

  Stream<List<AudioRow>> watchAll() => (select(
    audios,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<AudioRow?> getById(String id) =>
      (select(audios)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<AudioRow?> getByMd5(String md5) =>
      (select(audios)..where((t) => t.md5.equals(md5))).getSingleOrNull();

  Future<void> insertRow(AudioRow row) =>
      into(audios).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> updateLanguage({
    required String id,
    required String language,
  }) async {
    await (update(audios)..where((t) => t.id.equals(id))).write(
      AudiosCompanion(
        language: Value(language),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteId(String id) =>
      (delete(audios)..where((t) => t.id.equals(id))).go();

  /// Rows whose [Audios.localUri] equals [localUri] (exact string match).
  Future<int> countByLocalUri(String localUri) async {
    final rows = await (select(
      audios,
    )..where((t) => t.localUri.equals(localUri))).get();
    return rows.length;
  }
}
