/// Drift table: vocabulary_contexts (word appearances in media/ebook).
library;

import 'package:drift/drift.dart';

import 'sync_metadata.dart';

@TableIndex(
  name: 'idx_vocabulary_contexts_item_id',
  columns: {#vocabularyItemId},
)
@TableIndex(
  name: 'idx_vocabulary_contexts_item_source',
  columns: {#vocabularyItemId, #sourceType, #sourceId},
)
@DataClassName('VocabularyContextRow')
class VocabularyContexts extends Table with SyncMetadataColumns {
  @override
  String get tableName => 'vocabulary_contexts';

  TextColumn get id => text()();
  TextColumn get vocabularyItemId => text()();

  /// Sentence / paragraph context. SQL column name `text` (web field name).
  /// Getter cannot be `text` — that clashes with Drift's [text] builder.
  TextColumn get contextText => text().named('text')();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text()();

  /// JSON locator (`MediaLocator` or `EbookLocator`).
  TextColumn get locatorJson => text().named('locator')();
  TextColumn get explanation => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
