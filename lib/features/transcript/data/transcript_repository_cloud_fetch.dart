part of 'transcript_repository.dart';

/// Enjoy API transcript fetching for [TranscriptRepository]: skip-once-fetched
/// gating, server JSON → row mapping, batch upsert, and error / success
/// reporting. The YouTube fallback chain lives in
/// `_TranscriptRepositoryYoutubeFetch`.
extension _TranscriptRepositoryCloudFetch on TranscriptRepository {
  /// Single owner of the skip-once-fetched predicate (issue #718): the
  /// `lastStatus != 'error'` rule on the persisted [TranscriptFetchStateRow]
  /// for this target. `false` covers both "no row yet" and "last fetch
  /// errored" — both let the next open retry.
  Future<bool> _isCloudFetchSkippable(String mediaId) async {
    final state = await _readCloudFetchState(mediaId);
    return state != null && state.lastStatus != 'error';
  }

  /// Reads the persisted fetch-state row, resolving the target type once.
  /// The controller uses this for UI hydration; the predicate above uses it
  /// for the skip gate.
  Future<TranscriptFetchStateRow?> _readCloudFetchState(String mediaId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    return _db.transcriptFetchStateDao.getForTarget(tt, mediaId);
  }

  Future<TranscriptCloudFetchResult> _fetchCloudTranscripts(
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

    if (!force && await _isCloudFetchSkippable(mediaId)) {
      return const TranscriptCloudFetchResult(
        status: TranscriptCloudFetchStatus.skipped,
      );
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
      final rowsToUpsert = <TranscriptRow>[];
      for (final item in list) {
        final row = _transcriptRowFromServerMap(item, fallbackNow: now);
        if (row != null) rowsToUpsert.add(row);
      }
      if (rowsToUpsert.isNotEmpty) {
        await _db.batch(
          (b) => b.insertAll(
            _db.transcripts,
            rowsToUpsert,
            mode: InsertMode.insertOrReplace,
          ),
        );
      }
      final storedCount = rowsToUpsert.length;

      if (list.isNotEmpty && storedCount == 0) {
        return const TranscriptCloudFetchResult(
          status: TranscriptCloudFetchStatus.error,
          errorMessage: 'Could not store cloud transcripts',
        );
      }

      if (storedCount > 0) {
        await _ensurePrimaryTranscript(mediaId, targetType: tt);
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
}
