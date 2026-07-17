/// Drift table: vocabulary_reviews (local undo audit; never synced).
library;

import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_vocabulary_reviews_item_at',
  columns: {#vocabularyItemId, #at},
)
@DataClassName('VocabularyReviewRow')
class VocabularyReviews extends Table {
  @override
  String get tableName => 'vocabulary_reviews';

  TextColumn get id => text()();
  TextColumn get vocabularyItemId => text()();
  IntColumn get rating => integer()();
  DateTimeColumn get at => dateTime()();
  RealColumn get easeFactorBefore => real()();
  IntColumn get intervalBefore => integer()();
  TextColumn get statusBefore => text()();
  IntColumn get reviewsCountBefore => integer()();
  DateTimeColumn get nextReviewAtBefore => dateTime()();
  DateTimeColumn get lastReviewedAtBefore => dateTime().nullable()();
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
