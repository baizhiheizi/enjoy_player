import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/data/api/services/direct_uploads_api.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/data/apple_sign_in_service.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:enjoy_player/features/auth/data/google_sign_in_service.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

ApiClient _testApiClient() => ApiClient(
  httpClient: http.Client(),
  getBaseUrl: () async => 'https://enjoy.bot',
  getAccessToken: () async => null,
);

const _profile = UserProfile(id: 'u1', email: 'user@example.com', name: 'User');
const _profile2 = UserProfile(
  id: 'u2',
  email: 'other@example.com',
  name: 'Other',
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({
    this.initialState = const AuthSignedOut(),
    this.initialStateError,
    this.signInGoogleError,
    this.signInAppleError,
    this.verifyOtpError,
    this.exchangePkceError,
    this.fetchProfileResult,
    this.updateProfileResult,
    this.updateAvatarResult,
    this.sendOtpDelay,
  }) : super(
         authApi: () {
           final c = _testApiClient();
           return AuthApi(authClient: c, userClient: c);
         }(),
         directUploadsApi: DirectUploadsApi(_testApiClient()),
         tokenStore: SecureTokenStore(const FlutterSecureStorage()),
         getBaseUrl: () async => 'https://enjoy.bot',
       );

  final AuthState initialState;
  final Object? initialStateError;
  final Object? signInGoogleError;
  final Object? signInAppleError;
  final Object? verifyOtpError;
  final Object? exchangePkceError;
  final UserProfile? fetchProfileResult;
  final UserProfile? updateProfileResult;
  final UserProfile? updateAvatarResult;
  final Duration? sendOtpDelay;

  String? lastOtpEmail;
  String? lastVerifyCode;
  String? lastExchangeCode;
  UpdateProfileRequest? lastUpdateRequest;
  List<int>? lastAvatarBytes;
  String? lastAvatarFilename;
  String? lastAvatarContentType;
  bool clearSessionCalled = false;

  @override
  Future<AuthState> loadInitialAuthState() async {
    if (initialStateError != null) throw initialStateError!;
    return initialState;
  }

  @override
  Future<UserProfile> signInGoogle({required String idToken}) async {
    if (signInGoogleError != null) throw signInGoogleError!;
    return _profile;
  }

  @override
  Future<UserProfile> signInApple({
    required String identityToken,
    required String authorizationCode,
    Map<String, String>? fullName,
  }) async {
    if (signInAppleError != null) throw signInAppleError!;
    return _profile;
  }

  @override
  Future<OtpSendResponse> sendOtp({required String email}) async {
    lastOtpEmail = email;
    if (sendOtpDelay != null) {
      await Future<void>.delayed(sendOtpDelay!);
    }
    return const OtpSendResponse(
      requestId: 'req-1',
      expiresIn: 600,
      resendAfter: 30,
    );
  }

  @override
  Future<UserProfile> verifyOtp({
    required String requestId,
    required String email,
    required String code,
  }) async {
    lastVerifyCode = code;
    if (verifyOtpError != null) throw verifyOtpError!;
    return _profile;
  }

  @override
  Future<UserProfile> exchangePkceCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    lastExchangeCode = code;
    if (exchangePkceError != null) throw exchangePkceError!;
    return _profile;
  }

  @override
  Future<Uri> buildPkceAuthorizeUri({
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) async {
    return Uri.parse(
      'https://enjoy.bot/api/v1/auth/authorize'
      '?client_id=enjoy_player&redirect_uri=$redirectUri'
      '&code_challenge=$codeChallenge&code_challenge_method=S256'
      '&state=$state',
    );
  }

  @override
  Future<UserProfile> fetchProfile() async {
    return fetchProfileResult ?? _profile2;
  }

  @override
  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    lastUpdateRequest = request;
    return updateProfileResult ?? _profile2;
  }

  @override
  Future<UserProfile> updateAvatar({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    lastAvatarBytes = bytes;
    lastAvatarFilename = filename;
    lastAvatarContentType = contentType;
    return updateAvatarResult ?? _profile2;
  }

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
  }
}

class _FakeGoogleSignInService extends GoogleSignInService {
  _FakeGoogleSignInService({this.idToken});

  final String? idToken;
  bool signOutCalled = false;
  Object? signOutError;

  @override
  Future<String?> signInForIdToken() async {
    return idToken;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (signOutError != null) throw signOutError!;
  }
}

class _FakeAppleSignInService extends AppleSignInService {
  _FakeAppleSignInService({this.credentials, this.signInError});

  final AppleSignInCredentials? credentials;
  final Object? signInError;

  @override
  Future<AppleSignInCredentials?> signIn() async {
    if (signInError != null) throw signInError!;
    return credentials;
  }
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  _FakeUrlLauncherPlatform({this.launchResult = true});

  final bool launchResult;
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return launchResult;
  }

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;
}

ProviderContainer _container({
  required _FakeAuthRepository repo,
  GoogleSignInService? google,
  AppleSignInService? apple,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      if (google != null) googleSignInServiceProvider.overrideWithValue(google),
      if (apple != null) appleSignInServiceProvider.overrideWithValue(apple),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUrlLauncherPlatform fakeUrlLauncher;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    fakeUrlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
  });

  group('build (loadInitialAuthState)', () {
    test('returns AuthSignedOut on success', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      final state = await container.read(authCtrlProvider.future);
      expect(state, isA<AuthSignedOut>());
    });

    test('returns AuthSignedIn when session exists', () async {
      final repo = _FakeAuthRepository(
        initialState: const AuthSignedIn(profile: _profile),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      final state = await container.read(authCtrlProvider.future);
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u1');
    });

    test('rethrows when loadInitialAuthState fails', () async {
      final repo = _FakeAuthRepository(
        initialStateError: StateError('storage corrupt'),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(authCtrlProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('cancelSignIn', () {
    test('resets to AuthSignedOut when OTP flow is in progress', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).sendOtp(email: 'a@b.com');
      expect(container.read(authCtrlProvider).value, isA<AuthAwaitingOtp>());

      container.read(authCtrlProvider.notifier).cancelSignIn();
      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('resets to AuthSignedOut when PKCE flow is in progress', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 's',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      notifier.cancelSignIn();
      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('does not change state when already signed out', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      container.read(authCtrlProvider.notifier).cancelSignIn();
      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('does not change state when signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      notifier.cancelSignIn();
      expect(container.read(authCtrlProvider).value, isA<AuthSignedIn>());
    });
  });

  group('signInWithGoogle', () {
    test('transitions to AuthSignedIn on success', () async {
      final repo = _FakeAuthRepository();
      final google = _FakeGoogleSignInService(idToken: 'tok-123');
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).signInWithGoogle();

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u1');
    });

    test('returns silently when user cancels (null idToken)', () async {
      final repo = _FakeAuthRepository();
      final google = _FakeGoogleSignInService(idToken: null);
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).signInWithGoogle();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('rethrows AuthFailure from repository', () async {
      final repo = _FakeAuthRepository(
        signInGoogleError: const AuthFailure(
          'bad token',
          code: AuthFailureCode.invalidCredentials,
        ),
      );
      final google = _FakeGoogleSignInService(idToken: 'tok');
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).signInWithGoogle(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('wraps generic exception in AuthFailure with unknown code', () async {
      final repo = _FakeAuthRepository(
        signInGoogleError: StateError('network down'),
      );
      final google = _FakeGoogleSignInService(idToken: 'tok');
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).signInWithGoogle(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.unknown,
          ),
        ),
      );
    });

    test(
      'aborts silently when cancelled mid-flight (generation mismatch)',
      () async {
        final repo = _FakeAuthRepository(
          sendOtpDelay: const Duration(milliseconds: 50),
        );
        final google = _FakeGoogleSignInService(idToken: 'tok');
        final container = _container(repo: repo, google: google);
        addTearDown(container.dispose);

        await container.read(authCtrlProvider.future);
        final notifier = container.read(authCtrlProvider.notifier);

        final future = notifier.signInWithGoogle();
        notifier.cancelSignIn();
        await future;

        expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
      },
    );
  });

  group('signInWithApple', () {
    test('transitions to AuthSignedIn on success', () async {
      final repo = _FakeAuthRepository();
      final apple = _FakeAppleSignInService(
        credentials: const AppleSignInCredentials(
          identityToken: 'id-tok',
          authorizationCode: 'auth-code',
          fullName: {'givenName': 'Jane', 'familyName': 'Doe'},
        ),
      );
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).signInWithApple();

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u1');
    });

    test('returns silently when user cancels (null credentials)', () async {
      final repo = _FakeAuthRepository();
      final apple = _FakeAppleSignInService(credentials: null);
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).signInWithApple();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('returns silently on AuthorizationErrorCode.canceled', () async {
      final repo = _FakeAuthRepository();
      final apple = _FakeAppleSignInService(
        signInError: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'User canceled',
        ),
      );
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).signInWithApple();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('throws AuthFailure on non-canceled authorization error', () async {
      final repo = _FakeAuthRepository();
      final apple = _FakeAppleSignInService(
        signInError: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.failed,
          message: 'Something went wrong',
        ),
      );
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).signInWithApple(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('rethrows AuthFailure from repository', () async {
      final repo = _FakeAuthRepository(
        signInAppleError: const AuthFailure(
          'server rejected',
          code: AuthFailureCode.serverError,
        ),
      );
      final apple = _FakeAppleSignInService(
        credentials: const AppleSignInCredentials(
          identityToken: 'id-tok',
          authorizationCode: 'auth-code',
        ),
      );
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).signInWithApple(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.serverError,
          ),
        ),
      );
    });

    test('wraps generic exception in AuthFailure with unknown code', () async {
      final repo = _FakeAuthRepository();
      final apple = _FakeAppleSignInService(
        signInError: StateError('unexpected'),
      );
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).signInWithApple(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.unknown,
          ),
        ),
      );
    });

    test('aborts silently when cancelled mid-flight', () async {
      final repo = _FakeAuthRepository();
      final apple = _FakeAppleSignInService(
        credentials: const AppleSignInCredentials(
          identityToken: 'id-tok',
          authorizationCode: 'auth-code',
        ),
      );
      final container = _container(repo: repo, apple: apple);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);

      final future = notifier.signInWithApple();
      notifier.cancelSignIn();
      await future;

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });
  });

  group('sendOtp', () {
    test('transitions to AuthAwaitingOtp with trimmed email', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container
          .read(authCtrlProvider.notifier)
          .sendOtp(email: '  user@example.com  ');

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthAwaitingOtp>());
      final otp = state as AuthAwaitingOtp;
      expect(otp.email, 'user@example.com');
      expect(otp.requestId, 'req-1');
      expect(otp.resendAfterSeconds, 30);
    });

    test('aborts when cancelled during sendOtp delay', () async {
      final repo = _FakeAuthRepository(
        sendOtpDelay: const Duration(milliseconds: 100),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);

      final future = notifier.sendOtp(email: 'a@b.com');
      notifier.cancelSignIn();
      await future;

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });
  });

  group('verifyOtp', () {
    test('transitions to AuthSignedIn on success', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      await notifier.sendOtp(email: 'user@example.com');
      await notifier.verifyOtp(code: '123456');

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u1');
      expect(repo.lastVerifyCode, '123456');
    });

    test('throws AuthFailure when not in AuthAwaitingOtp state', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).verifyOtp(code: '123'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws AuthFailure when signed in (not awaiting OTP)', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await expectLater(
        notifier.verifyOtp(code: '123'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('propagates repository error', () async {
      final repo = _FakeAuthRepository(
        verifyOtpError: const AuthFailure(
          'Invalid code',
          code: AuthFailureCode.invalidCredentials,
        ),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      await notifier.sendOtp(email: 'user@example.com');

      await expectLater(
        notifier.verifyOtp(code: '000000'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('aborts when cancelled mid-flight', () async {
      final repo = _FakeAuthRepository(
        sendOtpDelay: const Duration(milliseconds: 50),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      await notifier.sendOtp(email: 'user@example.com');

      final future = notifier.verifyOtp(code: '123456');
      notifier.cancelSignIn();
      await future;

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });
  });

  group('resendOtp', () {
    test('re-sends OTP when in AuthAwaitingOtp state', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      await notifier.sendOtp(email: 'user@example.com');
      await notifier.resendOtp();

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthAwaitingOtp>());
      expect((state as AuthAwaitingOtp).email, 'user@example.com');
      expect(repo.lastOtpEmail, 'user@example.com');
    });

    test('does nothing when not in AuthAwaitingOtp state', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).resendOtp();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
      expect(repo.lastOtpEmail, isNull);
    });
  });

  group('startWebPkceSignIn', () {
    test('transitions to AuthSigningInWebPkce and launches browser', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).startWebPkceSignIn();

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSigningInWebPkce>());
      final pkce = state as AuthSigningInWebPkce;
      expect(pkce.oauthState, isNotEmpty);
      expect(pkce.codeVerifier, isNotEmpty);
      expect(pkce.redirectUri, 'enjoyplayer://auth/callback');
      expect(fakeUrlLauncher.lastLaunchedUrl, contains('enjoy.bot'));
    });

    test('throws AuthFailure and resets when browser launch fails', () async {
      fakeUrlLauncher = _FakeUrlLauncherPlatform(launchResult: false);
      UrlLauncherPlatform.instance = fakeUrlLauncher;

      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container.read(authCtrlProvider.notifier).startWebPkceSignIn(),
        throwsA(isA<AuthFailure>()),
      );

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('aborts when cancelled before launch completes', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);

      final future = notifier.startWebPkceSignIn();
      notifier.cancelSignIn();
      await future;

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });
  });

  group('handleAuthCallbackUri', () {
    test('ignores callback when not in AuthSigningInWebPkce state', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container
          .read(authCtrlProvider.notifier)
          .handleAuthCallbackUri(
            Uri.parse('enjoyplayer://auth/callback?code=abc&state=xyz'),
          );

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
      expect(repo.lastExchangeCode, isNull);
    });

    test('ignores callback with invalid URI', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'st',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await notifier.handleAuthCallbackUri(
        Uri.parse('https://other.com/callback?code=abc&state=st'),
      );

      expect(
        container.read(authCtrlProvider).value,
        isA<AuthSigningInWebPkce>(),
      );
      expect(repo.lastExchangeCode, isNull);
    });

    test('ignores callback with missing params', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'st',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await notifier.handleAuthCallbackUri(
        Uri.parse('enjoyplayer://auth/callback'),
      );

      expect(
        container.read(authCtrlProvider).value,
        isA<AuthSigningInWebPkce>(),
      );
    });

    test('ignores callback with state mismatch', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'expected-state',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await notifier.handleAuthCallbackUri(
        Uri.parse('enjoyplayer://auth/callback?code=abc&state=wrong-state'),
      );

      expect(
        container.read(authCtrlProvider).value,
        isA<AuthSigningInWebPkce>(),
      );
      expect(repo.lastExchangeCode, isNull);
    });

    test('transitions to AuthSignedIn on successful code exchange', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'st-1',
          codeVerifier: 'verifier-1',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await notifier.handleAuthCallbackUri(
        Uri.parse('enjoyplayer://auth/callback?code=the-code&state=st-1'),
      );

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u1');
      expect(repo.lastExchangeCode, 'the-code');
    });

    test('resets to AuthSignedOut and rethrows on AuthFailure', () async {
      final repo = _FakeAuthRepository(
        exchangePkceError: const AuthFailure(
          'expired code',
          code: AuthFailureCode.invalidCredentials,
        ),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'st-1',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await expectLater(
        notifier.handleAuthCallbackUri(
          Uri.parse('enjoyplayer://auth/callback?code=c&state=st-1'),
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.invalidCredentials,
          ),
        ),
      );

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('resets to AuthSignedOut and wraps non-AuthFailure errors', () async {
      final repo = _FakeAuthRepository(
        exchangePkceError: StateError('keychain failure'),
      );
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'st-1',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await expectLater(
        notifier.handleAuthCallbackUri(
          Uri.parse('enjoyplayer://auth/callback?code=c&state=st-1'),
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.unknown,
          ),
        ),
      );

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('aborts silently when generation changes during exchange', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 'st-1',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      final future = notifier.handleAuthCallbackUri(
        Uri.parse('enjoyplayer://auth/callback?code=c&state=st-1'),
      );
      notifier.cancelSignIn();
      await future;

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });
  });

  group('signOut', () {
    test('clears session and transitions to AuthSignedOut', () async {
      final repo = _FakeAuthRepository();
      final google = _FakeGoogleSignInService(idToken: 'tok');
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.signOut();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
      expect(repo.clearSessionCalled, isTrue);
      expect(google.signOutCalled, isTrue);
    });

    test('stays signed out even when Google sign-out throws', () async {
      final repo = _FakeAuthRepository();
      final google = _FakeGoogleSignInService(idToken: 'tok')
        ..signOutError = StateError('google unavailable');
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.signOut();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
      expect(repo.clearSessionCalled, isTrue);
    });

    test('cancels in-progress PKCE flow', () async {
      final repo = _FakeAuthRepository();
      final google = _FakeGoogleSignInService(idToken: null);
      final container = _container(repo: repo, google: google);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 's',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await notifier.signOut();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });
  });

  group('refreshProfile', () {
    test('updates profile when signed in', () async {
      final repo = _FakeAuthRepository(fetchProfileResult: _profile2);
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.refreshProfile();

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u2');
    });

    test('does nothing when not signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container.read(authCtrlProvider.notifier).refreshProfile();

      expect(container.read(authCtrlProvider).value, isA<AuthSignedOut>());
    });

    test('does nothing when in OTP state', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      await notifier.sendOtp(email: 'a@b.com');

      await notifier.refreshProfile();

      expect(container.read(authCtrlProvider).value, isA<AuthAwaitingOtp>());
    });
  });

  group('updateProfile', () {
    test('updates profile when signed in', () async {
      final repo = _FakeAuthRepository(updateProfileResult: _profile2);
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      const request = UpdateProfileRequest(name: 'New Name');
      await notifier.updateProfile(request);

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u2');
      expect(repo.lastUpdateRequest?.name, 'New Name');
    });

    test('throws AuthFailure with sessionRevoked when not signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container
            .read(authCtrlProvider.notifier)
            .updateProfile(const UpdateProfileRequest(name: 'X')),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.sessionRevoked,
          ),
        ),
      );
    });

    test('throws AuthFailure when in OTP state', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      await notifier.sendOtp(email: 'a@b.com');

      await expectLater(
        notifier.updateProfile(const UpdateProfileRequest(name: 'X')),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('updateAvatar', () {
    test('updates avatar when signed in', () async {
      final repo = _FakeAuthRepository(updateAvatarResult: _profile2);
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.updateAvatar(
        bytes: const [1, 2, 3],
        filename: 'pic.png',
        contentType: 'image/png',
      );

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.id, 'u2');
      expect(repo.lastAvatarBytes, [1, 2, 3]);
      expect(repo.lastAvatarFilename, 'pic.png');
      expect(repo.lastAvatarContentType, 'image/png');
    });

    test('throws AuthFailure with sessionRevoked when not signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await expectLater(
        container
            .read(authCtrlProvider.notifier)
            .updateAvatar(bytes: const [1], filename: 'a.jpg'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.sessionRevoked,
          ),
        ),
      );
    });

    test('passes null contentType when not provided', () async {
      final repo = _FakeAuthRepository(updateAvatarResult: _profile2);
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.updateAvatar(bytes: const [9], filename: 'x.webp');

      expect(repo.lastAvatarContentType, isNull);
    });
  });

  group('syncLocaleToServerIfSignedIn', () {
    test('calls updateProfile with locale tag when signed in', () async {
      final repo = _FakeAuthRepository(updateProfileResult: _profile2);
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.syncLocaleToServerIfSignedIn(const Locale('en', 'US'));

      expect(repo.lastUpdateRequest?.locale, 'en-US');
    });

    test('does nothing when not signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      await container
          .read(authCtrlProvider.notifier)
          .syncLocaleToServerIfSignedIn(const Locale('fr'));

      expect(repo.lastUpdateRequest, isNull);
    });

    test('does nothing when locale is null', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = const AsyncData(AuthSignedIn(profile: _profile));

      await notifier.syncLocaleToServerIfSignedIn(null);

      expect(repo.lastUpdateRequest, isNull);
    });
  });

  group('PKCE timeout', () {
    test('timer resets state to AuthSignedOut after timeout', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);
      notifier.state = AsyncData(
        AuthSigningInWebPkce(
          oauthState: 's',
          codeVerifier: 'v',
          redirectUri: 'enjoyplayer://auth/callback',
          startedAt: DateTime.now(),
        ),
      );

      await container.read(authCtrlProvider.notifier).startWebPkceSignIn();
      expect(
        container.read(authCtrlProvider).value,
        isA<AuthSigningInWebPkce>(),
      );
    });
  });

  group('full OTP flow integration', () {
    test('sendOtp -> verifyOtp -> signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);

      await notifier.sendOtp(email: 'test@enjoy.bot');
      expect(container.read(authCtrlProvider).value, isA<AuthAwaitingOtp>());

      await notifier.verifyOtp(code: '654321');
      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect((state as AuthSignedIn).profile.email, 'user@example.com');
    });

    test('sendOtp -> cancelSignIn -> verifyOtp throws', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);

      await notifier.sendOtp(email: 'test@enjoy.bot');
      notifier.cancelSignIn();

      await expectLater(
        notifier.verifyOtp(code: '123'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('full PKCE flow integration', () {
    test('startWebPkceSignIn -> handleAuthCallbackUri -> signed in', () async {
      final repo = _FakeAuthRepository();
      final container = _container(repo: repo);
      addTearDown(container.dispose);

      await container.read(authCtrlProvider.future);
      final notifier = container.read(authCtrlProvider.notifier);

      await notifier.startWebPkceSignIn();
      final pkceState =
          container.read(authCtrlProvider).value as AuthSigningInWebPkce;

      await notifier.handleAuthCallbackUri(
        Uri.parse(
          'enjoyplayer://auth/callback?code=auth-code&state=${pkceState.oauthState}',
        ),
      );

      final state = container.read(authCtrlProvider).value;
      expect(state, isA<AuthSignedIn>());
      expect(repo.lastExchangeCode, 'auth-code');
    });
  });
}
