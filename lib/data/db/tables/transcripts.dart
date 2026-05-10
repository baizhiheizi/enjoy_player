/// Drift table: transcript payloads (aligned with weapp Dexie `transcripts`).
library;

import 'package:drift/drift.dart';

@DataClassName('TranscriptRow')
class Transcripts extends Table {
  @override
  String get tableName => 'transcripts';

  TextColumn get id => text()();
  /// Weapp `TargetType`: `Video` | `Audio` | `Example` | `Ebook`.
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  TextColumn get language => text()();
  /// Weapp `TranscriptSource`: `official` | `auto` | `ai` | `user`.
  TextColumn get source => text()();
  /// JSON array of `TranscriptLine` (ms-based), same shape as weapp `timeline`.
  TextColumn get timelineJson => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get label => text().withDefault(const Constant(''))();
  IntColumn get trackIndex => integer().nullable()();
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
