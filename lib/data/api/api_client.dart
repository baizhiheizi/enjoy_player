/// Typed HTTP client: bearer auth, JSON, camelCase ↔ snake_case.
library;

import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io' show File;
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/json/gated_json_decode.dart';
import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/validation/trim_trailing_slashes.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/case_conversion.dart';
import 'package:enjoy_player/data/api/json_isolate.dart';

part 'api_client_decoding.dart';
part 'api_client_dispatch.dart';
part 'api_client_uploads.dart';

final Logger _log = logNamed('api');

/// Request/response lines at [Level.INFO] so they appear when
/// [Logger.root.level] is [Level.INFO] (profile/release), not only [Level.ALL].
void _apiHttpTrace(String message) {
  _log.info(message);
}

typedef GetBaseUrl = Future<String> Function();
typedef GetAccessToken = Future<String?> Function();
typedef RefreshAccessToken = Future<bool> Function();

/// Shared alias for decoded JSON objects; import from here instead of
/// redeclaring per service file.
typedef JsonMap = Map<String, dynamic>;

class ApiClient with _ApiClientDecoding, _ApiClientDispatch, _ApiClientUploads {
  ApiClient({
    required http.Client httpClient,
    required this.getBaseUrl,
    required this.getAccessToken,
    this.refreshAccessToken,
  }) : _client = httpClient;

  @override
  final http.Client _client;
  @override
  final GetBaseUrl getBaseUrl;
  @override
  final GetAccessToken getAccessToken;
  @override
  final RefreshAccessToken? refreshAccessToken;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) => _sendMapWithOptionalRefresh(
    method: 'GET',
    path: path,
    queryParameters: queryParameters,
    requireAuth: requireAuth,
  );

  /// For endpoints that return a JSON array (e.g. Rails `render json: @items`).
  Future<List<Map<String, dynamic>>> getJsonList(
    String path, {
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) => _sendList(
    method: 'GET',
    path: path,
    queryParameters: queryParameters,
    requireAuth: requireAuth,
  );

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool allowEmptyBody = false,
  }) => _sendMapWithOptionalRefresh(
    method: 'POST',
    path: path,
    body: body,
    requireAuth: requireAuth,
    allowEmptyBody: allowEmptyBody,
  );

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) => _sendMapWithOptionalRefresh(
    method: 'PATCH',
    path: path,
    body: body,
    requireAuth: requireAuth,
  );

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) => _sendMapWithOptionalRefresh(
    method: 'PUT',
    path: path,
    body: body,
    requireAuth: requireAuth,
  );

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool requireAuth = true,
  }) => _sendMapWithOptionalRefresh(
    method: 'DELETE',
    path: path,
    requireAuth: requireAuth,
    allowEmptyBody: true,
  );
}
