/// Page-level merge + batch upsert shared by the sync download services.
///
/// Split into a pure [mergePageRows] phase (one `WHERE id IN (…)` pre-read,
/// issue #810 D3) and a [persistMergedRows] phase (one transactional batch
/// upsert with a per-row fallback that isolates bad rows when the batch
/// fails), so a page's failure verdict is known before any write runs.
/// [mergeAndUpsertPage] composes both for callers that don't need the split
/// (per-target recording pull, issue #827 B3).
library;

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('sync.pageUpsert');

/// Per-page outcome of [persistMergedRows] / [runPerRowInsert].
typedef PageUpsertCounts = ({int synced, int failed, List<String> errors});

/// Merge-phase outcome of [mergePageRows]: rows that merged cleanly plus the
/// per-row failures that must keep their page from advancing the cursor.
typedef PageMergeOutcome<E> = ({List<E> rows, int failed, List<String> errors});

/// Merges [pendingUpserts] (keyed by server id) against local rows without
/// writing anything. A row whose `merge` throws is counted as failed and
/// excluded from [PageMergeOutcome.rows]; if the bulk pre-read fails, each
/// row falls back to a per-row `getLocal` lookup.
Future<PageMergeOutcome<E>> mergePageRows<E>(
  Map<String, Map<String, dynamic>> pendingUpserts, {
  required Future<Map<String, E>> Function(List<String> ids) getManyByIds,
  required Future<E?> Function(String id) getLocal,
  required E Function({required E? local, required Map<String, dynamic> server})
  merge,
}) async {
  Map<String, E>? locals;
  try {
    locals = await getManyByIds(pendingUpserts.keys.toList());
  } on Object catch (e, st) {
    _log.warning(
      'bulk pre-read failed; falling back to per-row lookups',
      e,
      st,
    );
  }
  final rows = <E>[];
  final errors = <String>[];
  for (final entry in pendingUpserts.entries) {
    try {
      final local = locals != null
          ? locals[entry.key]
          : await getLocal(entry.key);
      rows.add(merge(local: local, server: entry.value));
    } catch (e) {
      errors.add('$e');
    }
  }
  return (rows: rows, failed: errors.length, errors: errors);
}

/// Upserts already-merged [rows] in one transactional batch; when the batch
/// fails, retries each row via [insertRow] so a single bad row cannot fail
/// its page neighbors.
Future<PageUpsertCounts> persistMergedRows<E>(
  List<E> rows, {
  required Future<void> Function(List<E> rows) upsertRows,
  required Future<void> Function(E row) insertRow,
}) async {
  if (rows.isEmpty) return (synced: 0, failed: 0, errors: const <String>[]);
  try {
    await upsertRows(rows);
    return (synced: rows.length, failed: 0, errors: const <String>[]);
  } on Object {
    _log.warning('batch upsert failed; falling back to per-row inserts');
    return runPerRowInsert<E, E>(
      rows,
      lookupLocal: (_) async => null,
      insertOne: (row, _) => insertRow(row),
    );
  }
}

/// Merges and persists one page in a single call. See [mergePageRows] and
/// [persistMergedRows] for the phase contracts.
Future<PageUpsertCounts> mergeAndUpsertPage<E>(
  Map<String, Map<String, dynamic>> pendingUpserts, {
  required Future<Map<String, E>> Function(List<String> ids) getManyByIds,
  required Future<E?> Function(String id) getLocal,
  required Future<void> Function(List<E> rows) upsertRows,
  required Future<void> Function(E row) insertRow,
  required E Function({required E? local, required Map<String, dynamic> server})
  merge,
}) async {
  final merged = await mergePageRows<E>(
    pendingUpserts,
    getManyByIds: getManyByIds,
    getLocal: getLocal,
    merge: merge,
  );
  final counts = await persistMergedRows<E>(
    merged.rows,
    upsertRows: upsertRows,
    insertRow: insertRow,
  );
  return (
    synced: counts.synced,
    failed: merged.failed + counts.failed,
    errors: [...merged.errors, ...counts.errors],
  );
}

/// Runs [insertOne] over [items] one at a time, isolating per-item
/// failures so one bad row cannot fail its page neighbors. [lookupLocal]
/// resolves the local row an item merges against (or returns `null` when
/// the item is already merged).
Future<PageUpsertCounts> runPerRowInsert<T, E>(
  Iterable<T> items, {
  required Future<E?> Function(T item) lookupLocal,
  required Future<void> Function(T item, E? local) insertOne,
}) async {
  var synced = 0;
  final errors = <String>[];
  for (final item in items) {
    try {
      final local = await lookupLocal(item);
      await insertOne(item, local);
      synced++;
    } catch (e) {
      errors.add('$e');
    }
  }
  return (synced: synced, failed: errors.length, errors: errors);
}
