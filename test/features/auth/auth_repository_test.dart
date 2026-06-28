import 'dart:io';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository.refreshSession', () {
    late Directory tempDir;
    late FlutterSecureStorage storage;
    late SecureTokenStore tokenStore;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('auth_repo_test_');
      FlutterSecureStorage.setMockInitialValues({});
      storage = const FlutterSecureStorage();
      tokenStore = SecureTokenStore(storage);
      await tokenStore.writeAccessToken('access-1');
      await tokenStore.writeRefreshToken('refresh-1');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    AuthRepository build(http.Client client) {
      final api = AuthApi(
        ApiClient(
          httpClient: client,
          getBaseUrl: () async => 'https://enjoy.bot',
          getAccessToken: () async => null,
        ),
      );
      return AuthRepository(
        authApi: api,
        tokenStore: tokenStore,
        getBaseUrl: () async => 'https://enjoy.bot',
      );
    }

    test('returns true and persists new tokens on success', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        return http.Response(
          '{"accessToken":"a2","refreshToken":"r2","expiresIn":3600}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = build(client);

      final ok = await repo.refreshSession();

      expect(ok, isTrue);
      expect(await tokenStore.readAccessToken(), 'a2');
      expect(await tokenStore.readRefreshToken(), 'r2');
    });

    test(
      'returns false but keeps session on transient network error',
      () async {
        final client = MockClient((_) async {
          throw const SocketException('Connection reset by peer');
        });
        final repo = build(client);

        final ok = await repo.refreshSession();

        expect(ok, isFalse);
        expect(await tokenStore.readAccessToken(), 'access-1');
        expect(await tokenStore.readRefreshToken(), 'refresh-1');
      },
    );

    test('returns false and keeps session on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final repo = build(client);

      final ok = await repo.refreshSession();

      expect(ok, isFalse);
      expect(await tokenStore.readAccessToken(), 'access-1');
      expect(await tokenStore.readRefreshToken(), 'refresh-1');
    });

    test('returns false and keeps session on HTTP 429', () async {
      final client = MockClient((_) async => http.Response('slow down', 429));
      final repo = build(client);

      final ok = await repo.refreshSession();

      expect(ok, isFalse);
      expect(await tokenStore.readAccessToken(), 'access-1');
      expect(await tokenStore.readRefreshToken(), 'refresh-1');
    });

    test('returns false and clears session on HTTP 401', () async {
      final client = MockClient((_) async => http.Response('expired', 401));
      final repo = build(client);

      final ok = await repo.refreshSession();

      expect(ok, isFalse);
      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });

    test('returns false and clears session on HTTP 403', () async {
      final client = MockClient((_) async => http.Response('forbidden', 403));
      final repo = build(client);

      final ok = await repo.refreshSession();

      expect(ok, isFalse);
      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });

    test(
      'returns false and keeps session on HTTP 400 (malformed request, not auth revocation)',
      () async {
        final client = MockClient((_) async => http.Response('bad', 400));
        final repo = build(client);

        final ok = await repo.refreshSession();

        expect(ok, isFalse);
        expect(await tokenStore.readAccessToken(), 'access-1');
        expect(await tokenStore.readRefreshToken(), 'refresh-1');
      },
    );

    test('returns false when no refresh token is stored', () async {
      await tokenStore.clearAllAuthSecrets();
      final client = MockClient((_) async => http.Response('{}', 200));
      final repo = build(client);

      final ok = await repo.refreshSession();

      expect(ok, isFalse);
    });
  });

  group('AuthFailure', () {
    test('default code is unknown', () {
      const f = AuthFailure('oops');
      expect(f.code, AuthFailureCode.unknown);
      expect(f.isSessionRevoked, isFalse);
    });

    test('sessionRevoked marker is exposed', () {
      const f = AuthFailure('revoked', code: AuthFailureCode.sessionRevoked);
      expect(f.isSessionRevoked, isTrue);
    });
  });

  group('ApiException mapping in auth flows', () {
    test('ApiException 401 maps to AuthFailure.sessionRevoked', () {
      const e = ApiException(message: 'unauthorized', statusCode: 401);
      expect(authFailureCodeForApiException(e), AuthFailureCode.sessionRevoked);
    });

    test('ApiException 403 maps to AuthFailure.sessionRevoked', () {
      const e = ApiException(message: 'forbidden', statusCode: 403);
      expect(authFailureCodeForApiException(e), AuthFailureCode.sessionRevoked);
    });

    test('ApiException 429 maps to AuthFailure.rateLimited', () {
      const e = ApiException(message: 'slow down', statusCode: 429);
      expect(authFailureCodeForApiException(e), AuthFailureCode.rateLimited);
    });

    test('ApiException 500+ maps to AuthFailure.serverError', () {
      const e5 = ApiException(message: 'oops', statusCode: 500);
      const e503 = ApiException(message: 'unavailable', statusCode: 503);
      expect(authFailureCodeForApiException(e5), AuthFailureCode.serverError);
      expect(authFailureCodeForApiException(e503), AuthFailureCode.serverError);
    });

    test('ApiException 400/404/422 maps to AuthFailure.invalidCredentials', () {
      const e400 = ApiException(message: 'bad', statusCode: 400);
      const e404 = ApiException(message: 'missing', statusCode: 404);
      const e422 = ApiException(message: 'unprocessable', statusCode: 422);
      expect(
        authFailureCodeForApiException(e400),
        AuthFailureCode.invalidCredentials,
      );
      expect(
        authFailureCodeForApiException(e404),
        AuthFailureCode.invalidCredentials,
      );
      expect(
        authFailureCodeForApiException(e422),
        AuthFailureCode.invalidCredentials,
      );
    });

    test('ApiException with no status code maps to AuthFailure.unknown', () {
      const e = ApiException(message: 'no status');
      expect(authFailureCodeForApiException(e), AuthFailureCode.unknown);
    });
  });
}
