part of 'transcript_repository.dart';

/// YouTube worker-cache plumbing for [TranscriptRepository]: reading the
/// worker GET cache, storing cached responses locally, and uploading
/// directly-fetched transcripts back to the worker (with durable retry).
extension _TranscriptRepositoryYoutubeWorkerCache on TranscriptRepository {
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
  ///
  /// On failure the payload is durably enqueued via `sync_queue` (entity
  /// `video`, action `update`, payload `kind: youtube_upload`) so the next
  /// [SyncCtrl] periodic drain reattempts the upload. This is the fix for
  /// the Windows-fetches-but-Android-can't-serve-from-cache mode where the
  /// one-shot upload was lost on a transient worker failure.
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
          .then((ok) async {
            if (ok) {
              _log.info(
                'YouTube worker upload accepted for $videoId/$language '
                '(source=$source, ${timeline.length} lines)',
              );
              return;
            }
            _log.info(
              'YouTube worker upload returned false for '
              '$videoId/$language (source=$source, '
              '${timeline.length} lines) — enqueueing durable retry',
            );
            await _enqueueYoutubeUploadRetry(
              videoId: videoId,
              language: language,
              source: source,
              timeline: timeline,
            );
          })
          .catchError((Object e, StackTrace st) async {
            _log.warning(
              'YouTube worker upload threw for $videoId/$language '
              '(source=$source) — enqueueing durable retry',
              e,
              st,
            );
            await _enqueueYoutubeUploadRetry(
              videoId: videoId,
              language: language,
              source: source,
              timeline: timeline,
            );
          }),
    );
  }

  Future<void> _enqueueYoutubeUploadRetry({
    required String videoId,
    required String language,
    required String source,
    required List<Map<String, dynamic>> timeline,
  }) async {
    try {
      final payload = jsonEncode({
        'kind': 'youtube_upload',
        'videoId': videoId,
        'language': language,
        'source': source,
        'timeline': timeline,
      });
      await _db.syncQueueDao.enqueue(
        entityType: 'video',
        entityId: '$videoId/$language',
        action: 'update',
        payloadJson: payload,
      );
    } on Object catch (e, st) {
      _log.warning(
        'failed to enqueue YouTube worker upload retry for '
        '$videoId/$language',
        e,
        st,
      );
    }
  }
}
