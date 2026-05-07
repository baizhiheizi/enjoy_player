/// Root Drift database for Enjoy Player (native SQLite via drift_flutter).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/medias.dart';
import 'tables/playback_sessions.dart';
import 'tables/settings.dart';
import 'tables/transcripts.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Medias, Transcripts, PlaybackSessions, SettingsKv],
  daos: [MediaDao, TranscriptDao, SessionDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'enjoy_player'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transcripts, transcripts.label);
        await m.addColumn(transcripts, transcripts.trackIndex);
        await m.addColumn(transcripts, transcripts.isEmbedded);
        await m.addColumn(
          playbackSessions,
          playbackSessions.primaryTranscriptId,
        );
        await m.addColumn(
          playbackSessions,
          playbackSessions.secondaryTranscriptId,
        );
      }
    },
  );
}

@DriftAccessor(tables: [Medias])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.db);

  Future<List<MediaRow>> get all => select(medias).get();

  Stream<List<MediaRow>> watchAll() =>
      (select(medias)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<MediaRow?> getById(String id) =>
      (select(medias)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(MediaRow row) =>
      into(medias).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(medias)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Transcripts])
class TranscriptDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptDaoMixin {
  TranscriptDao(super.db);

  /// Legacy: returns all rows ordered by language (kept for compatibility).
  Stream<List<TranscriptRow>> watchForMedia(String mediaId) =>
      (select(transcripts)
            ..where((t) => t.mediaId.equals(mediaId))
            ..orderBy([(t) => OrderingTerm.asc(t.language)]))
          .watch();

  /// All tracks for a media: embedded first, then imported (by createdAt).
  Stream<List<TranscriptRow>> watchAllForMedia(String mediaId) =>
      (select(transcripts)
            ..where((t) => t.mediaId.equals(mediaId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.isEmbedded),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  Future<TranscriptRow?> getById(String id) =>
      (select(transcripts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TranscriptRow>> listForMedia(String mediaId) =>
      (select(transcripts)..where((t) => t.mediaId.equals(mediaId))).get();

  Future<void> upsert(TranscriptRow row) =>
      into(transcripts).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(transcripts)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [PlaybackSessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<PlaybackSessionRow?> getForMedia(String mediaId) =>
      (select(playbackSessions)
        ..where((t) => t.mediaId.equals(mediaId))).getSingleOrNull();

  Stream<PlaybackSessionRow?> watchForMedia(String mediaId) =>
      (select(playbackSessions)
        ..where((t) => t.mediaId.equals(mediaId))).watchSingleOrNull();

  Future<void> upsert(PlaybackSessionRow row) =>
      into(playbackSessions).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> updatePrimaryTranscript(String mediaId, String? transcriptId) =>
      (update(playbackSessions)..where((t) => t.mediaId.equals(mediaId))).write(
        PlaybackSessionsCompanion(primaryTranscriptId: Value(transcriptId)),
      );

  Future<void> updateSecondaryTranscript(
    String mediaId,
    String? transcriptId,
  ) => (update(playbackSessions)
    ..where((t) => t.mediaId.equals(mediaId))).write(
    PlaybackSessionsCompanion(secondaryTranscriptId: Value(transcriptId)),
  );
}

@DriftAccessor(tables: [SettingsKv])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row =
        await (select(settingsKv)
          ..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) => into(settingsKv).insert(
    SettingRow(key: key, value: value),
    mode: InsertMode.insertOrReplace,
  );
}
