/// Drift table: bounded L2 cache for AI result payloads.
///
/// Schema is intentionally minimal — the cache layer (AiResultCache) does
/// all eviction, indexing, and JSON serialization. The SQL layer just
/// provides keyed storage + a (kind, updatedAt DESC) index for cheap
/// LRU-eviction and age-cutoff queries.
library;

import 'package:drift/drift.dart';

@DataClassName('AiCacheRow')
class AiCache extends Table {
  @override
  String get tableName => 'ai_cache';

  /// Discriminator that prevents cross-modality collisions. One of
  /// `AiKind.wire` (`translation`, `dictionary`, `contextual_translation`,
  /// `auto_translate_line`).
  TextColumn get kind => text()();

  /// 32-char lowercase hex SHA-256 prefix produced by
  /// `AiCacheFingerprint.fingerprint(...)`.
  TextColumn get key => text()();

  /// JSON-encoded result payload. Decoded back to the concrete Dart type
  /// by the cache layer.
  TextColumn get payloadJson => text()();

  /// Last-write timestamp (milliseconds since epoch). Used by
  /// `evictOldestExcept` and `pruneOlderThan`.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {kind, key};
}
