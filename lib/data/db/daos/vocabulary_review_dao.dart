part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyReviews])
class VocabularyReviewDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyReviewDaoMixin {
  VocabularyReviewDao(super.db);

  Future<void> insertRow(VocabularyReviewRow row) =>
      into(vocabularyReviews).insert(row);

  Future<VocabularyReviewRow?> latestForItem(String vocabularyItemId) =>
      (select(vocabularyReviews)
            ..where((t) => t.vocabularyItemId.equals(vocabularyItemId))
            ..orderBy([(t) => OrderingTerm.desc(t.at)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> deleteByItemId(String vocabularyItemId) => (delete(
    vocabularyReviews,
  )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).go();

  Future<int> deleteById(String id) =>
      (delete(vocabularyReviews)..where((t) => t.id.equals(id))).go();
}
