/// REST client for Enjoy account auth and profile.
library;

import 'package:enjoy_player/data/api/rest_api.dart';

class AuthApi extends RestApi {
  AuthApi(super.client);

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

  Future<Map<String, dynamic>> profile() => client.getJson('/api/v1/profile');

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> user) =>
      client.patchJson('/api/v1/profile', body: {'user': user});
}
