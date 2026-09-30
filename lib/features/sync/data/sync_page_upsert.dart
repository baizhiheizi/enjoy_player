/// Page-level merge + batch upsert shared by the sync download services.
///
/// One `WHERE id IN (…)` pre-read and one transactional batch upsert
/// (issue #810 D3) instead of two round trips and one commit per server
/// row, with a per-row fallback that isolates bad rows when the batch
/// fails. Reused by the per-target recording pull (issue #827 B3).
library;

import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('sync.pageUpsert');

/// Per-page outcome of [mergeAndUpsertPage] / [runPerRowInsert].
typedef PageUpsertCounts = ({int synced, int failed, List<String> errors});

/// Merges [pendingUpserts] (keyed by server id) against local rows and
/// upserts the results in one batch. A row whose `merge` throws is
/// counted as failed and skipped; if the batch itself fails, every
/// already-merged row is retried one at a time via [insertRow] so a
/// single bad row cannot fail its page neighbors.
Future<PageUpsertCounts> mergeAndUpsertPage<E>(
  Map<String, Map<String, dynamic>> pendingUpserts, {
  required Future<Map<String, E>> Function(List<String> ids) getManyByIds,
  required Future<E?> Function(String id) getLocal,
  required Future<void> Function(List<E> rows) upsertRows,
  required Future<void> Function(E row) insertRow,
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
    final fallback =
        await runPerRowInsert<MapEntry<String, Map<String, dynamic>>, E>(
          pendingUpserts.entries,
          lookupLocal: (entry) => getLocal(entry.key),
          insertOne: (entry, local) =>
              insertRow(merge(local: local, server: entry.value)),
        );
    return fallback;
  }

  final mergedRows = <E>[];
  final errors = <String>[];
  for (final entry in pendingUpserts.entries) {
    try {
      mergedRows.add(merge(local: locals[entry.key], server: entry.value));
    } catch (e) {
      errors.add('$e');
    }
  }

  try {
    await upsertRows(mergedRows);
    return (synced: mergedRows.length, failed: errors.length, errors: errors);
  } on Object {
    _log.warning('batch upsert failed; falling back to per-row inserts');
    final fallback = await runPerRowInsert<E, E>(
      mergedRows,
      lookupLocal: (_) async => null,
      insertOne: (row, _) => insertRow(row),
    );
    return (
      synced: fallback.synced,
      failed: errors.length + fallback.failed,
      errors: [...errors, ...fallback.errors],
    );
  }
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
