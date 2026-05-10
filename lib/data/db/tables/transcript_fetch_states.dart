/// Marks that cloud transcripts were fetched at least once for a library target.
library;

import 'package:drift/drift.dart';

@DataClassName('TranscriptFetchStateRow')
class TranscriptFetchStates extends Table {
  @override
  String get tableName => 'transcript_fetch_states';

  /// Dexie `TargetType`: `Video` | `Audio`.
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  DateTimeColumn get lastFetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {targetType, targetId};
}
