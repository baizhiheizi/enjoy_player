import 'dart:convert';
import 'dart:math';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:enjoy_player/features/auth/domain/auth_callback.dart';
import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:enjoy_player/features/auth/domain/pkce.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PKCE', () {
    test('verifier and challenge are non-empty', () {
      final pair = generatePkcePair(random: Random(1));
      expect(pair.verifier.length, greaterThanOrEqualTo(43));
      expect(pair.challenge, isNotEmpty);
      expect(pair.challenge.contains('='), isFalse);
    });

    test('generateOAuthState is stable length', () {
      final state = generateOAuthState(random: Random(2));
      expect(state.length, 32);
    });
  });

  group('auth callback URI', () {
    test('accepts custom scheme callback', () {
      final uri = Uri.parse('enjoyplayer://auth/callback?code=abc&state=xyz');
      expect(isAuthCallbackUri(uri), isTrue);
      expect(parseAuthCallbackUri(uri)?.code, 'abc');
    });

    test('rejects state mismatch at parse level', () {
      final uri = Uri.parse('enjoyplayer://auth/callback?code=abc');
      expect(parseAuthCallbackUri(uri), isNull);
    });
  });

  group('AuthRepository OTP verify', () {
    test('persists access and refresh tokens', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureTokenStore(const FlutterSecureStorage());
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/otp/verify');
        return http.Response(
          jsonEncode({
            'access_token': 'access-1',
            'refresh_token': 'refresh-1',
            'expires_in': 3600,
            'token_type': 'Bearer',
            'user': {'id': 'u1', 'email': 'a@b.com', 'name': 'Test'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        httpClient: client,
        getBaseUrl: () async => 'https://enjoy.bot',
        getAccessToken: store.readAccessToken,
      );
      final repo = AuthRepository(
        authApi: AuthApi(apiClient),
        tokenStore: store,
        getBaseUrl: () async => 'https://enjoy.bot',
      );

      final profile = await repo.verifyOtp(
        requestId: 'req',
        email: 'a@b.com',
        code: '123456',
      );
      expect(profile.email, 'a@b.com');
      expect(await store.readAccessToken(), 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');
    });
  });

  test('AuthTokenResponse rejects missing refresh token', () {
    expect(
      () => AuthTokenResponse.fromJson({'accessToken': 'a', 'expiresIn': 60}),
      throwsFormatException,
    );
  });
}
