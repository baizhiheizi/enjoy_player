part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyContexts])
class VocabularyContextDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyContextDaoMixin {
  VocabularyContextDao(super.db);

  Future<List<VocabularyContextRow>> getByItemId(String vocabularyItemId) =>
      (select(
        vocabularyContexts,
      )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).get();

  /// Bulk-fetch all contexts for the given item ids in a single query
  /// (issue #468 — eliminates N+1 in vocabulary export).
  Future<List<VocabularyContextRow>> getByItemIds(Iterable<String> itemIds) {
    final ids = itemIds.toList();
    if (ids.isEmpty) return Future.value([]);
    return (select(
      vocabularyContexts,
    )..where((t) => t.vocabularyItemId.isIn(ids))).get();
  }

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

  /// Bulk-fetch rows by primary key in one `WHERE id IN (…)` query (issue
  /// #810 D3 — replaces a per-id `getById` round trip per server row in the
  /// sync download loop). Missing ids are absent from the map.
  Future<Map<String, VocabularyContextRow>> getManyByIds(
    Iterable<String> ids,
  ) async {
    final values = ids.toList();
    if (values.isEmpty) return const {};
    final rows = await (select(
      vocabularyContexts,
    )..where((t) => t.id.isIn(values))).get();
    return {for (final row in rows) row.id: row};
  }

  Future<void> insertRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row);

  Future<void> updateRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row, mode: InsertMode.replace);

  /// Batch upsert sharing [updateRow]'s semantics in one Drift `batch`
  /// (single transaction + COMMIT). Empty input is a no-op.
  Future<void> upsertRows(List<VocabularyContextRow> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(vocabularyContexts, rows, mode: InsertMode.replace);
    });
  }

  Future<int> deleteByItemId(String vocabularyItemId) => (delete(
    vocabularyContexts,
  )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).go();
}
