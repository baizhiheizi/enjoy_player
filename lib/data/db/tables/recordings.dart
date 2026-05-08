/// Drift table: pronunciation recordings (aligned with weapp `recordings`).
library;

import 'package:drift/drift.dart';

@DataClassName('RecordingRow')
class Recordings extends Table {
  @override
  String get tableName => 'recordings';

  TextColumn get id => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  IntColumn get referenceStartMs => integer()();
  IntColumn get referenceDurationMs => integer()();
  TextColumn get referenceText => text()();
  TextColumn get language => text()();
  IntColumn get durationMs => integer()();
  TextColumn get md5 => text().nullable()();
  TextColumn get audioUrl => text().nullable()();
  IntColumn get pronunciationScore => integer().nullable()();
  TextColumn get assessmentJson => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
