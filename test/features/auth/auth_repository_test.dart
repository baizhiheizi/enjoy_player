import 'dart:io';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/data/api/services/direct_uploads_api.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
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
      final sharedClient = ApiClient(
        httpClient: client,
        getBaseUrl: () async => 'https://enjoy.bot',
        getAccessToken: () async => null,
      );
      final api = AuthApi(authClient: sharedClient, userClient: sharedClient);
      return AuthRepository(
        authApi: api,
        directUploadsApi: DirectUploadsApi(sharedClient),
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

    test(
      'concurrent refreshSession calls share a single in-flight refresh '
      '(single-flight) — backend only sees one POST /api/v1/auth/refresh',
      () async {
        var refreshCalls = 0;
        final client = MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            refreshCalls++;
          }
          // Slight delay so concurrent callers race into the same completer
          // before the first call's response is processed.
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            '{"accessToken":"a2","refreshToken":"r2","expiresIn":3600}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final repo = build(client);

        final results = await Future.wait([
          repo.refreshSession(),
          repo.refreshSession(),
          repo.refreshSession(),
        ]);

        expect(results, [true, true, true]);
        // Without single-flight, the backend would have rotated the refresh
        // token on the first request and rejected the next two with 401,
        // which `clearSession()` would then treat as a hard auth failure and
        // sign the user out — see auth_repository.dart single-flight note.
        expect(refreshCalls, 1);
        expect(await tokenStore.readAccessToken(), 'a2');
        expect(await tokenStore.readRefreshToken(), 'r2');
      },
    );

    test(
      'concurrent refreshSession calls share the failure result and do not '
      'double-clear the session when the backend rejects the refresh token',
      () async {
        var refreshCalls = 0;
        final client = MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            refreshCalls++;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('rotated', 401);
        });
        final repo = build(client);

        final results = await Future.wait([
          repo.refreshSession(),
          repo.refreshSession(),
          repo.refreshSession(),
        ]);

        expect(results, [false, false, false]);
        expect(refreshCalls, 1);
        expect(await tokenStore.readAccessToken(), isNull);
        expect(await tokenStore.readRefreshToken(), isNull);
      },
    );
  });

  group('AuthRepository.loadInitialAuthState', () {
    late SecureTokenStore tokenStore;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tokenStore = SecureTokenStore(const FlutterSecureStorage());
    });

    AuthRepository buildRepo(http.Client client) {
      final sharedClient = ApiClient(
        httpClient: client,
        getBaseUrl: () async => 'https://enjoy.bot',
        getAccessToken: tokenStore.readAccessToken,
      );
      final api = AuthApi(authClient: sharedClient, userClient: sharedClient);
      return AuthRepository(
        authApi: api,
        directUploadsApi: DirectUploadsApi(sharedClient),
        tokenStore: tokenStore,
        getBaseUrl: () async => 'https://enjoy.bot',
      );
    }

    test('returns signed out when no access token is stored', () async {
      final repo = buildRepo(MockClient((_) async => http.Response('{}', 200)));

      final state = await repo.loadInitialAuthState();

      expect(state, isA<AuthSignedOut>());
    });

    test(
      'returns signed out on transient network error without clearing tokens',
      () async {
        await tokenStore.writeAccessToken('access-1');
        await tokenStore.writeRefreshToken('refresh-1');
        final client = MockClient((_) async {
          throw const SocketException('Connection reset by peer');
        });
        final repo = buildRepo(client);

        final state = await repo.loadInitialAuthState();

        expect(state, isA<AuthSignedOut>());
        expect(await tokenStore.readAccessToken(), 'access-1');
      },
    );

    test('returns signed in from cached profile without network', () async {
      await tokenStore.writeAccessToken('access-1');
      await tokenStore.writeCachedProfileJson(
        '{"id":"u1","email":"a@b.c","name":"A"}',
      );
      final client = MockClient((_) async {
        throw StateError('network should not be called');
      });
      final repo = buildRepo(client);

      final state = await repo.loadInitialAuthState();

      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u1');
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
