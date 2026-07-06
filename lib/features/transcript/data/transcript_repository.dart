/// Persist imported subtitles for a media item.
library;

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:path/path.dart' as p;

import '../../../core/application/app_language_catalog.dart';
import '../../../core/ids/enjoy_ids.dart';
import '../../../core/logging/log.dart';
import '../../../core/utils/stream_distinct.dart';
import '../../../core/utils/youtube_video_identity.dart';
import '../../../data/api/services/ai/youtube_transcripts_api.dart';
import '../../../data/api/services/transcript_api.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/media_target_resolver.dart';
import '../../../data/subtitle/embedded_subtitle_service.dart';
import '../../../data/subtitle/subtitle_parser.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../../../data/subtitle/subtitle_filename.dart';
import '../domain/transcript_fetch_status.dart';
import '../domain/transcript_track.dart';
import 'sidecar_subtitle_discovery.dart';
import 'transcript_timeline_parse.dart';

class _LinesCacheEntry {
  _LinesCacheEntry(this.updatedAt, this.lines);
  final DateTime updatedAt;
  final List<TranscriptLine> lines;
}

List<TranscriptLine> _decodeTimeline(String timelineJson) {
  final decoded = (jsonDecode(timelineJson) as List)
      .cast<Map<String, dynamic>>();
  return decoded.map(TranscriptLine.fromJson).toList();
}

TranscriptTrack _trackFromRow(TranscriptRow row) {
  return TranscriptTrack(
    id: row.id,
    targetType: row.targetType,
    targetId: row.targetId,
    language: row.language,
    source: row.source,
    label: row.label,
    trackIndex: row.trackIndex,
  );
}

/// Element-wise list comparison for [TranscriptTrack] lists.
///
/// Used by `watchTracks` to absorb identical re-emissions (e.g. when a
/// sibling Drift table bumps but the resolved track list is unchanged)
/// before the value reaches Riverpod listeners. The per-track `==`
/// (via `TranscriptTrack.hashCode` / `operator ==`) handles the
/// element-wise check.
bool _listEqualsTranscriptTrack(
  List<TranscriptTrack> previous,
  List<TranscriptTrack> current,
) {
  if (identical(previous, current)) return true;
  if (previous.length != current.length) return false;
  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != current[i]) return false;
  }
  return true;
}

int _sourcePriority(String source) {
  switch (source) {
    case 'official':
      return 0;
    case 'auto':
      return 1;
    case 'ai':
      return 2;
    case 'user':
      return 3;
    default:
      return 4;
  }
}

void _sortTranscriptRows(List<TranscriptRow> rows) {
  rows.sort((a, b) {
    final pa = _sourcePriority(a.source);
    final pb = _sourcePriority(b.source);
    if (pa != pb) return pa.compareTo(pb);
    return a.createdAt.compareTo(b.createdAt);
  });
}

String _normalizeSource(String raw) {
  switch (raw) {
    case 'official':
    case 'auto':
    case 'ai':
    case 'user':
      return raw;
    default:
      return 'official';
  }
}

DateTime _parseServerDate(dynamic v, DateTime fallback) {
  if (v is String) {
    return DateTime.tryParse(v) ?? fallback;
  }
  return fallback;
}

final Logger _log = logNamed('TranscriptRepository');

/// Matches Worker `YOUTUBE_ID_RE` / `VideoRow.vid` for canonical imports.
final RegExp _youtubeWorkerVideoIdRe = RegExp(r'^[a-zA-Z0-9_-]{11}$');

class TranscriptRepository {
  TranscriptRepository(
    this._db, [
    this._transcriptApi,
    this._youtubeTranscripts,
    int? maxYoutubeWorkerPollAttempts,
    Duration? youtubeWorkerPollDelay,
  ]) : _maxYoutubeWorkerPollAttempts = maxYoutubeWorkerPollAttempts ?? 30,
       _youtubeWorkerPollDelay =
           youtubeWorkerPollDelay ?? const Duration(seconds: 2);

  final AppDatabase _db;
  final TranscriptApi? _transcriptApi;
  final YoutubeTranscriptsClient? _youtubeTranscripts;

  final int _maxYoutubeWorkerPollAttempts;
  final Duration _youtubeWorkerPollDelay;

  final Map<String, _LinesCacheEntry> _linesCache = {};

  /// Decodes [row.timelineJson] with memoization on `(id, updatedAt)`.
  List<TranscriptLine> linesForRow(TranscriptRow row) {
    final hit = _linesCache[row.id];
    if (hit != null && hit.updatedAt == row.updatedAt) return hit.lines;
    final decoded = _decodeTimeline(row.timelineJson);
    _linesCache[row.id] = _LinesCacheEntry(row.updatedAt, decoded);
    return decoded;
  }

  Future<TranscriptRow?> primaryTranscriptRowForMedia(String mediaId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    final echo = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    final id = echo?.transcriptId;
    if (id == null) return null;
    return _db.transcriptDao.getById(id);
  }

  Stream<List<TranscriptTrack>> watchTracks(String mediaId) =>
      Stream.fromFuture(dexieTargetTypeForId(_db, mediaId)).asyncExpand((tt) {
        if (tt == null) {
          return Stream.value(<TranscriptTrack>[]);
        }
        return _db.transcriptDao
            .watchAllForTarget(tt, mediaId)
            .map((rows) {
              final sorted = [...rows];
              _sortTranscriptRows(sorted);
              return sorted.map(_trackFromRow).toList();
            })
            .distinctBy(_listEqualsTranscriptTrack);
      });

  /// Orchestrates transcript resolution when media is opened.
  ///
  /// 1. Ensures a primary transcript when tracks exist.
  /// 2. Imports adjacent sidecar `.srt` / `.vtt` for local files.
  /// 3. Optionally fetches cloud / YouTube transcripts when [fetchCloud].
  Future<TranscriptResolveResult> resolveOnOpen(
    String mediaId, {
    bool forceCloud = false,
    bool fetchCloud = true,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) {
      return const TranscriptResolveResult(hasTracks: false);
    }

    await ensurePrimaryTranscript(mediaId);
    try {
      await importSidecarSubtitles(mediaId);
    } on Object catch (e, st) {
      _log.warning('importSidecarSubtitles failed for $mediaId', e, st);
    }
    await ensurePrimaryTranscript(mediaId);

    TranscriptCloudFetchResult cloud = const TranscriptCloudFetchResult(
      status: TranscriptCloudFetchStatus.skipped,
    );
    if (fetchCloud) {
      cloud = await fetchCloudTranscripts(mediaId, force: forceCloud);
      await ensurePrimaryTranscript(mediaId);
    }

    final hasTracks = (await _db.transcriptDao.listForTarget(
      tt,
      mediaId,
    )).isNotEmpty;
    final result = TranscriptResolveResult(
      hasTracks: hasTracks,
      cloud: cloud,
      errorMessage: cloud.status == TranscriptCloudFetchStatus.error
          ? cloud.errorMessage
          : null,
    );

    if (fetchCloud && cloud.status != TranscriptCloudFetchStatus.skipped) {
      await _persistFetchOutcome(tt, mediaId, result);
    }

    return result;
  }

  /// Assigns primary transcript when tracks exist but session has none.
  Future<bool> ensurePrimaryTranscript(String mediaId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return false;

    final session = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    final rows = await _db.transcriptDao.listForTarget(tt, mediaId);
    _sortTranscriptRows(rows);
    if (rows.isEmpty) return false;

    final currentId = session?.transcriptId;
    if (currentId != null && rows.any((r) => r.id == currentId)) {
      return false;
    }

    await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
      tt,
      mediaId,
      rows.first.id,
    );
    return true;
  }

  /// Imports matching sidecar subtitle files next to a local media file.
  ///
  /// Returns the number of newly imported sidecar files.
  Future<int> importSidecarSubtitles(String mediaId) async {
    final uri = await resolvePlayableSourceUri(_db, mediaId);
    if (uri == null) return 0;

    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return 0;

    final sidecars = discoverSidecarSubtitleFiles(uri);
    if (sidecars.isEmpty) return 0;

    var imported = 0;
    for (final file in sidecars) {
      final name = p.basename(file.path);
      final language = languageHintFromSubtitleFileName(name);
      const source = 'user';
      final id = enjoyTranscriptId(
        targetType: tt,
        targetId: mediaId,
        language: language,
        source: source,
      );
      if (await _db.transcriptDao.getById(id) != null) continue;

      await importSubtitle(
        mediaId: mediaId,
        file: XFile(file.path, name: name),
        language: language,
        label: p.basenameWithoutExtension(name),
      );
      imported++;
    }
    return imported;
  }

  Future<void> _persistFetchOutcome(
    String targetType,
    String mediaId,
    TranscriptResolveResult result,
  ) async {
    final now = DateTime.now();
    final status = result.uiStatus;
    if (status == TranscriptFetchStatus.loading ||
        status == TranscriptFetchStatus.idle) {
      return;
    }

    await _db.transcriptFetchStateDao.upsertOutcome(
      targetType: targetType,
      targetId: mediaId,
      lastFetchedAt: now,
      lastStatus: TranscriptFetchUiState.toPersisted(status),
      lastError: result.errorMessage,
    );
  }

  /// Fetches transcripts from the Enjoy API and upserts them locally.
  ///
  /// When [force] is false, skips if this target was already fetched once
  /// ([TranscriptFetchStates]). On success, marks fetch state. Errors are
  /// logged and persisted as `error` when possible.
  Future<TranscriptCloudFetchResult> fetchCloudTranscripts(
    String mediaId, {
    bool force = false,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    if (!force) {
      final state = await _db.transcriptFetchStateDao.getForTarget(tt, mediaId);
      if (state != null && state.lastStatus != 'error') {
        return const TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.skipped,
        );
      }
    }

    if (tt == 'Video') {
      final video = await _db.videoDao.getById(mediaId);
      if (video != null) {
        final ytPlayback = youtubePlaybackVideoId(
          provider: video.provider,
          vid: video.vid,
          mediaUrl: video.mediaUrl,
          source: video.source,
        );
        if (ytPlayback != null && _youtubeTranscripts != null) {
          try {
            return await _fetchYoutubeWorkerTranscripts(
              mediaId: mediaId,
              video: video,
              force: force,
            );
          } on Object catch (e, st) {
            _log.warning(
              'fetchCloudTranscripts (YouTube worker) failed for $mediaId',
              e,
              st,
            );
            return TranscriptCloudFetchResult(
              status: TranscriptCloudFetchStatus.error,
              errorMessage: e.toString(),
            );
          }
        }
      }
    }

    final api = _transcriptApi;
    if (api == null) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    try {
      final list = await api.transcripts(targetId: mediaId, targetType: tt);
      final now = DateTime.now();
      var storedCount = 0;
      for (final item in list) {
        final row = _transcriptRowFromServerMap(item, fallbackNow: now);
        if (row == null) continue;
        await _db.transcriptDao.upsert(row);
        storedCount++;
      }

      if (list.isNotEmpty && storedCount == 0) {
        return const TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.error,
          errorMessage: 'Could not store cloud transcripts',
        );
      }

      if (storedCount > 0) {
        await ensurePrimaryTranscript(mediaId);
        return TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.success,
          storedCount: storedCount,
        );
      }

      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.empty,
      );
    } on Object catch (e, st) {
      _log.warning('fetchCloudTranscripts failed for $mediaId', e, st);
      return TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Worker body `video_id` / `videoId`: prefer [VideoRow.vid] when it is an
  /// 11-character YouTube id; otherwise fall back to [youtubePlaybackVideoId].
  String _workerYoutubeVideoId(VideoRow video) {
    final v = video.vid.trim();
    if (_youtubeWorkerVideoIdRe.hasMatch(v)) return v;
    final pb = youtubePlaybackVideoId(
      provider: video.provider,
      vid: video.vid,
      mediaUrl: video.mediaUrl,
      source: video.source,
    );
    return pb ?? v;
  }

  String? _workerCaptionLanguage(VideoRow video) {
    final lang = video.language.trim();
    if (lang.isEmpty || lang == 'und') return null;
    return workerLanguageBase(lang);
  }

  Future<TranscriptCloudFetchResult> _fetchYoutubeWorkerTranscripts({
    required String mediaId,
    required VideoRow video,
    required bool force,
  }) async {
    final api = _youtubeTranscripts;
    if (api == null) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    final workerVideoId = _workerYoutubeVideoId(video);
    final language = _workerCaptionLanguage(video);
    if (language == null) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }
    final now = DateTime.now();

    for (var attempt = 0; attempt < _maxYoutubeWorkerPollAttempts; attempt++) {
      final map = await api.pollTranscript(
        videoId: workerVideoId,
        language: language,
        captionFetch: 'auto',
        forceRefresh: attempt == 0 && force,
      );

      final status = map['status'] as String?;
      if (status == 'ready') {
        final stored = await _upsertYoutubeWorkerReadyTranscript(
          mediaId: mediaId,
          response: map,
          fallbackNow: now,
        );
        if (stored) {
          await ensurePrimaryTranscript(mediaId);
          return const TranscriptCloudFetchResult(
            status: TranscriptCloudFetchStatus.success,
            storedCount: 1,
          );
        }
        return const TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.empty,
        );
      }

      if (status == 'failed') {
        final err = map['error']?.toString() ?? 'YouTube transcript failed';
        _log.warning('YouTube worker transcript failed for $mediaId: $err');
        return TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.error,
          errorMessage: err,
        );
      }

      if (attempt < _maxYoutubeWorkerPollAttempts - 1) {
        await Future<void>.delayed(_youtubeWorkerPollDelay);
      }
    }

    return const TranscriptCloudFetchResult(
      status: TranscriptCloudFetchStatus.error,
      errorMessage: 'Timed out waiting for YouTube transcripts',
    );
  }

  /// Returns whether a non-empty transcript row was written.
  Future<bool> _upsertYoutubeWorkerReadyTranscript({
    required String mediaId,
    required Map<String, dynamic> response,
    required DateTime fallbackNow,
  }) async {
    final language = response['language'] as String? ?? 'en';
    final rawSource = response['source'] as String? ?? 'official';
    final source = _normalizeSource(rawSource);
    final lines = transcriptLinesFromApiTimeline(response['timeline']);
    if (lines.isEmpty) return false;

    final id = enjoyTranscriptId(
      targetType: 'Video',
      targetId: mediaId,
      language: language,
      source: source,
    );

    final label = _youtubeWorkerTranscriptLabel(response, language);
    final rawUrl = response['rawUrl'] as String?;
    final timelineJson = jsonEncode(lines.map((e) => e.toJson()).toList());
    final updated = DateTime.now();

    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        targetType: 'Video',
        targetId: mediaId,
        language: language,
        source: source,
        timelineJson: timelineJson,
        referenceId: rawUrl,
        label: label,
        trackIndex: null,
        syncStatus: 'synced',
        serverUpdatedAt: updated,
        createdAt: fallbackNow,
        updatedAt: updated,
      ),
    );
    return true;
  }

  String _youtubeWorkerTranscriptLabel(
    Map<String, dynamic> response,
    String language,
  ) {
    final meta = response['metadata'];
    if (meta is Map) {
      final title = meta['title'];
      if (title is String && title.trim().isNotEmpty) return title.trim();
    }
    return 'YouTube captions ($language)';
  }

  TranscriptRow? _transcriptRowFromServerMap(
    Map<String, dynamic> json, {
    required DateTime fallbackNow,
  }) {
    final id = json['id'] as String?;
    final targetType = json['targetType'] as String?;
    final targetId = json['targetId'] as String?;
    final language = json['language'] as String?;
    final rawSource = json['source'] as String?;
    final timeline = json['timeline'];

    if (id == null ||
        targetType == null ||
        targetId == null ||
        language == null ||
        rawSource == null) {
      return null;
    }

    final source = _normalizeSource(rawSource);
    final lines = transcriptLinesFromApiTimeline(timeline);
    if (lines.isEmpty) return null;

    final timelineJson = jsonEncode(lines.map((e) => e.toJson()).toList());
    final createdAt = _parseServerDate(json['createdAt'], fallbackNow);
    final updatedAt = _parseServerDate(json['updatedAt'], fallbackNow);
    final label = (json['label'] as String?) ?? '';
    final referenceId = json['referenceId'] as String?;

    return TranscriptRow(
      id: id,
      targetType: targetType,
      targetId: targetId,
      language: language,
      source: source,
      timelineJson: timelineJson,
      referenceId: referenceId,
      label: label,
      trackIndex: null,
      syncStatus: 'synced',
      serverUpdatedAt: updatedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<void> importSubtitle({
    required String mediaId,
    required XFile file,
    required String language,
    String? label,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    final text = await file.readAsString();
    final lines = const SubtitleParserFacade().parseWithHint(
      text,
      fileName: file.name,
    );
    final json = jsonEncode(lines.map((e) => e.toJson()).toList());
    const source = 'user';
    final id = enjoyTranscriptId(
      targetType: tt,
      targetId: mediaId,
      language: language,
      source: source,
    );
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        targetType: tt,
        targetId: mediaId,
        language: language,
        source: source,
        timelineJson: json,
        referenceId: null,
        label: label ?? p.basenameWithoutExtension(file.name),
        trackIndex: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final session = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    if (session?.transcriptId == null) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
        tt,
        mediaId,
        id,
      );
    }
  }

  /// Extracts embedded subtitle streams via ffmpeg; stored as `source: user`.
  ///
  /// Returns the number of new/updated transcript rows written.
  ///
  /// [playerSubtitleTracks] may be empty: subtitle streams are then discovered
  /// via `ffmpeg -i` (see [EmbeddedSubtitleService.extractTracks]).
  Future<int> extractEmbeddedTracks({
    required String mediaId,
    required String sourceUri,
    List<mk.SubtitleTrack> playerSubtitleTracks = const [],
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return 0;

    final existing = await _db.transcriptDao.listForTarget(tt, mediaId);
    final existingIndices = existing
        .where((r) => r.trackIndex != null)
        .map((r) => r.trackIndex!)
        .toSet();

    final extracted = await const EmbeddedSubtitleService().extractTracks(
      targetId: mediaId,
      targetTypeDexie: tt,
      mediaSourceUri: sourceUri,
      tracks: playerSubtitleTracks,
      existingTrackIndices: existingIndices,
    );

    if (extracted.isEmpty) return 0;

    for (final row in extracted) {
      await _db.transcriptDao.upsert(row);
    }

    final session = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    if (session?.transcriptId == null) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
        tt,
        mediaId,
        extracted.first.id,
      );
    }

    return extracted.length;
  }

  Future<void> setActiveTranscript(String mediaId, String transcriptId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
      tt,
      mediaId,
      transcriptId,
    );
  }

  Future<void> setSecondaryTranscript(
    String mediaId,
    String? transcriptId,
  ) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    await _db.echoSessionDao.updateSecondaryTranscriptForTarget(
      tt,
      mediaId,
      transcriptId,
    );
  }

  Future<void> deleteTranscript(String transcriptId) async {
    final row = await _db.transcriptDao.getById(transcriptId);
    if (row == null) return;

    final targetType = row.targetType;
    final targetId = row.targetId;
    final session = await _db.echoSessionDao.getLatestForTarget(
      targetType,
      targetId,
    );

    _linesCache.remove(transcriptId);
    await _db.transcriptDao.deleteId(transcriptId);

    if (session == null) return;

    var newPrimary = session.transcriptId;
    var newSecondary = session.secondaryTranscriptId;

    if (session.transcriptId == transcriptId) {
      newPrimary = await _nextPrimaryAfterDelete(targetType, targetId);
    }
    if (session.secondaryTranscriptId == transcriptId) {
      newSecondary = null;
    }
    if (newPrimary != null && newSecondary == newPrimary) {
      newSecondary = null;
    }

    if (newPrimary != session.transcriptId) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
        targetType,
        targetId,
        newPrimary,
      );
    }
    if (newSecondary != session.secondaryTranscriptId) {
      await _db.echoSessionDao.updateSecondaryTranscriptForTarget(
        targetType,
        targetId,
        newSecondary,
      );
    }
  }

  /// Picks the next primary transcript for [targetId] after delete:
  /// [official] > [auto] > [ai] > [user], then earliest [createdAt].
  Future<String?> _nextPrimaryAfterDelete(
    String targetType,
    String targetId,
  ) async {
    final remaining = await _db.transcriptDao.listForTarget(
      targetType,
      targetId,
    );
    if (remaining.isEmpty) return null;
    _sortTranscriptRows(remaining);
    return remaining.first.id;
  }
}
