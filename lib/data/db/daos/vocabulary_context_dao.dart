part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyContexts])
class VocabularyContextDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyContextDaoMixin {
  VocabularyContextDao(super.db);

  Future<List<VocabularyContextRow>> getByItemId(String vocabularyItemId) =>
      (select(
        vocabularyContexts,
      )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).get();

  Future<List<VocabularyContextRow>> getByItemAndSource({
    required String vocabularyItemId,
    required String sourceType,
    required String sourceId,
  }) =>
      (select(vocabularyContexts)..where(
            (t) =>
                t.vocabularyItemId.equals(vocabularyItemId) &
                t.sourceType.equals(sourceType) &
                t.sourceId.equals(sourceId),
          ))
          .get();

  Future<VocabularyContextRow?> getById(String id) => (select(
    vocabularyContexts,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row);

  Future<void> updateRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row, mode: InsertMode.replace);

  Future<int> deleteByItemId(String vocabularyItemId) => (delete(
    vocabularyContexts,
  )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).go();
}
