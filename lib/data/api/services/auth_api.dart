// ignore_for_file: prefer_initializing_formals

/// REST client for Enjoy account auth and profile.
library;

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/rest_api.dart';

/// Routes the unauthenticated `/api/v1/auth/*` endpoints through
/// [authClient] and the authenticated `/api/v1/profile` endpoints through
/// [userClient].
///
/// Why two clients? [authClient] is the no-refresh client used by sign-in,
/// OTP, PKCE exchange, and the refresh-token rotation itself — calling
/// `/api/v1/auth/refresh` from inside a 401-retry would recurse forever.
/// [userClient] is the refresh-enabled client used for normal signed-in
/// app traffic; routing the profile endpoints through it lets the 401-retry
/// hook transparently rotate the access token instead of immediately
/// calling `clearSession()` when the access JWT is past its 1-hour `exp`.
class AuthApi extends RestApi {
  AuthApi({required ApiClient authClient, required ApiClient userClient})
    : _userClient = userClient,
      super(authClient);

  final ApiClient _userClient;

  static const _authPrefix = '/api/v1/auth';

  Future<Map<String, dynamic>> signInGoogle({
    required String idToken,
    String? platform,
  }) => client.postJson(
    '$_authPrefix/google',
    body: {'idToken': idToken, 'platform': ?platform},
    requireAuth: false,
  );

  Future<Map<String, dynamic>> signInApple({
    required String identityToken,
    required String authorizationCode,
    Map<String, String>? fullName,
  }) => client.postJson(
    '$_authPrefix/apple',
    body: {
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
    },
    requireAuth: false,
  );

  Future<Map<String, dynamic>> sendOtp({required String email}) =>
      client.postJson(
        '$_authPrefix/otp/send',
        body: {'email': email},
        requireAuth: false,
      );

  Future<Map<String, dynamic>> verifyOtp({
    required String requestId,
    required String email,
    required String code,
  }) => client.postJson(
    '$_authPrefix/otp/verify',
    body: {'requestId': requestId, 'email': email, 'code': code},
    requireAuth: false,
  );

  Future<Map<String, dynamic>> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) => client.postJson(
    '$_authPrefix/token',
    body: {
      'grantType': 'authorization_code',
      'code': code,
      'codeVerifier': codeVerifier,
      'redirectUri': redirectUri,
    },
    requireAuth: false,
  );

  Future<Map<String, dynamic>> refresh({required String refreshToken}) =>
      client.postJson(
        '$_authPrefix/refresh',
        body: {'refreshToken': refreshToken},
        requireAuth: false,
      );

  Future<Map<String, dynamic>> profile() =>
      _userClient.getJson('/api/v1/profile');

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> user) =>
      _userClient.patchJson('/api/v1/profile', body: {'user': user});
}
