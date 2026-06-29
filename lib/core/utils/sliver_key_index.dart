/// Helpers for [SliverChildBuilderDelegate.findChildIndexCallback].
///
/// When a sliver's underlying data list reorders (e.g. after a Drift
/// re-emit inserts a new row at the head), Flutter calls the
/// `findChildIndexCallback` with the [LocalKey] of an existing child to
/// learn the new index. Returning the index lets the framework re-use the
/// already-built [Element] instead of tearing it down and rebuilding from
/// scratch — a meaningful win for long lists that re-emit often.
///
/// The convention used across the discover / home grids is:
///
/// ```dart
/// key: ValueKey<String>('$prefix${item.id}'),
/// findChildIndexCallback: (k) => findSliverIndexByPrefixedId(
///   items: items, key: k, prefix: prefix, idOf: (i) => i.id,
/// ),
/// ```
///
/// Keeping the [prefix] in one place avoids subtle bugs where the key
/// shape and the lookup shape drift apart.
library;

import 'package:flutter/widgets.dart';

/// Returns the index in [items] whose [idOf] matches the suffix of [key].
///
/// [key] must be a [ValueKey] whose value is `"$prefix${idOf(item)}"`. Returns
/// `null` for any key shape that doesn't match (wrong type, wrong prefix, or
/// no item with that id) — the sliver framework treats a `null` return as
/// "this key isn't part of this delegate's children" and falls back to the
/// default O(n) child scan.
int? findSliverIndexByPrefixedId<T>({
  required Iterable<T> items,
  required Key key,
  required String prefix,
  required String Function(T) idOf,
}) {
  if (key is! ValueKey<String>) return null;
  final raw = key.value;
  if (!raw.startsWith(prefix)) return null;
  final id = raw.substring(prefix.length);
  var i = 0;
  for (final item in items) {
    if (idOf(item) == id) return i;
    i++;
  }
  return null;
}
