/// Encrypted storage for API bearer token.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_token_store.g.dart';

const _kAccessTokenKey = 'enjoy_player.access_token';

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
}
