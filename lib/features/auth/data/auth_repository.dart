/// Persists session tokens + profile cache; calls [AuthApi].
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show PlatformException;
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/application/in_flight_op.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/data/api/services/direct_uploads_api.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_platform_support.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/auth_token_response.dart';
import 'package:enjoy_player/features/auth/domain/avatar_pick_constraints.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';

part 'auth_repository.g.dart';

final Logger _log = logNamed('auth');

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final userClient = ref.watch(apiClientProvider);
  final repo = AuthRepository(
    authApi: AuthApi(
      authClient: ref.watch(authApiClientProvider),
      userClient: userClient,
    ),
    directUploadsApi: DirectUploadsApi(userClient),
    tokenStore: ref.watch(secureTokenStoreProvider),
    getBaseUrl: () => ref.read(apiBaseUrlProvider.future),
    onSessionLost: () => ref.invalidate(authCtrlProvider),
  );

  registerOn401RefreshCallback(() async {
    final ok = await repo.refreshSession();
    if (!ok) {
      final hasToken = await repo.hasAccessToken();
      if (!hasToken) {
        ref.invalidate(authCtrlProvider);
      }
    }
    return ok;
  });
  ref.onDispose(clearOn401RefreshCallback);

  return repo;
}

class AuthRepository {
  AuthRepository({
    required this._authApi,
    required this._directUploadsApi,
    required this._tokenStore,
    required this._getBaseUrl,
    this.onSessionLost,
  });

  final AuthApi _authApi;
  final DirectUploadsApi _directUploadsApi;
  final SecureTokenStore _tokenStore;
  final Future<String> Function() _getBaseUrl;

  /// Invoked when a background session revalidation started by
  /// [loadInitialAuthState] finds the session revoked and no usable token
  /// left — wired by `authRepositoryProvider` to invalidate
  /// `authCtrlProvider` so the UI transitions to signed-out.
  final void Function()? onSessionLost;

  /// In-flight session revalidation kicked by the most recent
  /// [loadInitialAuthState] that found an expired token plus a cached
  /// profile, or `null` when no revalidation is running. Tests use it to
  /// await the background refresh; production code treats revalidation as
  /// fire-and-forget.
  @visibleForTesting
  Future<void>? get sessionRevalidation => _sessionRevalidation;
  Future<void>? _sessionRevalidation;

  /// Single-flight guard for [refreshSession].
  ///
  /// When multiple concurrent API calls hit a 401 from an expired access
  /// token, they all enter the 401-retry path at once and would each call
  /// `POST /api/v1/auth/refresh`. The backend
  /// ([`RefreshTokenRotator`](https://github.com/baizhiheizi/enjoy_web/blob/main/app/services/native_auth/refresh_token_rotator.rb))
  /// rotates the refresh token eagerly on first receipt, so the second /
  /// third / … concurrent calls would see HTTP 401 `Invalid refresh token`
  /// and [clearSession] would fire — signing the user out. Sharing a single
  /// in-flight `Future` keeps a burst of parallel 401s down to one refresh
  /// round-trip.
  final InFlightOp<bool> _refreshFlight = InFlightOp<bool>();

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

  Future<OtpSendResponse> sendOtp({required String email}) =>
      _guardApi(() async {
        final m = await _authApi.sendOtp(email: email.trim());
        return OtpSendResponse.fromJson(m);
      }, revokeSession: false);

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
        'prompt': 'select_account',
        'state': state,
      },
    );
  }

  Future<bool> refreshSession() => _refreshFlight.run((_) => _refreshSession());

  Future<bool> _refreshSession() async {
    try {
      final refresh = await _tokenStore.readRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        return false;
      }
      final m = await _authApi.refresh(refreshToken: refresh);
      final tokens = AuthTokenResponse.fromJson(m);
      await _persistTokens(tokens);
      return true;
    } on ApiException catch (e) {
      _log.warning('refresh session failed', e);
      if (_shouldRevokeSessionOnApiException(e)) {
        try {
          await clearSession();
        } catch (e2, st2) {
          _log.warning('clearSession failed during refresh', e2, st2);
        }
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

  /// Single mapping point for transport failures raised by the auth API.
  ///
  /// A rejected session (HTTP 401 or 403) clears the local tokens before the
  /// [AuthFailure] surfaces — see [AuthFailureCode.sessionRevoked]. Pass
  /// `revokeSession: false` for calls that run without an established session
  /// (sign-in, OTP request, and the profile fetch that follows a sign-in).
  Future<T> _guardApi<T>(
    Future<T> Function() call, {
    bool revokeSession = true,
  }) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (revokeSession && _shouldRevokeSessionOnApiException(e)) {
        try {
          await clearSession();
        } catch (e2, st2) {
          _log.warning('clearSession failed', e2, st2);
        }
      }
      throw AuthFailure(e.message, code: authFailureCodeForApiException(e));
    }
  }

  Future<UserProfile> fetchProfile() => _fetchProfile(revokeSession: true);

  Future<UserProfile> _fetchProfile({required bool revokeSession}) =>
      _guardApi(() async {
        final m = await _authApi.profile();
        final profile = UserProfile.fromJson(m);
        await _cacheProfile(profile);
        return profile;
      }, revokeSession: revokeSession);

  Future<UserProfile> updateProfile(UpdateProfileRequest request) =>
      _guardApi(() async {
        final body = request.toUserJson();
        if (body.isEmpty) {
          return await fetchProfile();
        }
        final m = await _authApi.updateProfile(body);
        final profile = UserProfile.fromJson(m);
        await _cacheProfile(profile);
        return profile;
      });

  /// Direct-uploads [bytes] then attaches via `user.avatar` signed_id.
  Future<UserProfile> updateAvatar({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final mime = contentType?.trim().isNotEmpty == true
        ? contentType!.trim().toLowerCase()
        : avatarContentTypeForFilename(filename);
    final failure = validateAvatarPick(
      byteLength: bytes.length,
      filename: filename,
      contentType: mime,
    );
    if (failure != null) {
      throw AuthFailure(switch (failure) {
        AvatarPickFailure.empty => 'Avatar file is empty',
        AvatarPickFailure.tooLarge => 'Avatar must be 2 MB or smaller',
        AvatarPickFailure.unsupportedType =>
          'Avatar must be JPEG, PNG, or WebP',
      }, code: AuthFailureCode.unknown);
    }
    if (mime == null) {
      throw const AuthFailure(
        'Avatar must be JPEG, PNG, or WebP',
        code: AuthFailureCode.unknown,
      );
    }

    return _guardApi(() async {
      final signedId = await _directUploadsApi.uploadBlob(
        bytes: bytes,
        filename: filename,
        contentType: mime,
      );
      return await updateProfile(
        UpdateProfileRequest(avatarSignedId: signedId),
      );
    });
  }

  Future<UserProfile?> readCachedProfile() => _readOrNull(
    _tokenStore.readCachedProfileJson,
  ).then(_decodeCachedProfileJson);

  static UserProfile? _decodeCachedProfileJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return UserProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasAccessToken() async {
    final t = await _tokenStore.readAccessToken();
    return t != null && t.isNotEmpty;
  }

  Future<AuthState> loadInitialAuthState() async {
    final reads = await Future.wait(
      _secureStorageReads().map((read) => _readOrNull(read)),
    );
    final accessToken = reads[0];
    final expiresAtRaw = reads[1];
    final cachedProfileJson = reads[2];

    if (accessToken == null || accessToken.isEmpty) {
      await _tokenStore.clearCachedProfile();
      return const AuthSignedOut();
    }

    final cached = _decodeCachedProfileJson(cachedProfileJson);
    final tokenExpired = _isExpiredToken(expiresAtRaw);

    if (cached != null) {
      if (tokenExpired) {
        _sessionRevalidation = _revalidateSessionInBackground();
      }
      return AuthSignedIn(profile: cached);
    }

    if (tokenExpired) {
      final refreshed = await refreshSession();
      if (!refreshed) {
        return const AuthSignedOut();
      }
    }

    try {
      final profile = await fetchProfile();
      return AuthSignedIn(profile: profile);
    } on AuthFailure {
      await clearSession();
      return const AuthSignedOut();
    } catch (e, st) {
      _log.warning('loadInitialAuthState: profile fetch failed', e, st);
      return const AuthSignedOut();
    }
  }

  List<Future<String?> Function()> _secureStorageReads() => [
    _tokenStore.readAccessToken,
    _tokenStore.readTokenExpiresAt,
    _tokenStore.readCachedProfileJson,
  ];

  Future<String?> _readOrNull(Future<String?> Function() read) async {
    try {
      return await read();
    } on PlatformException catch (e, st) {
      _log.warning('loadInitialAuthState: secure storage read failed', e, st);
      return null;
    }
  }

  /// Upper bound for one background refresh attempt; matches the 15 s the
  /// auth feature already uses for `profile_practice_stats_provider`.
  static const _backgroundRefreshTimeout = Duration(seconds: 15);

  /// Delay before the single retry of a transient background refresh
  /// failure.
  static const _backgroundRefreshRetryDelay = Duration(seconds: 30);

  /// Refreshes the expired token behind the signed-in first frame.
  ///
  /// Contract:
  /// - refresh succeeds: tokens are rotated, session stays;
  /// - refresh refused and the stored access token was cleared (401/403):
  ///   [onSessionLost] fires;
  /// - transient failure — network error, timeout, or 5xx — leaves the
  ///   stored access token intact: one delayed retry runs, then the session
  ///   stays as-is; the 401-refresh interceptor on the next API call is the
  ///   recovery path (see `registerOn401RefreshCallback`).
  Future<void> _revalidateSessionInBackground({bool allowRetry = true}) async {
    try {
      final refreshed = await refreshSession().timeout(
        _backgroundRefreshTimeout,
      );
      if (refreshed) return;
      if (await hasAccessToken()) {
        await _retryTransientRevalidation(allowRetry);
        return;
      }
      _log.info('session revoked during background revalidation');
      onSessionLost?.call();
    } on TimeoutException catch (e) {
      _log.warning('background session revalidation timed out', e);
      await _retryTransientRevalidation(allowRetry);
    } catch (e, st) {
      _log.warning('background session revalidation failed', e, st);
    }
  }

  /// Runs the single delayed retry after a transient revalidation failure;
  /// the retried attempt itself never schedules another.
  Future<void> _retryTransientRevalidation(bool allowRetry) async {
    if (!allowRetry) return;
    await Future<void>.delayed(_backgroundRefreshRetryDelay);
    await _revalidateSessionInBackground(allowRetry: false);
  }

  static bool _isExpiredToken(String? expiresAtRaw) {
    if (expiresAtRaw == null || expiresAtRaw.isEmpty) return false;
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt);
  }

  Future<String?> readRefreshToken() => _tokenStore.readRefreshToken();

  /// Revokes [refreshToken] on the server, swallowing every failure.
  ///
  /// Never throws: an absent or empty token is skipped, and a failed or
  /// timed-out request is logged. Callers can fire this without a guard.
  Future<void> revokeRefreshTokenBestEffort(String? refreshToken) async {
    if (refreshToken == null || refreshToken.isEmpty) return;
    try {
      await _authApi
          .logout(refreshToken: refreshToken)
          .timeout(const Duration(seconds: 3));
    } catch (e, st) {
      _log.warning('server logout revoke failed', e, st);
    }
  }

  Future<void> clearSession() async {
    await _tokenStore.clearAllAuthSecrets();
  }

  Future<UserProfile> _completeSignIn(
    Future<Map<String, dynamic>> request,
  ) async {
    try {
      return await _guardApi(() async {
        final m = await request;
        final tokens = AuthTokenResponse.fromJson(m);
        await _persistTokens(tokens);
        if (tokens.user != null) {
          await _cacheProfile(tokens.user!);
          return tokens.user!;
        }
        return await _fetchProfile(revokeSession: false);
      }, revokeSession: false);
    } on FormatException catch (e) {
      throw AuthFailure(e.message, code: AuthFailureCode.invalidCredentials);
    }
  }

  Future<void> _persistTokens(AuthTokenResponse tokens) async {
    await _tokenStore.writeAccessToken(tokens.accessToken);
    await _tokenStore.writeRefreshToken(tokens.refreshToken);
    final expiresAt = DateTime.now()
        .add(Duration(seconds: tokens.expiresIn))
        .toUtc();
    await _tokenStore.writeTokenExpiresAt(expiresAt.toIso8601String());
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
