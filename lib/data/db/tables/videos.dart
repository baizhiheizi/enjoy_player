/// Drift table: video media (aligned with weapp Dexie `videos`).
library;

import 'package:drift/drift.dart';

@DataClassName('VideoRow')
class Videos extends Table {
  @override
  String get tableName => 'videos';

  TextColumn get id => text()();
  TextColumn get vid => text()();
  TextColumn get provider => text().withDefault(const Constant('user'))();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  /// Duration in whole seconds (weapp `Video.duration`).
  IntColumn get durationSeconds =>
      integer().withDefault(const Constant(0))();
  TextColumn get language => text().withDefault(const Constant('und'))();
  TextColumn get source => text().nullable()();
  /// Local file URI (replaces web `fileHandle` / `blob`).
  TextColumn get localUri => text().nullable()();
  TextColumn get md5 => text().nullable()();
  IntColumn get size => integer().nullable()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get syncStatus => text().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
