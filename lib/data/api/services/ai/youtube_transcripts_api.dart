/// Worker `POST /youtube/transcripts` (sync poll; may return `generating` with HTTP 202).
library;

import 'package:enjoy_player/data/api/rest_api.dart';

/// Contract for YouTube transcript polling on the Enjoy Worker.
abstract class YoutubeTranscriptsClient {
  Future<Map<String, dynamic>> pollTranscript({
    required String videoId,
    required String language,
    String? captionFetch,
    bool? forceRefresh,
    int? waitMs,
  });

  /// Multi-language path: the first entry of [languages] is the source language
  /// (the original caption); the remaining entries are translation targets.
  Future<Map<String, dynamic>> pollTranscripts({
    required String videoId,
    required List<String> languages,
    String? captionFetch,
    bool? forceRefresh,
    int? waitMs,
  });

  /// Looks up a cached transcript from the worker's GET endpoint.
  ///
  /// Returns the transcript map on cache hit, `null` on 404 (cache miss).
  Future<Map<String, dynamic>?> getCachedTranscript({
    required String videoId,
    required String language,
  });

  /// Uploads a client-fetched transcript to the worker for caching.
  ///
  /// Returns `true` on successful upload (201 or 409 idempotent).
  /// Failures are thrown or return `false`.
  Future<bool> uploadTranscript({
    required String videoId,
    required String language,
    required String source,
    required List<Map<String, dynamic>> timeline,
    Map<String, dynamic>? metadata,
  });

  /// Fetches the current set of YouTube InnerTube client profiles.
  ///
  /// Returns the profile list from `GET /youtube/client-profiles`.
  Future<List<Map<String, dynamic>>> fetchClientProfiles();
}

class YoutubeTranscriptsApi extends RestApi
    implements YoutubeTranscriptsClient {
  YoutubeTranscriptsApi(super.client);

  static const _transcriptsPath = '/youtube/transcripts';
  static const _profilesPath = '/youtube/client-profiles';

  @override
  Future<Map<String, dynamic>> pollTranscript({
    required String videoId,
    required String language,
    String? captionFetch,
    bool? forceRefresh,
    int? waitMs,
  }) {
    return client.postJson(
      _transcriptsPath,
      body: {
        'videoId': videoId,
        'language': language,
        'captionFetch': ?captionFetch,
        'forceRefresh': ?forceRefresh,
        'waitMs': ?waitMs,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> pollTranscripts({
    required String videoId,
    required List<String> languages,
    String? captionFetch,
    bool? forceRefresh,
    int? waitMs,
  }) {
    return client.postJson(
      _transcriptsPath,
      body: {
        'videoId': videoId,
        'languages': languages,
        'captionFetch': ?captionFetch,
        'forceRefresh': ?forceRefresh,
        'waitMs': ?waitMs,
      },
    );
  }

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
      await client.postJson(
        _transcriptsPath,
        body: {
          'videoId': videoId,
          'language': language,
          'source': source,
          'timeline': timeline,
          'metadata': ?metadata,
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
      return await client.getJsonList(_profilesPath);
    } on Object {
      return <Map<String, dynamic>>[];
    }
  }
}
