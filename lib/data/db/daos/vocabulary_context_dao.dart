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

  Future<void> insertRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row);

  Future<int> deleteByItemId(String vocabularyItemId) => (delete(
    vocabularyContexts,
  )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).go();
}
