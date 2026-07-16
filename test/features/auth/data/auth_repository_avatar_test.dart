import 'dart:convert';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/data/api/services/direct_uploads_api.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository.updateAvatar', () {
    late SecureTokenStore tokenStore;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tokenStore = SecureTokenStore(const FlutterSecureStorage());
      await tokenStore.writeAccessToken('access-1');
    });

    test('direct-uploads then PATCHes avatar and caches profile', () async {
      final bytes = utf8.encode('fake-jpeg');
      var sawCreate = false;
      var sawPut = false;
      var sawPatch = false;

      final client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/direct_uploads') {
          sawCreate = true;
          return http.Response(
            jsonEncode({
              'signed_id': 'signed-abc',
              'direct_upload': {
                'url': 'https://storage.example/upload',
                'headers': {'Content-Type': 'image/jpeg'},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' && request.url.host == 'storage.example') {
          sawPut = true;
          expect(request.bodyBytes, bytes);
          return http.Response('', 200);
        }
        if (request.method == 'PATCH' &&
            request.url.path == '/api/v1/profile') {
          sawPatch = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['user']['avatar'], 'signed-abc');
          return http.Response(
            jsonEncode({
              'id': '24000001',
              'name': 'Ada',
              'email': 'a@b.com',
              'avatar_url': 'https://cdn.example/a.jpg',
              'mixin_id': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        fail('Unexpected ${request.method} ${request.url}');
      });

      final apiClient = ApiClient(
        httpClient: client,
        getBaseUrl: () async => 'https://enjoy.bot',
        getAccessToken: () async => 'access-1',
      );
      final repo = AuthRepository(
        authApi: AuthApi(authClient: apiClient, userClient: apiClient),
        directUploadsApi: DirectUploadsApi(apiClient),
        tokenStore: tokenStore,
        getBaseUrl: () async => 'https://enjoy.bot',
      );

      final profile = await repo.updateAvatar(
        bytes: bytes,
        filename: 'me.jpg',
        contentType: 'image/jpeg',
      );

      expect(sawCreate, isTrue);
      expect(sawPut, isTrue);
      expect(sawPatch, isTrue);
      expect(profile.avatarUrl, 'https://cdn.example/a.jpg');
      expect(profile.id, '24000001');
      final cached = await repo.readCachedProfile();
      expect(cached?.avatarUrl, 'https://cdn.example/a.jpg');
    });

    test('rejects oversize before network', () async {
      final client = MockClient((_) async {
        fail('should not call network');
      });
      final apiClient = ApiClient(
        httpClient: client,
        getBaseUrl: () async => 'https://enjoy.bot',
        getAccessToken: () async => 'access-1',
      );
      final repo = AuthRepository(
        authApi: AuthApi(authClient: apiClient, userClient: apiClient),
        directUploadsApi: DirectUploadsApi(apiClient),
        tokenStore: tokenStore,
        getBaseUrl: () async => 'https://enjoy.bot',
      );

      expect(
        () => repo.updateAvatar(
          bytes: List<int>.filled(2 * 1024 * 1024 + 1, 1),
          filename: 'big.jpg',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
