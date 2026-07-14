/// Root Drift database for Enjoy Player (native SQLite via drift_flutter).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/stream_distinct.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'migration_backup.dart';
import 'settings_keys.dart';
import 'youtube_subscription_source.dart';
import 'tables/ai_cache.dart';
import 'tables/audios.dart';
import 'tables/dictations.dart';
import 'tables/echo_sessions.dart';
import 'tables/recordings.dart';
import 'tables/settings.dart';
import 'tables/sync_queue.dart';
import 'tables/transcript_fetch_states.dart';
import 'tables/transcripts.dart';
import 'tables/videos.dart';
import 'tables/youtube_channel_subscriptions.dart';
import 'tables/youtube_feed_entries.dart';

part 'app_database.g.dart';
part 'daos/ai_cache_dao.dart';
part 'daos/audio_dao.dart';
part 'daos/dictation_dao.dart';
part 'daos/echo_session_dao.dart';
part 'daos/recording_dao.dart';
part 'daos/settings_dao.dart';
part 'daos/sync_queue_dao.dart';
part 'daos/transcript_dao.dart';
part 'daos/transcript_fetch_state_dao.dart';
part 'daos/video_dao.dart';
part 'daos/youtube_channel_subscription_dao.dart';
part 'daos/youtube_feed_entry_dao.dart';

@DriftDatabase(
  tables: [
    Videos,
    Audios,
    Transcripts,
    TranscriptFetchStates,
    EchoSessions,
    Recordings,
    Dictations,
    SyncQueue,
    SettingsKv,
    YoutubeChannelSubscriptions,
    YoutubeFeedEntries,
    AiCache,
  ],
  daos: [
    VideoDao,
    AudioDao,
    TranscriptDao,
    TranscriptFetchStateDao,
    EchoSessionDao,
    RecordingDao,
    DictationDao,
    SyncQueueDao,
    SettingsDao,
    YoutubeChannelSubscriptionDao,
    YoutubeFeedEntryDao,
    AiCacheDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor, String name = deviceGlobalDatabaseName})
    : _dbName = name,
      super(executor ?? driftDatabase(name: name));

  /// Drift file name for device-global settings (`enjoy_player.sqlite`).
  ///
  /// Per-user library data uses `enjoy_player_<userId>`.
  static const String deviceGlobalDatabaseName = 'enjoy_player';

  /// Drift / sqlite file name (no path) for this instance.
  ///
  /// Used by callers (e.g. `SyncCtrl._onSignedIn`) that need to know
  /// whether they are about to read the device-global DB or a per-user DB
  /// without having to inspect the executor.
  final String _dbName;

  /// True when this instance serves the device-global settings file.
  bool get isDeviceGlobalDatabase => _dbName == deviceGlobalDatabaseName;

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      await _runMigrations(m, from, to);
    },
  );

  /// Explicit schema steps — no blanket table drops without [backupToJson].
  Future<void> _runMigrations(Migrator m, int from, int to) async {
    if (from >= to) return;

    var current = from;
    while (current < to) {
      if (current < 6 && to >= 7) {
        await backupToJson(m.database, from: current, to: to);
        await _dropLegacyTables(m);
        await m.createAll();
        return;
      }

      final next = current + 1;
      if (next == 7) {
        await m.createTable(youtubeChannelSubscriptions);
        await m.createTable(youtubeFeedEntries);
      } else if (next == 8) {
        await _addColumnIfMissing(
          m,
          youtubeFeedEntries,
          youtubeFeedEntries.durationSeconds,
        );
      } else if (next == 9) {
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_transcript_fetch_states_target '
          'ON transcript_fetch_states (target_type, target_id)',
        );
      } else if (next == 10) {
        await _addColumnIfMissing(
          m,
          youtubeChannelSubscriptions,
          youtubeChannelSubscriptions.language,
        );
      } else if (next == 11) {
        await _addColumnIfMissing(m, echoSessions, echoSessions.blurActive);
      } else if (next == 12) {
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS ai_cache ('
          'kind TEXT NOT NULL, '
          'key TEXT NOT NULL, '
          'payload_json TEXT NOT NULL, '
          'updated_at INTEGER NOT NULL, '
          'PRIMARY KEY (kind, key))',
        );
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_ai_cache_kind_updated_at '
          'ON ai_cache (kind, updated_at DESC)',
        );
      }
      current = next;
    }
  }

  /// Adds [column] to [table] unless it already exists.
  ///
  /// Unlike `CREATE TABLE IF NOT EXISTS` (which drift's [Migrator.createTable]
  /// uses by default), `ALTER TABLE ... ADD COLUMN` has no idempotent form in
  /// SQLite. A migration that ran partway on a previous launch (e.g. crashed
  /// on a later step) can leave the column already present with
  /// `schemaVersion` unchanged, so re-running this step unconditionally would
  /// throw `duplicate column name` on every subsequent launch — before
  /// logging is even initialized, silently hanging the app at a blank window.
  static Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final rows = await m.database
        .customSelect(
          'SELECT 1 FROM pragma_table_info(?) WHERE name = ?',
          variables: [
            Variable.withString(table.actualTableName),
            Variable.withString(column.name),
          ],
        )
        .get();
    if (rows.isNotEmpty) return;
    await m.addColumn(table, column);
  }

  Future<void> _dropLegacyTables(Migrator m) async {
    const tables = <String>[
      'sync_queue',
      'dictations',
      'recordings',
      'echo_sessions',
      'transcripts',
      'transcript_fetch_states',
      'youtube_feed_entries',
      'youtube_channel_subscriptions',
      'videos',
      'audios',
      'playback_sessions',
      'media',
      'settings',
    ];
    for (final name in tables) {
      await m.database.customStatement('DROP TABLE IF EXISTS $name');
    }
  }
}
