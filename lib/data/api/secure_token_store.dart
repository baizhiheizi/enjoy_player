/// Encrypted storage for API bearer token.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_token_store.g.dart';

const _kAccessTokenKey = 'enjoy_player.access_token';
const _kCachedProfileJsonKey = 'enjoy_player.cached_profile_json';

@Riverpod(keepAlive: true)
SecureTokenStore secureTokenStore(Ref ref) {
  return SecureTokenStore(const FlutterSecureStorage());
}

/// Thin wrapper around [FlutterSecureStorage].
class SecureTokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _kAccessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _kAccessTokenKey, value: token);

  Future<void> clearAccessToken() => _storage.delete(key: _kAccessTokenKey);

  /// JSON from [UserProfile.toJson] for cold-start UI before network fetch.
  Future<String?> readCachedProfileJson() =>
      _storage.read(key: _kCachedProfileJsonKey);

  Future<void> writeCachedProfileJson(String json) =>
      _storage.write(key: _kCachedProfileJsonKey, value: json);

  Future<void> clearCachedProfile() =>
      _storage.delete(key: _kCachedProfileJsonKey);

  /// Clears bearer token and cached profile (sign out / invalid session).
  Future<void> clearAllAuthSecrets() async {
    await clearAccessToken();
    await clearCachedProfile();
  }
}
