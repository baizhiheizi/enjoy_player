/// Typed HTTP client: bearer auth, JSON, camelCase ↔ snake_case.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/case_conversion.dart';
import 'package:enjoy_player/data/api/json_isolate.dart';

final Logger _log = logNamed('api');

/// Request/response lines at [Level.INFO] so they appear when
/// [Logger.root.level] is [Level.INFO] (profile/release), not only [Level.ALL].
void _apiHttpTrace(String message) {
  _log.info(message);
}

typedef GetBaseUrl = Future<String> Function();
typedef GetAccessToken = Future<String?> Function();

class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required this.getBaseUrl,
    required this.getAccessToken,
    this.sendAuthHeader = true,
  }) : _client = httpClient;

  final http.Client _client;
  final GetBaseUrl getBaseUrl;
  final GetAccessToken getAccessToken;
  final bool sendAuthHeader;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) =>
      _sendMap(
        method: 'GET',
        path: path,
        queryParameters: queryParameters,
        body: null,
        requireAuth: requireAuth,
      );

  /// For endpoints that return a JSON array (e.g. Rails `render json: @items`).
  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) =>
      _sendList(
        method: 'GET',
        path: path,
        queryParameters: queryParameters,
        body: null,
        requireAuth: requireAuth,
      );

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) =>
      _sendMap(
        method: 'POST',
        path: path,
        queryParameters: null,
        body: body,
        requireAuth: requireAuth,
      );

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool transformBody = true,
  }) =>
      _sendMap(
        method: 'PATCH',
        path: path,
        queryParameters: null,
        body: body,
        requireAuth: requireAuth,
        transformBody: transformBody,
      );

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool transformBody = true,
  }) =>
      _sendMap(
        method: 'PUT',
        path: path,
        queryParameters: null,
        body: body,
        requireAuth: requireAuth,
        transformBody: transformBody,
      );

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool requireAuth = true,
  }) =>
      _sendMap(
        method: 'DELETE',
        path: path,
        queryParameters: null,
        body: null,
        requireAuth: requireAuth,
        allowEmptyBody: true,
      );

  /// Multipart POST (e.g. Whisper) returning a JSON object with camelCase keys.
  Future<Map<String, dynamic>> postMultipartJson(
    String path, {
    required String fileFieldName,
    required List<int> fileBytes,
    String? fileFilename,
    Map<String, String> fields = const {},
    bool requireAuth = true,
  }) async {
    final base = _trimTrailingSlash(await getBaseUrl());
    final uriBase = Uri.parse(base);
    final pathUri = Uri.parse(path);
    final merged = uriBase.resolveUri(pathUri);

    String? bearer;
    if (sendAuthHeader && requireAuth) {
      final token = await getAccessToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      bearer = token;
    }

    final request = http.MultipartRequest('POST', merged);
    request.headers['Accept'] = 'application/json';
    if (bearer != null) {
      request.headers['Authorization'] = 'Bearer $bearer';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileFilename,
      ),
    );
    for (final e in fields.entries) {
      request.fields[e.key] = e.value;
    }

    final sw = Stopwatch()..start();
    _apiHttpTrace('HTTP → POST $merged (multipart)');
    try {
      final streamed = await _client.send(request);
      final bodyBytes = await streamed.stream.toBytes();
      sw.stop();
      final response = http.Response.bytes(
        bodyBytes,
        streamed.statusCode,
        headers: streamed.headers,
        request: request,
      );
      _apiHttpTrace(
        'HTTP ← POST $merged ${response.statusCode} '
        '${sw.elapsedMilliseconds}ms len=${bodyBytes.length}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = await _decodeResponseBody(response);
        if (decoded is! Map) {
          throw ApiException(
            message: 'Expected JSON object',
            statusCode: response.statusCode,
            body: decoded,
          );
        }
        return Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      await _throwApiError(response);
      throw AssertionError('unreachable');
    } catch (e, st) {
      sw.stop();
      _log.warning(
        'HTTP ✗ POST $merged (multipart) after ${sw.elapsedMilliseconds}ms: $e',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<Object?> _decodeResponseBody(http.Response response) async {
    final raw = response.body;
    if (raw.isEmpty) return null;
    if (raw.length > 48 * 1024 && !kIsWeb) {
      return compute(decodeJsonToCamel, raw);
    }
    return decodeJsonToCamel(raw);
  }

  Future<Map<String, dynamic>> _sendMap({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    required bool requireAuth,
    bool allowEmptyBody = false,
    bool transformBody = true,
  }) async {
    final response = await _dispatch(
      method: method,
      path: path,
      queryParameters: queryParameters,
      body: body,
      requireAuth: requireAuth,
      transformBody: transformBody,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty && allowEmptyBody) {
        return const <String, dynamic>{};
      }
      final decoded = await _decodeResponseBody(response);
      if (decoded is! Map) {
        throw ApiException(
          message: 'Expected JSON object',
          statusCode: response.statusCode,
          body: decoded,
        );
      }
      return Map<String, dynamic>.from(
        decoded.map((k, v) => MapEntry(k.toString(), v)),
      );
    }

    await _throwApiError(response);
    throw AssertionError('unreachable');
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
      transformBody: true,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = await _decodeResponseBody(response);
      if (decoded is! List) {
        throw ApiException(
          message: 'Expected JSON array',
          statusCode: response.statusCode,
          body: decoded,
        );
      }
      return decoded.map<Map<String, dynamic>>((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) {
          return Map<String, dynamic>.from(
            e.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
        throw ApiException(
          message: 'Array element is not an object',
          statusCode: response.statusCode,
          body: e,
        );
      }).toList();
    }

    await _throwApiError(response);
    throw AssertionError('unreachable');
  }

  Future<http.Response> _dispatch({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    required bool requireAuth,
    bool transformBody = true,
  }) async {
    final base = _trimTrailingSlash(await getBaseUrl());
    final uriBase = Uri.parse(base);
    final pathUri = Uri.parse(path);
    final merged = uriBase.resolveUri(pathUri);
    final uri = queryParameters == null || queryParameters.isEmpty
        ? merged
        : merged.replace(
            queryParameters: _snakeCaseQuery(queryParameters),
          );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=UTF-8',
    };

    if (sendAuthHeader && requireAuth) {
      final token = await getAccessToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Not authenticated',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final bodyBytes = body == null
        ? null
        : utf8.encode(
            jsonEncode(transformBody ? convertKeysToSnake(body) : body),
          );

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
          response =
              await _client.patch(uri, headers: headers, body: bodyBytes);
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

  Future<void> _throwApiError(http.Response response) async {
    Object? errBody;
    try {
      errBody = response.body.isEmpty
          ? null
          : (response.body.length > 32 * 1024 && !kIsWeb
                ? await compute(decodeJsonToCamel, response.body)
                : decodeJsonToCamel(response.body));
    } catch (_) {
      errBody = response.body;
    }

    throw ApiException(
      message: 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
      body: errBody,
    );
  }

  Map<String, String> _snakeCaseQuery(Map<String, String> query) {
    final out = <String, String>{};
    query.forEach((k, v) {
      out[_camelQueryKeyToSnake(k)] = v;
    });
    return out;
  }

  static String _camelQueryKeyToSnake(String key) {
    final b = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final c = key[i];
      final code = c.codeUnitAt(0);
      final isUpper = code >= 65 && code <= 90;
      if (isUpper && i > 0) {
        b.write('_');
      }
      b.write(c.toLowerCase());
    }
    return b.toString();
  }

  static String _trimTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
