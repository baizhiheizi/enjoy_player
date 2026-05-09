/// Persists session token + profile cache; calls [AuthApi].
library;

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:enjoy_player/data/api/services/auth_api.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';

part 'auth_repository.g.dart';

final Logger _log = logNamed('auth');

/// Nested JSON maps from [decodeJsonToCamel] are often [Map<dynamic, dynamic>],
/// not [Map<String, dynamic>], so always normalize before strict typing.
Map<String, dynamic>? _jsonObjectAsStringMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
  return null;
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    authApi: AuthApi(ref.watch(apiClientProvider)),
    tokenStore: ref.watch(secureTokenStoreProvider),
  );
}

class AuthRepository {
  AuthRepository({
    required AuthApi authApi,
    required SecureTokenStore tokenStore,
  })  : _authApi = authApi,
        _tokenStore = tokenStore;

  final AuthApi _authApi;
  final SecureTokenStore _tokenStore;

  Future<({String requestId, String verificationUrl})> startAuth() async {
    try {
      final m = await _authApi.startAuth();
      final requestId = m['requestId'] as String?;
      final verificationUrl = m['verificationUrl'] as String?;
      if (requestId == null ||
          requestId.isEmpty ||
          verificationUrl == null ||
          verificationUrl.isEmpty) {
        throw const AuthFailure('Invalid start_auth response');
      }
      return (requestId: requestId, verificationUrl: verificationUrl);
    } on ApiException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<PollAuthOutcome> pollAuth(String requestId) async {
    try {
      final m = await _authApi.pollAuth(requestId);
      final status = m['status'] as String?;
      if (status == 'approved') {
        final token = m['accessToken'] as String?;
        final user = _jsonObjectAsStringMap(m['user']);
        if (token == null || token.isEmpty || user == null) {
          _log.warning(
            'poll approved: expected accessToken + user object; '
            'topKeys=${m.keys.toList()} userType=${m['user']?.runtimeType} '
            'tokenMissing=${token == null || token.isEmpty}',
          );
          throw const AuthFailure('Invalid poll approved response');
        }
        return PollAuthOutcomeApproved(accessToken: token, user: user);
      }
      return const PollAuthOutcomePending();
    } on ApiException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> persistAccessToken(String token) =>
      _tokenStore.writeAccessToken(token);

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
      throw AuthFailure(e.message);
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
      throw AuthFailure(e.message);
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

  Future<void> _cacheProfile(UserProfile profile) async {
    await _tokenStore.writeCachedProfileJson(jsonEncode(profile.toJson()));
  }

  Future<bool> hasAccessToken() async {
    final t = await _tokenStore.readAccessToken();
    return t != null && t.isNotEmpty;
  }

  /// Cold start: token + optional cached profile, else fetch profile.
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
}

sealed class PollAuthOutcome {
  const PollAuthOutcome();
}

final class PollAuthOutcomePending extends PollAuthOutcome {
  const PollAuthOutcomePending();
}

final class PollAuthOutcomeApproved extends PollAuthOutcome {
  const PollAuthOutcomeApproved({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final Map<String, dynamic> user;
}
