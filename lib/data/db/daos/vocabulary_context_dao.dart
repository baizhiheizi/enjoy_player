part of '../app_database.dart';

@DriftAccessor(tables: [VocabularyContexts])
class VocabularyContextDao extends DatabaseAccessor<AppDatabase>
    with
        _$VocabularyContextDaoMixin,
        BulkPkRowsMixin<AppDatabase, VocabularyContextRow> {
  VocabularyContextDao(super.db);

  @override
  TableInfo<Table, VocabularyContextRow> get bulkPkTable => vocabularyContexts;

  @override
  String Function(VocabularyContextRow row) get bulkPkRowId =>
      (row) => row.id;

  Future<List<VocabularyContextRow>> getByItemId(String vocabularyItemId) =>
      (select(
        vocabularyContexts,
      )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).get();

  /// Max ids per `IN (…)` query — SQLite's default host variable limit is
  /// 999, so long id lists are chunked below it (issue #827 B1).
  static const _kMaxIdsPerQuery = 900;

  /// Bulk-fetch all contexts for the given item ids (issue #468 —
  /// eliminates N+1 in vocabulary export). One query per ≤900 ids.
  Future<List<VocabularyContextRow>> getByItemIds(
    Iterable<String> itemIds,
  ) async {
    final ids = itemIds.toList();
    if (ids.isEmpty) return const [];
    final rows = <VocabularyContextRow>[];
    for (var i = 0; i < ids.length; i += _kMaxIdsPerQuery) {
      final chunk = ids.skip(i).take(_kMaxIdsPerQuery).toList();
      rows.addAll(
        await (select(
          vocabularyContexts,
        )..where((t) => t.vocabularyItemId.isIn(chunk))).get(),
      );
    }
    return rows;
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

  Future<void> insertRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row);

  Future<void> updateRow(VocabularyContextRow row) =>
      into(vocabularyContexts).insert(row, mode: InsertMode.replace);

  Future<int> deleteByItemId(String vocabularyItemId) => (delete(
    vocabularyContexts,
  )..where((t) => t.vocabularyItemId.equals(vocabularyItemId))).go();
}
