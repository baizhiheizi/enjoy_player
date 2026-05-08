/// REST client for `/api/v1/sessions/*` and `/api/v1/profile`.
library;

import 'package:enjoy_player/data/api/api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> startAuth() => _client.postJson(
        '/api/v1/sessions/start_auth',
        requireAuth: false,
      );

  Future<Map<String, dynamic>> pollAuth(String requestId) => _client.getJson(
        '/api/v1/sessions/poll',
        queryParameters: {'requestId': requestId},
        requireAuth: false,
      );

  Future<Map<String, dynamic>> profile() => _client.getJson('/api/v1/profile');

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> user) =>
      _client.patchJson(
        '/api/v1/profile',
        body: {'user': user},
      );
}
