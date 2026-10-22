part of '../sync_queue_job.dart';

/// Syntactic probe for the retry payload's `kind` member (quoted key,
/// tolerant of insignificant whitespace) — see
/// [SyncQueueJob.decodeYoutubeUploadRetry].
final RegExp _kYoutubeUploadKindProbe = RegExp(
  r'"kind"\s*:\s*"youtube_upload"',
);

Future<SyncYoutubeUploadRetry?> _decodeYoutubeUploadRetry(
  String? payloadJson,
) async {
  if (payloadJson == null || !_kYoutubeUploadKindProbe.hasMatch(payloadJson)) {
    return null;
  }
  final Object? decoded;
  try {
    decoded = await decodeJsonGated(payloadJson);
  } on Object {
    return null;
  }
  final payload = castJsonObjectOrNull(decoded);
  if (payload == null || payload['kind'] != 'youtube_upload') {
    return null;
  }

  final videoId = payload['videoId'];
  final language = payload['language'];
  final source = payload['source'];
  final rawTimeline = payload['timeline'];
  List<Map<String, dynamic>>? timeline;
  if (rawTimeline is List) {
    final parsed = <Map<String, dynamic>>[];
    var tainted = false;
    for (final entry in rawTimeline) {
      final cast = castJsonObjectOrNull(entry);
      if (cast == null) {
        tainted = true;
        break;
      }
      parsed.add(cast);
    }
    timeline = tainted ? null : parsed;
  }
  if (videoId is! String ||
      videoId.isEmpty ||
      language is! String ||
      language.isEmpty ||
      source is! String ||
      source.isEmpty ||
      timeline == null ||
      timeline.isEmpty) {
    return null;
  }
  return SyncYoutubeUploadRetry(
    videoId: videoId,
    language: language,
    source: source,
    timeline: timeline,
  );
}

/// Durable YouTube worker transcript-upload retry (issue #717), absorbed
/// from the pre-seam producer in
/// `transcript_repository_youtube_worker_cache.dart`.
///
/// Rides the `video` entity as `action: update` with
/// `entityId = '$videoId/$language'` — which never matches a local video
/// row id (UUIDv5) — and `payload.kind: youtube_upload`. The payload is the
/// whole job: the drain re-uploads it via the worker transcripts API and
/// never touches a local row. The worker treats a repeated upload as
/// idempotent (409 == success), so re-running a partially-applied upload is
/// safe.
final class SyncYoutubeUploadRetry extends SyncQueueJob {
  const SyncYoutubeUploadRetry({
    required this.videoId,
    required this.language,
    required this.source,
    required this.timeline,
  });

  final String videoId;
  final String language;
  final String source;
  final List<Map<String, dynamic>> timeline;

  @override
  SyncQueueJobWire encode() => SyncQueueJobWire(
    entityType: SyncEntityType.video.wireName,
    entityId: '$videoId/$language',
    action: SyncAction.update.wireName,
    payloadJson: jsonEncode(<String, dynamic>{
      'kind': 'youtube_upload',
      'videoId': videoId,
      'language': language,
      'source': source,
      'timeline': timeline,
    }),
  );

  /// Dispatches this retry through [client]'s upload call — the single
  /// binding of the four named upload parameters, so the drain passes
  /// `job.toUploadCall(youtubeTranscripts)` instead of rebuilding the
  /// field-by-field upload on every tick.
  Future<bool> toUploadCall(YoutubeTranscriptsClient client) =>
      client.uploadTranscript(
        videoId: videoId,
        language: language,
        source: source,
        timeline: timeline,
      );

  /// Retry-handling contract for the durable worker-upload row, absorbed
  /// from `SyncEngine._processOne`'s tail (issue #749) so it lives next to
  /// the wire shape it protects:
  ///
  /// - [upload] completing `false` → throw. The drain's generic failure
  ///   path then records the attempt (`markAttempted` plus the queue's
  ///   shared `SyncRetryPolicy` backoff / threshold — this job owns no
  ///   policy of its own, issue #752).
  /// - success → **conditional remove**: the expected payload is derived
  ///   from this job's own [encode] call — the single source of truth —
  ///   and handed to `SyncQueueRepository.removeByIdIfPayload`, whose
  ///   transactional read-compare-delete keeps a producer refresh that
  ///   landed while the upload was in flight (the [encode]-stability
  ///   contract on [SyncQueueJob.encode] is what makes those bytes equal
  ///   to the row the producer wrote).
  ///
  /// The transport arrives as an already-started [upload] future (the
  /// caller builds it with [toUploadCall]), so this module still owns no
  /// transport client and no Drift code; `SyncEngine._processOne`'s
  /// exhaustive switch stays the only variant consumer and the only caller.
  Future<void> processRetry({
    required int rowId,
    required Future<bool> upload,
    required Future<void> Function(int id, String expectedPayloadJson)
    removeByIdIfPayload,
  }) async {
    final ok = await upload;
    if (!ok) {
      throw StateError(
        'youtube_upload retry for $videoId/$language returned '
        'false (worker rejected or transport failure)',
      );
    }
    final expected = encode().payloadJson;
    if (expected == null) {
      throw StateError(
        'SyncYoutubeUploadRetry.encode() must produce a payload',
      );
    }
    await removeByIdIfPayload(rowId, expected);
  }
}
