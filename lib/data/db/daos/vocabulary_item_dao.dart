part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyItems])
class VocabularyItemDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyItemDaoMixin {
  VocabularyItemDao(super.db);

  Future<VocabularyItemRow?> getById(String id) => (select(
    vocabularyItems,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Bulk-fetch rows by primary key in one `WHERE id IN (…)` query (issue
  /// #810 D3 — replaces a per-id `getById` round trip per server row in the
  /// sync download loop). Missing ids are absent from the map.
  Future<Map<String, VocabularyItemRow>> getManyByIds(
    Iterable<String> ids,
  ) async {
    final values = ids.toList();
    if (values.isEmpty) return const {};
    final rows = await (select(
      vocabularyItems,
    )..where((t) => t.id.isIn(values))).get();
    return {for (final row in rows) row.id: row};
  }

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

  /// Batch upsert sharing [updateRow]'s semantics in one Drift `batch`
  /// (single transaction + COMMIT). Empty input is a no-op.
  Future<void> upsertRows(List<VocabularyItemRow> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(vocabularyItems, rows, mode: InsertMode.replace);
    });
  }

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

  Stream<List<VocabularyItemRow>> watchAll() => select(vocabularyItems).watch();
}
