part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyItems])
class VocabularyItemDao extends DatabaseAccessor<AppDatabase>
    with
        _$VocabularyItemDaoMixin,
        BulkPkRowsMixin<AppDatabase, VocabularyItemRow> {
  VocabularyItemDao(super.db);

  @override
  TableInfo<Table, VocabularyItemRow> get bulkPkTable => vocabularyItems;

  @override
  GeneratedColumn<String> get bulkPkColumn => vocabularyItems.id;

  @override
  String Function(VocabularyItemRow row) get bulkPkRowId =>
      (row) => row.id;

  @override
  InsertMode get bulkPkInsertMode => InsertMode.replace;

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

  /// Live list without the `explanation` JSON blob (issue #810 G): every
  /// table write re-emits this stream, and the watch consumers (word list,
  /// stats, review-options preview) render list fields only. Rows read here
  /// carry `explanation: null`; fetch via [getById] / [listAll] when the
  /// payload is needed.
  Stream<List<VocabularyItemRow>> watchAll() {
    final columns = <GeneratedColumn<Object>>[
      vocabularyItems.id,
      vocabularyItems.word,
      vocabularyItems.language,
      vocabularyItems.targetLanguage,
      vocabularyItems.status,
      vocabularyItems.easeFactor,
      vocabularyItems.interval,
      vocabularyItems.nextReviewAt,
      vocabularyItems.reviewsCount,
      vocabularyItems.lastReviewedAt,
      vocabularyItems.contextsCount,
      vocabularyItems.syncStatus,
      vocabularyItems.serverUpdatedAt,
      vocabularyItems.createdAt,
      vocabularyItems.updatedAt,
    ];
    final query = selectOnly(vocabularyItems)..addColumns(columns);
    return query
        .map(
          (row) => VocabularyItemRow(
            id: row.read(vocabularyItems.id)!,
            word: row.read(vocabularyItems.word)!,
            language: row.read(vocabularyItems.language)!,
            targetLanguage: row.read(vocabularyItems.targetLanguage)!,
            status: row.read(vocabularyItems.status)!,
            easeFactor: row.read(vocabularyItems.easeFactor)!,
            interval: row.read(vocabularyItems.interval)!,
            nextReviewAt: row.read(vocabularyItems.nextReviewAt)!,
            reviewsCount: row.read(vocabularyItems.reviewsCount)!,
            lastReviewedAt: row.read(vocabularyItems.lastReviewedAt),
            contextsCount: row.read(vocabularyItems.contextsCount)!,
            explanation: null,
            syncStatus: row.read(vocabularyItems.syncStatus),
            serverUpdatedAt: row.read(vocabularyItems.serverUpdatedAt),
            createdAt: row.read(vocabularyItems.createdAt)!,
            updatedAt: row.read(vocabularyItems.updatedAt)!,
          ),
        )
        .watch();
  }
}
