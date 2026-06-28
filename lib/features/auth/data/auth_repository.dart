/// Persists session tokens + profile cache; calls [AuthApi].
library;

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/features/auth/domain/auth_platform_support.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';

part 'auth_repository.g.dart';

final Logger _log = logNamed('auth');

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    authApi: AuthApi(ref.watch(authApiClientProvider)),
    tokenStore: ref.watch(secureTokenStoreProvider),
    getBaseUrl: () => ref.read(apiBaseUrlProvider.future),
  );
}

class AuthRepository {
  AuthRepository({
    required this._authApi,
    required this._tokenStore,
    required this._getBaseUrl,
  });

  final AuthApi _authApi;
  final SecureTokenStore _tokenStore;
  final Future<String> Function() _getBaseUrl;

  Future<UserProfile> signInGoogle({required String idToken}) =>
      _completeSignIn(
        _authApi.signInGoogle(
          idToken: idToken,
          platform: authGooglePlatformParam(),
        ),
      );

  Future<UserProfile> signInApple({
    required String identityToken,
    required String authorizationCode,
    Map<String, String>? fullName,
  }) => _completeSignIn(
    _authApi.signInApple(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      fullName: fullName,
    ),
  );

  Future<OtpSendResponse> sendOtp({required String email}) async {
    try {
      final m = await _authApi.sendOtp(email: email.trim());
      return OtpSendResponse.fromJson(m);
    } on ApiException catch (e) {
      throw AuthFailure(e.message, code: authFailureCodeForApiException(e));
    }
  }

  Future<UserProfile> verifyOtp({
    required String requestId,
    required String email,
    required String code,
  }) => _completeSignIn(
    _authApi.verifyOtp(
      requestId: requestId,
      email: email.trim(),
      code: code.trim(),
    ),
  );

  Future<UserProfile> exchangePkceCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) => _completeSignIn(
    _authApi.exchangeAuthorizationCode(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    ),
  );

  Future<Uri> buildPkceAuthorizeUri({
    required String redirectUri,
    required String codeChallenge,
    required String state,
  }) async {
    final base = _trimTrailingSlash(await _getBaseUrl());
    return Uri.parse('$base/api/v1/auth/authorize').replace(
      queryParameters: {
        'client_id': 'enjoy_player',
        'redirect_uri': redirectUri,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );
  }

  Future<bool> refreshSession() async {
    final refresh = await _tokenStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return false;
    }
    try {
      final m = await _authApi.refresh(refreshToken: refresh);
      final tokens = AuthTokenResponse.fromJson(m);
      await _persistTokens(tokens);
      return true;
    } on ApiException catch (e) {
      _log.warning('refresh session failed', e);
      if (_shouldRevokeSessionOnApiException(e)) {
        await clearSession();
      }
      return false;
    } catch (e, st) {
      _log.warning('refresh session failed', e, st);
      return false;
    }
  }

  /// Server explicitly told us the session is no longer valid; we must
  /// wipe local tokens. Transient 5xx / network errors keep the session
  /// so the next request can retry.
  static bool _shouldRevokeSessionOnApiException(ApiException e) {
    final status = e.statusCode;
    if (status == 401 || status == 403) return true;
    return false;
  }

  Future<UserProfile> fetchProfile() async {
    try {
      final m = await _authApi.profile();
      final profile = UserProfile.fromJson(m);
      await _cacheProfile(profile);
      return profile;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await clearSession();
      }
      throw AuthFailure(e.message, code: authFailureCodeForApiException(e));
    }
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    try {
      final body = request.toUserJson();
      if (body.isEmpty) {
        return fetchProfile();
      }
      final m = await _authApi.updateProfile(body);
      final profile = UserProfile.fromJson(m);
      await _cacheProfile(profile);
      return profile;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await clearSession();
      }
      throw AuthFailure(e.message, code: authFailureCodeForApiException(e));
    }
  }

  Future<UserProfile?> readCachedProfile() async {
    final raw = await _tokenStore.readCachedProfileJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> persistAccessToken(String token) =>
      _tokenStore.writeAccessToken(token);

  Future<bool> hasAccessToken() async {
    final t = await _tokenStore.readAccessToken();
    return t != null && t.isNotEmpty;
  }

  Future<AuthState> loadInitialAuthState() async {
    final hasToken = await hasAccessToken();
    if (!hasToken) {
      await _tokenStore.clearCachedProfile();
      return const AuthSignedOut();
    }
    final cached = await readCachedProfile();
    if (cached != null) {
      return AuthSignedIn(profile: cached);
    }
    try {
      final profile = await fetchProfile();
      return AuthSignedIn(profile: profile);
    } on AuthFailure {
      await clearSession();
      return const AuthSignedOut();
    }
  }

  Future<void> clearSession() async {
    await _tokenStore.clearAllAuthSecrets();
  }

  Future<UserProfile> _completeSignIn(
    Future<Map<String, dynamic>> request,
  ) async {
    try {
      final m = await request;
      final tokens = AuthTokenResponse.fromJson(m);
      await _persistTokens(tokens);
      if (tokens.user != null) {
        await _cacheProfile(tokens.user!);
        return tokens.user!;
      }
      return fetchProfile();
    } on ApiException catch (e) {
      throw AuthFailure(e.message, code: authFailureCodeForApiException(e));
    } on FormatException catch (e) {
      throw AuthFailure(e.message, code: AuthFailureCode.invalidCredentials);
    }
  }

  Future<void> _persistTokens(AuthTokenResponse tokens) async {
    await _tokenStore.writeAccessToken(tokens.accessToken);
    await _tokenStore.writeRefreshToken(tokens.refreshToken);
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    await _tokenStore.writeCachedProfileJson(jsonEncode(profile.toJson()));
  }

  static String _trimTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}

/// Maps an [ApiException] thrown by the auth API to an [AuthFailureCode] so
/// the UI can distinguish "you typed the wrong code" from "the server is down"
/// from "your session expired and we logged you out".
AuthFailureCode authFailureCodeForApiException(ApiException e) {
  final status = e.statusCode;
  if (status == 401 || status == 403) return AuthFailureCode.sessionRevoked;
  if (status == 429) return AuthFailureCode.rateLimited;
  if (status != null && status >= 500) return AuthFailureCode.serverError;
  if (status == 400 || status == 404 || status == 422) {
    return AuthFailureCode.invalidCredentials;
  }
  return AuthFailureCode.unknown;
}
