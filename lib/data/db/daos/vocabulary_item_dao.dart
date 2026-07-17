part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyItems])
class VocabularyItemDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyItemDaoMixin {
  VocabularyItemDao(super.db);

  Future<VocabularyItemRow?> getById(String id) => (select(
    vocabularyItems,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<VocabularyItemRow?> getByWordLanguageTarget({
    required String word,
    required String language,
    required String targetLanguage,
  }) =>
      (select(vocabularyItems)..where(
            (t) =>
                t.word.equals(word) &
                t.language.equals(language) &
                t.targetLanguage.equals(targetLanguage),
          ))
          .getSingleOrNull();

  Future<void> insertRow(VocabularyItemRow row) =>
      into(vocabularyItems).insert(row);

  Future<void> updateRow(VocabularyItemRow row) =>
      into(vocabularyItems).insert(row, mode: InsertMode.replace);

  Future<int> deleteById(String id) =>
      (delete(vocabularyItems)..where((t) => t.id.equals(id))).go();

  /// Rows with [VocabularyItems.nextReviewAt] <= [now]; due predicate
  /// applied in Dart (matches web filter on `lastReviewedAt`).
  Future<List<VocabularyItemRow>> listDue(DateTime now) async {
    final candidates = await (select(
      vocabularyItems,
    )..where((t) => t.nextReviewAt.isSmallerOrEqualValue(now))).get();
    return candidates
        .where(
          (row) =>
              row.lastReviewedAt == null ||
              row.nextReviewAt.isAfter(row.lastReviewedAt!),
        )
        .toList();
  }

  Future<List<VocabularyItemRow>> listAll() => select(vocabularyItems).get();
}
