/// Root Drift database for Enjoy Player (native SQLite via drift_flutter).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Default Drift database name (guest / signed-out local data).
  static const String guestDatabaseName = 'enjoy_player';

  AppDatabase({QueryExecutor? executor, String name = guestDatabaseName})
    : _dbName = name,
      super(executor ?? driftDatabase(name: name));

  /// Drift / sqlite file name (no path) for this instance.
  ///
  /// Used by callers (e.g. `SyncCtrl._onSignedIn`) that need to know
  /// whether they are about to read the guest DB or a per-user DB
  /// without having to inspect the executor.
  final String _dbName;

  /// True when this instance serves the device-global guest file.
  bool get isGuestDatabase => _dbName == guestDatabaseName;

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 7 && to == 8) {
        await m.addColumn(
          youtubeFeedEntries,
          youtubeFeedEntries.durationSeconds,
        );
        return;
      }

      // v6 → v7 only adds Discover tables; preserve existing library data.
      if (from >= 6 && to == 7) {
        await m.createTable(youtubeChannelSubscriptions);
        await m.createTable(youtubeFeedEntries);
        return;
      }

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
      await m.createAll();
    },
  );
}

@DriftAccessor(tables: [Videos])
class VideoDao extends DatabaseAccessor<AppDatabase> with _$VideoDaoMixin {
  VideoDao(super.db);

  Stream<List<VideoRow>> watchAll() => (select(
    videos,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<VideoRow?> getById(String id) =>
      (select(videos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<VideoRow?> getYoutubeByVid(String youtubeVid) =>
      (select(videos)..where(
            (t) => t.provider.equals('youtube') & t.vid.equals(youtubeVid),
          ))
          .getSingleOrNull();

  Future<List<VideoRow>> listAll() => select(videos).get();

  Future<void> insertRow(VideoRow row) =>
      into(videos).insert(row, mode: InsertMode.insertOrReplace);

  /// Partial update so concurrent duration/thumbnail jobs do not clobber columns.
  Future<void> updateLocalThumbnail(String id, String absoluteThumbPath) async {
    await (update(videos)..where((t) => t.id.equals(id))).write(
      VideosCompanion(
        thumbnailUrl: Value(absoluteThumbPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Partial update for YouTube oEmbed title/thumbnail refresh.
  Future<void> updateYoutubeMetadata({
    required String id,
    required String title,
    String? thumbnailUrl,
  }) async {
    await (update(videos)..where((t) => t.id.equals(id))).write(
      VideosCompanion(
        title: Value(title),
        thumbnailUrl: thumbnailUrl == null
            ? const Value.absent()
            : Value(thumbnailUrl),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteId(String id) =>
      (delete(videos)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Audios])
class AudioDao extends DatabaseAccessor<AppDatabase> with _$AudioDaoMixin {
  AudioDao(super.db);

  Stream<List<AudioRow>> watchAll() => (select(
    audios,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<AudioRow?> getById(String id) =>
      (select(audios)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(AudioRow row) =>
      into(audios).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(audios)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Transcripts])
class TranscriptDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptDaoMixin {
  TranscriptDao(super.db);

  Stream<List<TranscriptRow>> watchForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.language)]))
          .watch();

  Stream<List<TranscriptRow>> watchAllForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.source),
              (t) => OrderingTerm.asc(t.language),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  /// Existence-only stream (no `timeline_json` reads) for UI like transport buttons.
  Stream<bool> watchExistsForTarget(String targetType, String targetId) {
    return customSelect(
      'SELECT EXISTS (SELECT 1 FROM transcripts WHERE target_type = ? AND target_id = ?) AS e',
      variables: [
        Variable.withString(targetType),
        Variable.withString(targetId),
      ],
      readsFrom: {transcripts},
    ).watch().map((rows) => rows.first.read<int>('e') != 0);
  }

  Future<TranscriptRow?> getById(String id) =>
      (select(transcripts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TranscriptRow>> listForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)..where(
            (t) =>
                t.targetType.equals(targetType) & t.targetId.equals(targetId),
          ))
          .get();

  Future<void> upsert(TranscriptRow row) =>
      into(transcripts).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(transcripts)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [TranscriptFetchStates])
class TranscriptFetchStateDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptFetchStateDaoMixin {
  TranscriptFetchStateDao(super.db);

  Future<TranscriptFetchStateRow?> getForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcriptFetchStates)..where(
            (t) =>
                t.targetType.equals(targetType) & t.targetId.equals(targetId),
          ))
          .getSingleOrNull();

  Future<void> upsertFetched(
    String targetType,
    String targetId,
    DateTime lastFetchedAt, {
    String? lastStatus,
    String? lastError,
  }) => upsertOutcome(
    targetType: targetType,
    targetId: targetId,
    lastFetchedAt: lastFetchedAt,
    lastStatus: lastStatus ?? 'success',
    lastError: lastError,
  );

  Future<void> upsertOutcome({
    required String targetType,
    required String targetId,
    required DateTime lastFetchedAt,
    required String lastStatus,
    String? lastError,
  }) => into(transcriptFetchStates).insert(
    TranscriptFetchStateRow(
      targetType: targetType,
      targetId: targetId,
      lastFetchedAt: lastFetchedAt,
      lastStatus: lastStatus,
      lastError: lastError,
    ),
    mode: InsertMode.insertOrReplace,
  );
}

@DriftAccessor(tables: [EchoSessions])
class EchoSessionDao extends DatabaseAccessor<AppDatabase>
    with _$EchoSessionDaoMixin {
  EchoSessionDao(super.db);

  // ignore: prefer_const_constructors — Uuid() is not const
  static final Uuid _uuid = Uuid();

  EchoSessionRow _newSession({
    required String targetType,
    required String targetId,
    String language = 'und',
    String? transcriptId,
    String? secondaryTranscriptId,
  }) {
    final now = DateTime.now();
    return EchoSessionRow(
      id: _uuid.v4(),
      targetType: targetType,
      targetId: targetId,
      language: language,
      currentTimeMs: 0,
      playbackRate: 1,
      volume: 1,
      echoStartMs: null,
      echoEndMs: null,
      transcriptId: transcriptId,
      secondaryTranscriptId: secondaryTranscriptId,
      recordingsCount: 0,
      recordingsDurationMs: 0,
      lastRecordingAt: null,
      currentSegmentIndex: -1,
      echoActive: false,
      echoStartLine: -1,
      echoEndLine: -1,
      startedAt: now,
      lastActiveAt: now,
      completedAt: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Ensures at least one echo session row exists for the target (creates if missing).
  Future<EchoSessionRow> getOrCreateLatestForTarget(
    String targetType,
    String targetId,
  ) async {
    final existing = await getLatestForTarget(targetType, targetId);
    if (existing != null) return existing;
    final row = _newSession(targetType: targetType, targetId: targetId);
    await into(echoSessions).insert(row);
    return row;
  }

  Future<EchoSessionRow?> getLatestForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(echoSessions)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.lastActiveAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<EchoSessionRow?> watchLatestForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(echoSessions)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.lastActiveAt)])
            ..limit(1))
          .watch()
          .map((rows) => rows.isEmpty ? null : rows.first);

  Future<void> upsert(EchoSessionRow row) =>
      into(echoSessions).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> updatePrimaryTranscriptForTarget(
    String targetType,
    String targetId,
    String? transcriptId,
  ) async {
    final latest = await getLatestForTarget(targetType, targetId);
    final now = DateTime.now();
    if (latest == null) {
      await into(echoSessions).insert(
        _newSession(
          targetType: targetType,
          targetId: targetId,
          transcriptId: transcriptId,
        ),
      );
    } else {
      await (update(echoSessions)..where((t) => t.id.equals(latest.id))).write(
        EchoSessionsCompanion(
          transcriptId: Value(transcriptId),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> updateSecondaryTranscriptForTarget(
    String targetType,
    String targetId,
    String? secondaryTranscriptId,
  ) async {
    final latest = await getLatestForTarget(targetType, targetId);
    final now = DateTime.now();
    if (latest == null) {
      await into(echoSessions).insert(
        _newSession(
          targetType: targetType,
          targetId: targetId,
          secondaryTranscriptId: secondaryTranscriptId,
        ),
      );
    } else {
      await (update(echoSessions)..where((t) => t.id.equals(latest.id))).write(
        EchoSessionsCompanion(
          secondaryTranscriptId: Value(secondaryTranscriptId),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Local aggregates for profile stats (single round-trip).
  Future<({int sessionCount, int recordingsDurationMs})> practiceTotals() {
    return customSelect(
          'SELECT COUNT(*) AS c, COALESCE(SUM(recordings_duration_ms), 0) AS d '
          'FROM echo_sessions',
          readsFrom: {echoSessions},
        )
        .map(
          (row) => (
            sessionCount: row.read<int>('c'),
            recordingsDurationMs: row.read<int>('d'),
          ),
        )
        .getSingle();
  }
}

@DriftAccessor(tables: [Recordings])
class RecordingDao extends DatabaseAccessor<AppDatabase>
    with _$RecordingDaoMixin {
  RecordingDao(super.db);

  Stream<List<RecordingRow>> watchByTarget(
    String targetType,
    String targetId,
  ) =>
      (select(recordings)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Echo-region overlap — same rules as web `getRecordingsByEchoRegion`.
  Stream<List<RecordingRow>> watchByEchoRegion({
    required String targetType,
    required String targetId,
    required String language,
    required int echoStartMs,
    required int echoEndMs,
  }) =>
      (select(recordings)
            ..where((t) {
              final recordingEnd = t.referenceStart + t.referenceDuration;
              return t.targetType.equals(targetType) &
                  t.targetId.equals(targetId) &
                  t.language.equals(language) &
                  t.referenceStart.isSmallerThanValue(echoEndMs) &
                  recordingEnd.isBiggerThanValue(echoStartMs);
            })
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<RecordingRow>> listByEchoRegion({
    required String targetType,
    required String targetId,
    required String language,
    required int echoStartMs,
    required int echoEndMs,
  }) async {
    return (select(recordings)
          ..where((t) {
            final recordingEnd = t.referenceStart + t.referenceDuration;
            return t.targetType.equals(targetType) &
                t.targetId.equals(targetId) &
                t.language.equals(language) &
                t.referenceStart.isSmallerThanValue(echoEndMs) &
                recordingEnd.isBiggerThanValue(echoStartMs);
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<RecordingRow?> getById(String id) =>
      (select(recordings)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertRow(RecordingRow row) =>
      into(recordings).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> updateAssessment({
    required String id,
    required int? pronunciationScore,
    required String? assessmentJson,
    required DateTime updatedAt,
  }) => (update(recordings)..where((t) => t.id.equals(id))).write(
    RecordingsCompanion(
      pronunciationScore: Value(pronunciationScore),
      assessmentJson: Value(assessmentJson),
      updatedAt: Value(updatedAt),
      syncStatus: const Value('local'),
    ),
  );

  Future<void> deleteId(String id) =>
      (delete(recordings)..where((t) => t.id.equals(id))).go();
}

/// Recording `[referenceStart, referenceStart + referenceDuration)` vs echo `[echoStartMs, echoEndMs)` (ms).
bool recordingOverlapsEchoRegion(
  RecordingRow r,
  int echoStartMs,
  int echoEndMs,
) {
  final recordingStart = r.referenceStart;
  final recordingEnd = r.referenceStart + r.referenceDuration;
  final overlapStart = recordingStart > echoStartMs
      ? recordingStart
      : echoStartMs;
  final overlapEnd = recordingEnd < echoEndMs ? recordingEnd : echoEndMs;
  return overlapStart < overlapEnd;
}

@DriftAccessor(tables: [Dictations])
class DictationDao extends DatabaseAccessor<AppDatabase>
    with _$DictationDaoMixin {
  DictationDao(super.db);

  Stream<List<DictationRow>> watchByTarget(
    String targetType,
    String targetId,
  ) =>
      (select(dictations)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> insertRow(DictationRow row) =>
      into(dictations).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(dictations)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> enqueue({
    required String entityType,
    required String entityId,
    required String action,
    String? payloadJson,
  }) => into(syncQueue).insert(
    SyncQueueCompanion.insert(
      entityType: entityType,
      entityId: entityId,
      action: action,
      payloadJson: Value(payloadJson),
      createdAt: DateTime.now(),
    ),
  );

  Future<List<SyncQueueRow>> peekBatch({int limit = 50}) =>
      (select(syncQueue)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<void> markAttempted(int id, {String? error}) async {
    final existing = await (select(
      syncQueue,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(existing.retryCount + 1),
        lastAttempt: Value(DateTime.now()),
        error: Value(error),
      ),
    );
  }

  Future<void> deleteId(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [SettingsKv])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(
      settingsKv,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) => into(settingsKv).insert(
    SettingRow(key: key, value: value),
    mode: InsertMode.insertOrReplace,
  );
}

@DriftAccessor(tables: [YoutubeChannelSubscriptions])
class YoutubeChannelSubscriptionDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubeChannelSubscriptionDaoMixin {
  YoutubeChannelSubscriptionDao(super.db);

  Stream<List<YoutubeChannelSubscriptionRow>> watchAll() => (select(
    youtubeChannelSubscriptions,
  )..orderBy([(t) => OrderingTerm.asc(t.displayName)])).watch();

  Future<List<YoutubeChannelSubscriptionRow>> listAll() =>
      select(youtubeChannelSubscriptions).get();

  Future<YoutubeChannelSubscriptionRow?> getByChannelId(String channelId) =>
      (select(
        youtubeChannelSubscriptions,
      )..where((t) => t.channelId.equals(channelId))).getSingleOrNull();

  Future<void> upsert(YoutubeChannelSubscriptionRow row) => into(
    youtubeChannelSubscriptions,
  ).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteChannelId(String channelId) => (delete(
    youtubeChannelSubscriptions,
  )..where((t) => t.channelId.equals(channelId))).go();

  Future<void> touchLastFetched(String channelId, DateTime fetchedAt) async {
    await (update(
      youtubeChannelSubscriptions,
    )..where((t) => t.channelId.equals(channelId))).write(
      YoutubeChannelSubscriptionsCompanion(lastFetchedAt: Value(fetchedAt)),
    );
  }

  Future<void> updateDisplayName(String channelId, String displayName) async {
    await (update(
      youtubeChannelSubscriptions,
    )..where((t) => t.channelId.equals(channelId))).write(
      YoutubeChannelSubscriptionsCompanion(displayName: Value(displayName)),
    );
  }

  Future<void> updateThumbnail(String channelId, String? thumbnailUrl) async {
    await (update(
      youtubeChannelSubscriptions,
    )..where((t) => t.channelId.equals(channelId))).write(
      YoutubeChannelSubscriptionsCompanion(thumbnailUrl: Value(thumbnailUrl)),
    );
  }
}

@DriftAccessor(tables: [YoutubeFeedEntries])
class YoutubeFeedEntryDao extends DatabaseAccessor<AppDatabase>
    with _$YoutubeFeedEntryDaoMixin {
  YoutubeFeedEntryDao(super.db);

  Stream<List<YoutubeFeedEntryRow>> watchTimeline() => (select(
    youtubeFeedEntries,
  )..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])).watch();

  Stream<List<YoutubeFeedEntryRow>> watchForChannel(String channelId) =>
      (select(youtubeFeedEntries)
            ..where((t) => t.channelId.equals(channelId))
            ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)]))
          .watch();

  Future<void> upsertEntry(YoutubeFeedEntryRow row) =>
      into(youtubeFeedEntries).insert(row, mode: InsertMode.insertOrReplace);

  Future<YoutubeFeedEntryRow?> getEntry({
    required String channelId,
    required String videoId,
  }) =>
      (select(youtubeFeedEntries)..where(
            (t) => t.channelId.equals(channelId) & t.videoId.equals(videoId),
          ))
          .getSingleOrNull();

  Future<void> updateDurationSeconds({
    required String channelId,
    required String videoId,
    required int durationSeconds,
  }) async {
    await (update(youtubeFeedEntries)..where(
          (t) => t.channelId.equals(channelId) & t.videoId.equals(videoId),
        ))
        .write(
          YoutubeFeedEntriesCompanion(durationSeconds: Value(durationSeconds)),
        );
  }

  Future<void> deleteForChannel(String channelId) => (delete(
    youtubeFeedEntries,
  )..where((t) => t.channelId.equals(channelId))).go();

  /// Removes cached entries for [channelId] not present in [keepVideoIds].
  Future<void> deleteStaleForChannel(
    String channelId,
    Set<String> keepVideoIds,
  ) async {
    if (keepVideoIds.isEmpty) {
      await deleteForChannel(channelId);
      return;
    }
    await (delete(youtubeFeedEntries)..where(
          (t) =>
              t.channelId.equals(channelId) & t.videoId.isNotIn(keepVideoIds),
        ))
        .go();
  }
}
