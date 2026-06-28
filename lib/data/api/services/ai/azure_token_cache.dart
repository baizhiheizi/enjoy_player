/// Short-lived Azure Speech token cache (Enjoy worker `POST /azure/tokens`).
library;

import 'dart:async';

import 'package:enjoy_player/data/api/services/ai/azure_token_api.dart';
import 'package:meta/meta.dart';

/// In-memory cache (~9 minutes) mirroring web `@enjoy/ai` token manager.
final class AzureTokenCache {
  AzureTokenCache({
    AzureTokenApi? api,
    @visibleForTesting
    Future<Map<String, dynamic>> Function()? debugOverrideFetch,
  }) : assert(
         api != null || debugOverrideFetch != null,
         'Provide api or debugOverrideFetch',
       ),
       _api = api,
       _debugOverrideFetch = debugOverrideFetch;

  final AzureTokenApi? _api;
  final Future<Map<String, dynamic>> Function()? _debugOverrideFetch;

  static const Duration _ttl = Duration(minutes: 9);

  ({String token, String region})? _cached;
  DateTime? _fetchedAt;

  /// In-flight fetch shared by concurrent callers. Without this, two
  /// `getToken` calls that both miss the cache (e.g. on a cold start
  /// or right after `clear()`) would each hit the worker, doubling
  /// the call budget. The completer is cleared once the fetch settles.
  Future<({String token, String region})>? _inFlight;

  /// [durationSeconds] is forwarded for worker-side cost estimation (assessment).
  Future<({String token, String region})> getToken({
    required int durationSeconds,
  }) async {
    final now = DateTime.now();
    final at = _fetchedAt;
    final c = _cached;
    if (c != null && at != null && now.difference(at) < _ttl) {
      return c;
    }

    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }

    Future<({String token, String region})> fetch() async {
      final json = _debugOverrideFetch != null
          ? await _debugOverrideFetch()
          : await _api!.generateToken(
              usage: <String, dynamic>{
                'purpose': 'assessment',
                'assessment': <String, dynamic>{
                  'durationSeconds': durationSeconds,
                },
              },
            );

      final token = json['token'] as String?;
      final region = json['region'] as String?;
      if (token == null || token.isEmpty || region == null || region.isEmpty) {
        throw StateError(
          'Azure token response missing token/region: ${json.keys.join(", ")}',
        );
      }

      final value = (token: token, region: region);
      _cached = value;
      _fetchedAt = DateTime.now();
      return value;
    }

    final pending = fetch();
    _inFlight = pending;
    try {
      return await pending;
    } finally {
      _inFlight = null;
    }
  }

  void clear() {
    _cached = null;
    _fetchedAt = null;
  }
}
