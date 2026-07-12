/// Worker cache & profile API for YouTube transcripts
/// (see `specs/013-client-yt-transcripts/contracts/worker-cache-api.md`).
library;

import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

/// Worker-side caption-fetch strategy. Mirrors
/// `apps/worker/src/routes/youtube/_validation.ts` (`caption_fetch`).
enum WorkerCaptionFetch { auto, official }

WorkerCaptionFetch _captionFetchForSource(String source) {
  return source == 'official'
      ? WorkerCaptionFetch.official
      : WorkerCaptionFetch.auto;
}

/// Contract for the Enjoy Worker transcript cache & profile endpoints
/// (cache-only; the legacy poll-based POST `/youtube/transcripts` was removed
/// upstream — see issue #320).
abstract class YoutubeTranscriptsClient {
  /// Looks up a cached transcript from the worker's GET endpoint.
  ///
  /// Returns the transcript map on cache hit, `null` on 404 (cache miss).
  Future<Map<String, dynamic>?> getCachedTranscript({
    required String videoId,
    required String language,
  });

  /// Uploads a client-fetched transcript to the worker for caching.
  ///
  /// Sends the full wire body the worker validates as required
  /// (`format`, `caption_fetch`, `generated_at`, plus `video_id`, `language`,
  /// `source`, `timeline`, optional `metadata`). Returns `true` on success
  /// (201 or 409 idempotent). Any failure (validation, transport, ...) is
  /// swallowed and surfaced as `false` — call sites treat this as
  /// fire-and-forget.
  Future<bool> uploadTranscript({
    required String videoId,
    required String language,
    required String source,
    required List<Map<String, dynamic>> timeline,
    Map<String, dynamic>? metadata,
  });

  /// Fetches the current set of YouTube InnerTube client profiles.
  ///
  /// `GET /youtube/client-profiles` returns a `{"version", "profiles"}`
  /// envelope; this extracts and returns the `profiles` list.
  Future<List<Map<String, dynamic>>> fetchClientProfiles();
}

class YoutubeTranscriptsApi extends RestApi
    implements YoutubeTranscriptsClient {
  YoutubeTranscriptsApi(super.client);

  static const _transcriptsPath = '/youtube/transcripts';
  static const _profilesPath = '/youtube/client-profiles';

  @override
  Future<Map<String, dynamic>?> getCachedTranscript({
    required String videoId,
    required String language,
  }) async {
    try {
      return await client.getJson(
        _transcriptsPath,
        queryParameters: {'videoId': videoId, 'language': language},
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> uploadTranscript({
    required String videoId,
    required String language,
    required String source,
    required List<Map<String, dynamic>> timeline,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final captionFetch = _captionFetchForSource(source);
      await client.postJson(
        _transcriptsPath,
        body: {
          'format': 'enjoy',
          'videoId': videoId,
          'language': language,
          'captionFetch': captionFetch == WorkerCaptionFetch.official
              ? 'official'
              : 'auto',
          'source': source,
          'timeline': timeline,
          'metadata': ?metadata,
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchClientProfiles() async {
    try {
      final response = await client.getJson(_profilesPath);
      final list = response['profiles'];
      if (list is List) {
        return list
            .map(castJsonObjectOrNull)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
      return <Map<String, dynamic>>[];
    } on Object {
      return <Map<String, dynamic>>[];
    }
  }
}
