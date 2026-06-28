/// Marks that cloud transcripts were fetched at least once for a library target.
library;

import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_transcript_fetch_states_target',
  columns: {#targetType, #targetId},
)
@DataClassName('TranscriptFetchStateRow')
class TranscriptFetchStates extends Table {
  @override
  String get tableName => 'transcript_fetch_states';

  /// Dexie `TargetType`: `Video` | `Audio`.
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get lastFetchedAt => dateTime()();

  /// Terminal outcome: `success`, `empty`, or `error`.
  TextColumn get lastStatus => text().nullable()();

  /// User-facing or log-friendly error when [lastStatus] is `error`.
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {targetType, targetId};
}
