part of 'api_client.dart';

const int _kIsolateJsonEncodeByteEstimateThreshold = 16 * 1024;

List<int> _encodeSnakeJsonBody(Object? body) =>
    utf8.encode(jsonEncode(convertKeysToSnake(body)));

bool _shouldEncodeJsonInIsolate(Object? body) {
  if (body is String) {
    return body.length > _kIsolateJsonEncodeByteEstimateThreshold;
  }
  if (body is List) return body.length >= 32;
  if (body is Map) {
    if (body.length >= 24) return true;
    for (final v in body.values) {
      if (v is List && v.length >= 32) return true;
      if (v is String && v.length > _kIsolateJsonEncodeByteEstimateThreshold) {
        return true;
      }
      if (v is Map && v.length >= 24) return true;
    }
  }
  return false;
}

String _trimTrailingSlash(String url) {
  if (url.endsWith('/')) {
    return url.substring(0, url.length - 1);
  }
  return url;
}

mixin _ApiClientDispatch on _ApiClientDecoding {
  http.Client get _client;
  GetBaseUrl get getBaseUrl;
  GetAccessToken get getAccessToken;
  RefreshAccessToken? get refreshAccessToken;

  /// Resolves a relative API [path] against the configured base URL.
  Future<Uri> _resolveApiUrl(String path) async {
    final base = _trimTrailingSlash(await getBaseUrl());
    final uriBase = Uri.parse(base);
    final pathUri = Uri.parse(path);
    return uriBase.resolveUri(pathUri);
  }

  /// Returns a bearer token to attach to the outgoing request, or `null`
  /// when auth is disabled / not required for this call.
  ///
  /// When the cached token is missing or empty, attempts a single
  /// [refreshAccessToken] and re-reads the token. If no usable token is
  /// available after that, throws [ApiException] with status 401 — matching
  /// the auth posture callers relied on before the three call sites were
  /// deduplicated.
  Future<String?> _ensureAuthenticated(bool requireAuth) async {
    if (!requireAuth) return null;

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) return token;

    if (refreshAccessToken != null) {
      final ok = await refreshAccessToken!();
      if (ok) {
        final newToken = await getAccessToken();
        if (newToken != null && newToken.isNotEmpty) return newToken;
      }
    }

    throw const ApiException(message: 'Not authenticated', statusCode: 401);
  }

  Future<Map<String, dynamic>> _sendMapWithOptionalRefresh({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    required bool requireAuth,
    bool allowEmptyBody = false,
    bool allowRefreshRetry = true,
  }) async {
    final response = await _dispatch(
      method: method,
      path: path,
      queryParameters: queryParameters,
      body: body,
      requireAuth: requireAuth,
    );

    if (response.statusCode == 401 &&
        requireAuth &&
        allowRefreshRetry &&
        refreshAccessToken != null) {
      final refreshed = await refreshAccessToken!();
      if (refreshed) {
        return _sendMapWithOptionalRefresh(
          method: method,
          path: path,
          queryParameters: queryParameters,
          body: body,
          requireAuth: requireAuth,
          allowEmptyBody: allowEmptyBody,
          allowRefreshRetry: false,
        );
      }
    }

    return _decodeMapResponse(response, allowEmptyBody: allowEmptyBody);
  }

  Future<List<Map<String, dynamic>>> _sendList({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    required bool requireAuth,
  }) async {
    final response = await _dispatch(
      method: method,
      path: path,
      queryParameters: queryParameters,
      body: body,
      requireAuth: requireAuth,
    );

    return _decodeListResponse(response);
  }

  Future<http.Response> _dispatch({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    required bool requireAuth,
  }) async {
    final merged = await _resolveApiUrl(path);
    final uri = queryParameters == null || queryParameters.isEmpty
        ? merged
        : merged.replace(queryParameters: _snakeCaseQuery(queryParameters));

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=UTF-8',
    };

    final bearer = await _ensureAuthenticated(requireAuth);
    if (bearer != null) {
      headers['Authorization'] = 'Bearer $bearer';
    }

    final bodyBytes = body == null
        ? null
        : (_shouldEncodeJsonInIsolate(body)
              ? await Isolate.run(() => _encodeSnakeJsonBody(body))
              : _encodeSnakeJsonBody(body));

    final sw = Stopwatch()..start();
    _apiHttpTrace('HTTP → $method $uri');

    try {
      final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
        case 'POST':
          response = await _client.post(uri, headers: headers, body: bodyBytes);
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: bodyBytes,
          );
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: bodyBytes);
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
        default:
          throw ApiException(message: 'Unsupported method $method');
      }
      sw.stop();
      _apiHttpTrace(
        'HTTP ← $method $uri ${response.statusCode} '
        '${sw.elapsedMilliseconds}ms len=${response.bodyBytes.length}',
      );
      return response;
    } catch (e, st) {
      sw.stop();
      _log.warning(
        'HTTP ✗ $method $uri after ${sw.elapsedMilliseconds}ms: $e',
        e,
        st,
      );
      rethrow;
    }
  }

  Map<String, String> _snakeCaseQuery(Map<String, String> query) {
    final out = <String, String>{};
    query.forEach((k, v) {
      out[camelToSnakeToken(k)] = v;
    });
    return out;
  }
}
