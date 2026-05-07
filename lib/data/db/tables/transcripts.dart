/// Drift table: transcript payloads linked to media (JSON lines).
library;

import 'package:drift/drift.dart';

import 'medias.dart';

@DataClassName('TranscriptRow')
class Transcripts extends Table {
  @override
  String get tableName => 'transcripts';

  TextColumn get id => text()();
  TextColumn get mediaId =>
      text().references(Medias, #id, onDelete: KeyAction.cascade)();
  TextColumn get language => text()();
  TextColumn get source => text()();
  TextColumn get linesJson => text()();

  /// Human-readable label shown in the track picker (filename, stream title, etc.).
  TextColumn get label => text().withDefault(const Constant(''))();

  /// For embedded tracks: the 0-based index in the container's subtitle stream list.
  IntColumn get trackIndex => integer().nullable()();

  /// 1 if extracted from the media file itself, 0 if user-imported an external file.
  BoolColumn get isEmbedded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
