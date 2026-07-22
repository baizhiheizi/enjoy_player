/// Persist imported subtitles for a media item.
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:path/path.dart' as p;

import '../../../core/application/app_language_catalog.dart';
import '../../../core/ids/enjoy_ids.dart';
import '../../../core/logging/log.dart';
import '../../../core/utils/collections.dart';
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
import '../domain/auto_translate.dart';
import '../domain/transcript_fetch_status.dart';
import '../domain/transcript_track.dart';
import 'sidecar_subtitle_discovery.dart';
import 'transcript_timeline_parse.dart';
import 'youtube_caption_fetcher.dart';

part 'transcript_repository_subtitle_import.dart';
part 'transcript_repository_youtube_fetch.dart';
part 'transcript_repository_youtube_worker_cache.dart';

class _LinesCacheEntry {
  _LinesCacheEntry(this.hash, this.lines);
  final String hash;
  final List<TranscriptLine> lines;
}

String _timelineJsonHash(String timelineJson) =>
    sha1.convert(utf8.encode(timelineJson)).toString().substring(0, 16);

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
    this._youtubeFetcher,
  ]);

  final AppDatabase _db;
  final TranscriptApi? _transcriptApi;
  final YoutubeTranscriptsClient? _youtubeTranscripts;
  final YoutubeCaptionFetcher? _youtubeFetcher;

  final Map<String, _LinesCacheEntry> _linesCache = {};

  /// Decodes [row.timelineJson] with memoization on `(id, timelineJsonHash)`.
  ///
  /// The hash-on-content key avoids re-decoding when an unrelated Drift table
  /// bump shifts the row's `updatedAt` without changing `timelineJson`.
  List<TranscriptLine> linesForRow(TranscriptRow row) {
    final hash = _timelineJsonHash(row.timelineJson);
    final hit = _linesCache[row.id];
    if (hit != null && hit.hash == hash) return hit.lines;
    final decoded = _decodeTimeline(row.timelineJson);
    _linesCache[row.id] = _LinesCacheEntry(hash, decoded);
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
            .distinctBy(listEquals);
      });

  /// Orchestrates transcript resolution when media is opened.
  ///
  /// 1. Ensures a primary transcript when tracks exist.
  /// 2. Imports adjacent sidecar `.srt` / `.vtt` for local files.
  /// 3. Optionally fetches cloud / YouTube transcripts when [fetchCloud].
  ///
  /// [nativeLanguage] / [learningLanguage] are forwarded to the YouTube
  /// branch so the post-fetch primary picker can prefer tracks matching the
  /// video's content language first, then the user's learning language,
  /// then fall back to source priority.
  Future<TranscriptResolveResult> resolveOnOpen(
    String mediaId, {
    bool forceCloud = false,
    bool fetchCloud = true,
    String? nativeLanguage,
    String? learningLanguage,
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
      cloud = await fetchCloudTranscripts(
        mediaId,
        force: forceCloud,
        nativeLanguage: nativeLanguage,
        learningLanguage: learningLanguage,
      );
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
    String? nativeLanguage,
    String? learningLanguage,
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
        if (ytPlayback != null) {
          try {
            return await _fetchYoutubeTranscriptsWithFallback(
              mediaId: mediaId,
              video: video,
              force: force,
              learningLanguage: learningLanguage,
            );
          } on Object catch (e, st) {
            _log.warning(
              'fetchCloudTranscripts (YouTube fallback) failed for $mediaId',
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

  /// Persists a generated `source: 'ai'` transcript for [mediaId] +
  /// [language] using a deterministic row id so re-generation upserts
  /// in place (SC-004 / FR-010).
  ///
  /// When [activateAsPrimary] is true (default), the new track is set
  /// as the session primary (FR-021). The prior `label` is preserved
  /// across re-generations so the user keeps a familiar name (FR-022).
  /// Returns the row id, or null when the media id cannot be resolved.
  Future<String?> upsertAsrGeneratedTrack({
    required String mediaId,
    required String language,
    required List<TranscriptLine> lines,
    String? label,
    bool activateAsPrimary = true,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    if (lines.isEmpty) return null;

    const source = 'ai';
    final id = enjoyTranscriptId(
      targetType: tt,
      targetId: mediaId,
      language: language,
      source: source,
    );
    final existing = await _db.transcriptDao.getById(id);
    final now = DateTime.now();
    final resolvedLabel = (label != null && label.isNotEmpty)
        ? label
        : (existing?.label.isNotEmpty == true
              ? existing!.label
              : 'Generated ($language)');
    final timelineJson = jsonEncode(lines.map((e) => e.toJson()).toList());

    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        targetType: tt,
        targetId: mediaId,
        language: language,
        source: source,
        timelineJson: timelineJson,
        referenceId: null,
        label: resolvedLabel,
        trackIndex: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    _linesCache.remove(id);

    if (activateAsPrimary) {
      await setActiveTranscript(mediaId, id);
    }
    return id;
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

  /// Ensures a durable `source: ai` track exists with a timing skeleton for
  /// auto-translate. Returns the track id, or null when the target is unknown.
  ///
  /// When a non-stale AI track already exists for the same primary, its
  /// translated texts are **preserved** (no rewrite). Stale tracks are rebuilt
  /// as an empty skeleton so mismatched bilingual pairs are never shown.
  Future<String?> ensureAutoTranslateTrack({
    required String mediaId,
    required String primaryTranscriptId,
    required String targetLanguage,
    required List<TranscriptLine> primaryLines,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null || primaryLines.isEmpty) return null;

    final id = autoTranslateAiTrackId(
      targetType: tt,
      mediaId: mediaId,
      targetLanguage: targetLanguage,
    );
    final existing = await _db.transcriptDao.getById(id);
    if (existing != null &&
        !isAutoTranslateTrackStale(
          aiRow: existing,
          primaryId: primaryTranscriptId,
          primaryLines: primaryLines,
        )) {
      return id;
    }

    final skeleton = buildAutoTranslateSkeleton(primaryLines);
    final json = jsonEncode(skeleton.map((e) => e.toJson()).toList());
    final now = DateTime.now();

    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        targetType: tt,
        targetId: mediaId,
        language: targetLanguage,
        source: 'ai',
        timelineJson: json,
        referenceId: primaryTranscriptId,
        label: existing?.label.isNotEmpty == true
            ? existing!.label
            : 'Auto translate ($targetLanguage)',
        trackIndex: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    _linesCache.remove(id);
    return id;
  }

  /// Writes one translated line into the AI track timeline.
  Future<void> updateAutoTranslateLineText({
    required String aiTranscriptId,
    required int lineIndex,
    required String text,
    String? sourceKey,
  }) async {
    final row = await _db.transcriptDao.getById(aiTranscriptId);
    if (row == null) return;
    final lines = List<TranscriptLine>.from(linesForRow(row));
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    lines[lineIndex] = TranscriptLine(
      text: text,
      startMs: lines[lineIndex].startMs,
      durationMs: lines[lineIndex].durationMs,
      sourceKey: text.trim().isEmpty ? null : sourceKey,
    );
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      row.copyWith(
        timelineJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
        updatedAt: now,
      ),
    );
    _linesCache.remove(aiTranscriptId);
  }

  /// Whether the AI track is out of sync with the current primary transcript.
  bool isAutoTranslateTrackStale({
    required TranscriptRow aiRow,
    required String primaryId,
    required List<TranscriptLine> primaryLines,
  }) {
    final aiLines = linesForRow(aiRow);
    return isAutoTranslateTimelineStale(
      referencePrimaryId: aiRow.referenceId,
      primaryId: primaryId,
      primaryLines: primaryLines,
      aiLines: aiLines,
    );
  }

  /// Clears translated texts while preserving timing skeleton (Re-translate).
  Future<void> clearAutoTranslateTexts({
    required String aiTranscriptId,
    required List<TranscriptLine> primaryLines,
  }) async {
    final row = await _db.transcriptDao.getById(aiTranscriptId);
    if (row == null) return;
    final skeleton = buildAutoTranslateSkeleton(primaryLines);
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      row.copyWith(
        timelineJson: jsonEncode(skeleton.map((e) => e.toJson()).toList()),
        updatedAt: now,
      ),
    );
    _linesCache.remove(aiTranscriptId);
  }

  Future<TranscriptRow?> transcriptRowById(String transcriptId) =>
      _db.transcriptDao.getById(transcriptId);

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
