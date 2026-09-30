/// Shared bulk primary-key operations for sync download DAOs (issue #810 D3).
///
/// Hand-written (not a `part of` the database library, no `@DriftAccessor`),
/// so applying it to existing DAOs requires no codegen regeneration.
library;

import 'package:drift/drift.dart';

/// Provides [getManyByIds] / [upsertRows] for tables whose primary key is a
/// single `TEXT` column, collapsing the per-entity copies behind one
/// implementation.
///
/// Implementations supply the table and the typed row-id accessor only: the
/// primary-key column is derived from the table's `$primaryKey` (a
/// non-singleton key or a non-`TEXT` column fails the cast loudly), and the
/// conflict mode defaults to [InsertMode.insertOrReplace] — drift documents
/// `InsertMode.replace` as identical, so the vocabulary DAOs' former
/// `replace` override is gone.
mixin BulkPkRowsMixin<DB extends GeneratedDatabase, R extends Insertable<R>>
    on DatabaseAccessor<DB> {
  /// Table read by [getManyByIds] and written by [upsertRows].
  TableInfo<Table, R> get bulkPkTable;

  /// Primary key of a row, used to key the [getManyByIds] result map.
  String Function(R row) get bulkPkRowId;

  /// Conflict mode [upsertRows] applies, matching the DAO's single-row write.
  InsertMode get bulkPkInsertMode => InsertMode.insertOrReplace;

  /// Primary-key column driving the `WHERE id IN (…)` filter.
  late final GeneratedColumn<String> bulkPkColumn =
      bulkPkTable.$primaryKey.single as GeneratedColumn<String>;

  /// Bulk-fetches rows by primary key in one `WHERE id IN (…)` query.
  /// Ids with no row are absent from the map; empty input is a no-op.
  Future<Map<String, R>> getManyByIds(Iterable<String> ids) async {
    final values = ids.toList();
    if (values.isEmpty) return const {};
    final rows = await (select(
      bulkPkTable,
    )..where((_) => bulkPkColumn.isIn(values))).get();
    return {for (final row in rows) bulkPkRowId(row): row};
  }

  /// Batch upserts [rows] in one Drift `batch` (single transaction + COMMIT).
  /// Empty input is a no-op.
  Future<void> upsertRows(List<R> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(bulkPkTable, rows, mode: bulkPkInsertMode);
    });
  }
}
