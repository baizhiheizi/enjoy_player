import 'dart:async';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/data/api/services/direct_uploads_api.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:enjoy_player/features/auth/data/google_sign_in_service.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:enjoy_player/features/auth/domain/pkce.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

ApiClient _testApiClient() => ApiClient(
  httpClient: http.Client(),
  getBaseUrl: () async => 'https://enjoy.bot',
  getAccessToken: () async => null,
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        authApi: () {
          final sharedClient = _testApiClient();
          return AuthApi(authClient: sharedClient, userClient: sharedClient);
        }(),
        directUploadsApi: DirectUploadsApi(_testApiClient()),
        tokenStore: SecureTokenStore(const FlutterSecureStorage()),
        getBaseUrl: () async => 'https://enjoy.bot',
      );

  @override
  Future<OtpSendResponse> sendOtp({required String email}) async {
    return const OtpSendResponse(
      requestId: 'r1',
      expiresIn: 600,
      resendAfter: 30,
    );
  }

  @override
  Future<AuthState> loadInitialAuthState() async => const AuthSignedOut();

  final List<String> signOutCalls = <String>[];
  final List<String?> revokedTokens = <String?>[];
  String? storedRefreshToken = 'refresh-token-1';
  Completer<void>? revokeGate;
  bool failRevoke = false;
  int revokedFailures = 0;

  @override
  Future<String?> readRefreshToken() async {
    signOutCalls.add('read');
    return storedRefreshToken;
  }

  @override
  Future<void> revokeRefreshTokenBestEffort(String? refreshToken) async {
    signOutCalls.add('revoke');
    revokedTokens.add(refreshToken);
    if (revokeGate != null) {
      await revokeGate!.future;
    }
    if (failRevoke) {
      revokedFailures++;
    }
  }

  @override
  Future<void> clearSession() async {
    signOutCalls.add('clear');
    await super.clearSession();
  }
}

class _ThrowingGoogleSignInService extends GoogleSignInService {
  @override
  Future<void> signOut() => throw StateError('google sign-out unavailable');
}

/// Reproduces the real bug: the server-side PKCE exchange succeeds, but
/// persisting the resulting tokens throws a non-[AuthFailure] exception
/// (e.g. the keychain `PlatformException` from a stale entry).
class _PersistFailsAuthRepository extends _FakeAuthRepository {
  @override
  Future<UserProfile> exchangePkceCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) => Future.error(
    PlatformException(
      code: 'Unexpected security result code',
      message: 'Code: -25299, Message: item already exists',
      details: -25299,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sendOtp transitions to AuthAwaitingOtp', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final fake = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(authCtrlProvider.future);
    await container
        .read(authCtrlProvider.notifier)
        .sendOtp(email: 'user@example.com');

    final state = container.read(authCtrlProvider).value;
    expect(state, isA<AuthAwaitingOtp>());
    expect((state as AuthAwaitingOtp).email, 'user@example.com');
  });

  test('updateAvatar throws AuthFailure when not signed in', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final fake = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(authCtrlProvider.future);
    expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());

    await expectLater(
      container
          .read(authCtrlProvider.notifier)
          .updateAvatar(bytes: const [1, 2, 3], filename: 'a.jpg'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('signOut stays signed out when Google sign-out throws', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final fake = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fake),
        googleSignInServiceProvider.overrideWithValue(
          _ThrowingGoogleSignInService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authCtrlProvider.future);
    container.read(authCtrlProvider.notifier).state = const AsyncData(
      AuthSignedIn(
        profile: UserProfile(id: 'u1', email: 'user@example.com', name: 'User'),
      ),
    );

    await container.read(authCtrlProvider.notifier).signOut();

    expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    expect(await fake.hasAccessToken(), isFalse);
  });

  test('handleAuthCallbackUri resets to AuthSignedOut and surfaces an '
      'AuthFailure when persisting tokens throws a non-AuthFailure error '
      '(e.g. a keychain PlatformException), instead of leaving the flow '
      'stuck on AuthSigningInWebPkce forever', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final fake = _PersistFailsAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(authCtrlProvider.future);
    final notifier = container.read(authCtrlProvider.notifier);
    final pkce = generatePkcePair();
    const oauthState = 'state-123';
    notifier.state = AsyncData(
      AuthSigningInWebPkce(
        oauthState: oauthState,
        codeVerifier: pkce.verifier,
        redirectUri: 'enjoyplayer://auth/callback',
        startedAt: DateTime.now(),
      ),
    );

    await expectLater(
      notifier.handleAuthCallbackUri(
        Uri.parse('enjoyplayer://auth/callback?code=abc&state=$oauthState'),
      ),
      throwsA(isA<AuthFailure>()),
    );

    expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
  });

  test(
    'signOut clears local session immediately and revokes in background',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final revokeGate = Completer<void>();
      final fake = _FakeAuthRepository()..revokeGate = revokeGate;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(authCtrlProvider.notifier).state = const AsyncData(
        AuthSignedIn(
          profile: UserProfile(
            id: 'u1',
            email: 'user@example.com',
            name: 'User',
          ),
        ),
      );

      await container.read(authCtrlProvider.notifier).signOut();

      expect(fake.signOutCalls.sublist(0, 2), ['read', 'clear']);
      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
      expect(fake.revokedTokens, ['refresh-token-1']);

      revokeGate.complete();
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'signOut still clears local session when the background revoke fails',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final fake = _FakeAuthRepository()..failRevoke = true;
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(authCtrlProvider.notifier).state = const AsyncData(
        AuthSignedIn(
          profile: UserProfile(
            id: 'u1',
            email: 'user@example.com',
            name: 'User',
          ),
        ),
      );

      await container.read(authCtrlProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);

      expect(fake.signOutCalls, ['read', 'clear', 'revoke']);
      expect(fake.revokedFailures, 1);
      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    },
  );
}
