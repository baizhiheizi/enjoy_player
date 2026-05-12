/// Short-lived Azure Speech token cache (Enjoy worker `POST /azure/tokens`).
library;

import 'package:enjoy_player/data/api/services/ai/azure_token_api.dart';
import 'package:meta/meta.dart';

/// In-memory cache (~9 minutes) mirroring web `@enjoy/ai` token manager.
final class AzureTokenCache {
  AzureTokenCache({
    AzureTokenApi? api,
    @visibleForTesting Future<Map<String, dynamic>> Function()? debugOverrideFetch,
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
    if (token == null ||
        token.isEmpty ||
        region == null ||
        region.isEmpty) {
      throw StateError(
        'Azure token response missing token/region: ${json.keys.join(", ")}',
      );
    }

    _cached = (token: token, region: region);
    _fetchedAt = now;
    return _cached!;
  }

  void clear() {
    _cached = null;
    _fetchedAt = null;
  }
}
