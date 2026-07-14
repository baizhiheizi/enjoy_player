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
    String? nativeLanguage,
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
    String? nativeLanguage,
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

  /// Stores a transcript row from a worker GET cache response.
  Future<bool> _upsertWorkerCachedTranscript({
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
        referenceId: response['rawUrl'] as String?,
        label: 'YouTube captions ($language)',
        trackIndex: null,
        syncStatus: 'synced',
        serverUpdatedAt: updated,
        createdAt: fallbackNow,
        updatedAt: updated,
      ),
    );
    return true;
  }

  /// Three-tier fallback chain for YouTube transcript fetching.
  ///
  /// Tier 1: Worker GET cache (skipped when [force] is true).
  /// Tier 2: Client-side direct YouTube fetch (bypasses worker).
  /// Every direct fetch uploads all tracks to the worker for caching.
  ///
  /// Every branch logs its outcome (at INFO or WARNING) so the chain is
  /// observable in production. Without these logs a Windows → worker → Android
  /// failure mode looks like a true no-op: no server-side upload log, no
  /// client-side failure, no UI signal.
  Future<TranscriptCloudFetchResult> _fetchYoutubeTranscriptsWithFallback({
    required String mediaId,
    required VideoRow video,
    required bool force,
  }) async {
    final workerVideoId = _workerYoutubeVideoId(video);
    final language = _workerCaptionLanguage(video);
    if (language == null) {
      // Do NOT silently skip: if a YouTube video row was imported without a
      // content language, the worker cache lookup and the Innertube fallback
      // both short-circuit. The user sees no captions and no error; this log
      // is the only breadcrumb that the chain was skipped.
      _log.warning(
        'YouTube transcript chain skipped for $mediaId: '
        'videos.language is missing or "und" '
        '(set the media content language to enable fetch)',
      );
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    // Tier 1: Worker GET cache (skip when forcing a refresh)
    if (!force) {
      _log.info('YouTube Tier 1 (worker cache) GET $workerVideoId/$language');
      final cached = await _fetchWorkerCachedTranscript(
        videoId: workerVideoId,
        language: language,
      );
      if (cached != null) {
        final result = await _upsertWorkerCachedTranscript(
          mediaId: mediaId,
          response: cached,
          fallbackNow: DateTime.now(),
        );
        if (result) {
          _log.info(
            'YouTube Tier 1 hit for $workerVideoId/$language — '
            'using cached transcript (skipping InnerTube)',
          );
          return const TranscriptCloudFetchResult(
            status: TranscriptCloudFetchStatus.success,
            storedCount: 1,
          );
        }
        _log.info(
          'YouTube Tier 1 returned a body but stored 0 lines — '
          'falling through to InnerTube',
        );
        return const TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.empty,
        );
      }
      _log.info(
        'YouTube Tier 1 miss for $workerVideoId/$language — '
        'falling through to direct InnerTube fetch',
      );
    }

    // Tier 2: Client-side direct YouTube fetch — download all tracks
    final fetcher = _youtubeFetcher;
    if (fetcher == null) {
      _log.warning(
        'YouTube Tier 2 unavailable: YoutubeCaptionFetcher is not wired',
      );
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
    }

    final allResult = await fetcher.fetchAllSubtitles(
      videoId: workerVideoId,
      preferredLang: language,
    );

    if (!allResult.isSuccess) {
      // All built-in InnerTube profiles failed — this is the most common
      // cause of "I see captions on Windows but the Android client shows
      // nothing" after the cache miss. Bump to WARNING so it surfaces on
      // logcat / in the rotating log file even at production log levels.
      _log.warning(
        'YouTube Tier 2 (direct InnerTube) failed for '
        '$workerVideoId/$language: ${allResult.error}',
      );
      return TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.error,
        errorMessage: allResult.error ?? 'No captions available',
      );
    }

    final now = DateTime.now();
    var storedCount = 0;
    String? primaryRowId;

    for (final trackResult in allResult.results) {
      if (!trackResult.isSuccess || trackResult.subtitles.isEmpty) continue;
      if (trackResult.language.isEmpty) continue;

      final source = _normalizeSource(trackResult.source);
      final id = enjoyTranscriptId(
        targetType: 'Video',
        targetId: mediaId,
        language: trackResult.language,
        source: source,
      );
      final timelineJson = jsonEncode(
        trackResult.subtitles.map((e) => e.toJson()).toList(),
      );

      await _db.transcriptDao.upsert(
        TranscriptRow(
          id: id,
          targetType: 'Video',
          targetId: mediaId,
          language: trackResult.language,
          source: source,
          timelineJson: timelineJson,
          referenceId: null,
          label: 'YouTube captions (${trackResult.language})',
          trackIndex: null,
          syncStatus: 'local',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      storedCount++;

      primaryRowId ??= id;

      _uploadToWorkerAfterDirectFetch(
        videoId: workerVideoId,
        language: trackResult.language,
        source: source,
        lines: trackResult.subtitles,
      );
    }

    if (storedCount == 0) {
      _log.info(
        'YouTube Tier 2 succeeded profile=${allResult.fetchProfile} '
        'but stored 0 valid tracks for $workerVideoId/$language',
      );
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.empty,
      );
    }

    _log.info(
      'YouTube Tier 2 stored $storedCount track(s) via '
      'profile=${allResult.fetchProfile} for $workerVideoId/$language; '
      'uploads dispatched to worker',
    );
    return TranscriptCloudFetchResult(
      status: TranscriptCloudFetchStatus.success,
      storedCount: storedCount,
    );
  }

  /// Tries to fetch a cached transcript from the worker's GET endpoint.
  ///
  /// Returns the transcript map on success, null on cache miss or error.
  Future<Map<String, dynamic>?> _fetchWorkerCachedTranscript({
    required String videoId,
    required String language,
  }) async {
    final client = _youtubeTranscripts;
    if (client == null) return null;
    try {
      return await client.getCachedTranscript(
        videoId: videoId,
        language: language,
      );
    } on Object catch (_) {
      return null;
    }
  }

  /// Fire-and-forget upload of a directly-fetched transcript to the worker.
  ///
  /// Note: the upload is still **never awaited** — it does not block the UI
  /// or the local-transcript write path. But the returned [Future] is
  /// observed (`.then` + `.catchError`) so that an upload failure or
  /// exception shows up in production logs. Without this hook the failure
  /// was completely invisible: [YoutubeTranscriptsApi.uploadTranscript]
  /// swallows the exception into `return false` and `unawaited(...)` discards
  /// the bool.
  void _uploadToWorkerAfterDirectFetch({
    required String videoId,
    required String language,
    required String source,
    required List<TranscriptLine> lines,
  }) {
    final client = _youtubeTranscripts;
    if (client == null) {
      _log.warning(
        'YouTube worker upload skipped for $videoId/$language '
        '(source=$source): youtube transcripts client is not wired',
      );
      return;
    }
    final timeline = lines
        .map(
          (l) => {'text': l.text, 'start': l.startMs, 'duration': l.durationMs},
        )
        .toList();
    unawaited(
      client
          .uploadTranscript(
            videoId: videoId,
            language: language,
            source: source,
            timeline: timeline,
          )
          .then((ok) {
            if (ok) {
              _log.info(
                'YouTube worker upload accepted for $videoId/$language '
                '(source=$source, ${timeline.length} lines)',
              );
            } else {
              // `YoutubeTranscriptsApi.uploadTranscript` already logged a
              // WARNING with the underlying cause; this adds the chain
              // context (which video/language/source) at INFO so the
              // operator can correlate client and worker logs.
              _log.info(
                'YouTube worker upload returned false for '
                '$videoId/$language (source=$source, '
                '${timeline.length} lines) — worker cache will not be '
                'populated; the next client will re-fetch via InnerTube',
              );
            }
          })
          .catchError((Object e, StackTrace st) {
            // The `try/on Object { return false; }` inside the API client
            // normally prevents errors from leaking out, but defensively
            // observe anything else (e.g. a logging misconfiguration) so
            // an uncaught async error never escapes to the zone.
            _log.warning(
              'YouTube worker upload threw for $videoId/$language '
              '(source=$source)',
              e,
              st,
            );
          }),
    );
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
