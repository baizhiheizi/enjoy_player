import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/data/auth_repository.dart';
import 'package:enjoy_player/features/auth/data/google_sign_in_service.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
    : super(
        authApi: AuthApi(
          ApiClient(
            httpClient: http.Client(),
            getBaseUrl: () async => 'https://enjoy.bot',
            getAccessToken: () async => null,
          ),
        ),
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
}

class _ThrowingGoogleSignInService extends GoogleSignInService {
  @override
  Future<void> signOut() => throw StateError('google sign-out unavailable');
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
}
