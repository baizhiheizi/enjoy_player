/// Drift table: vocabulary_items (word-level SRS entity).
library;

import 'package:drift/drift.dart';

import 'sync_metadata.dart';

@TableIndex(
  name: 'idx_vocabulary_items_word_language',
  columns: {#word, #language},
)
@TableIndex(
  name: 'idx_vocabulary_items_next_review_at',
  columns: {#nextReviewAt},
)
@TableIndex(name: 'idx_vocabulary_items_status', columns: {#status})
@DataClassName('VocabularyItemRow')
class VocabularyItems extends Table with SyncMetadataColumns {
  @override
  String get tableName => 'vocabulary_items';

  TextColumn get id => text()();
  TextColumn get word => text()();
  TextColumn get language => text()();
  TextColumn get targetLanguage => text()();
  TextColumn get status => text()();
  RealColumn get easeFactor => real()();
  IntColumn get interval => integer()();
  DateTimeColumn get nextReviewAt => dateTime()();
  IntColumn get reviewsCount => integer()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  IntColumn get contextsCount => integer()();
  TextColumn get explanation => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
