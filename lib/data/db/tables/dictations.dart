/// Drift table: dictation attempts (aligned with weapp `dictations`).
library;

import 'package:drift/drift.dart';

@DataClassName('DictationRow')
class Dictations extends Table {
  @override
  String get tableName => 'dictations';

  TextColumn get id => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();
  IntColumn get referenceStartMs => integer()();
  IntColumn get referenceDurationMs => integer()();
  TextColumn get referenceText => text()();
  TextColumn get language => text()();
  TextColumn get userInput => text()();
  IntColumn get accuracy => integer()();
  IntColumn get correctWords => integer()();
  IntColumn get missedWords => integer()();
  IntColumn get extraWords => integer()();
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
