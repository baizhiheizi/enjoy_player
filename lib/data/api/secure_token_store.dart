/// Encrypted storage for API bearer token.
library;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, visibleForTesting;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/secure_storage_guard.dart';
import 'package:enjoy_player/data/api/secure_storage_op_lock.dart';
import 'package:enjoy_player/data/api/secure_storage_options.dart';

part 'secure_token_store.g.dart';

final Logger _log = logNamed('secureTokenStore');

const _kAccessTokenKey = 'enjoy_player.access_token';
const _kRefreshTokenKey = 'enjoy_player.refresh_token';
const _kCachedProfileJsonKey = 'enjoy_player.cached_profile_json';
const _kTokenExpiresAtKey = 'enjoy_player.token_expires_at';

@Riverpod(keepAlive: true)
SecureTokenStore secureTokenStore(Ref ref) {
  return SecureTokenStore(secureStorageBackend);
}

/// Thin wrapper around [FlutterSecureStorage].
///
/// Every operation is routed through [sharedSecureStorageOpLock]: on Linux
/// the backend keeps all keys in a single libsecret item and overlapping
/// operations interleave inside the GTK main loop, corrupting or losing the
/// freshly written session (see [SecureStorageOpLock]).
class SecureTokenStore {
  SecureTokenStore(this._storage, {SecureStorageOpLock? opLock})
    : _opLock = opLock ?? sharedSecureStorageOpLock;

  final FlutterSecureStorage _storage;
  final SecureStorageOpLock _opLock;

  @visibleForTesting
  FlutterSecureStorage get storage => _storage;

  Future<String?> readAccessToken() =>
      _serialized(() => _storage.read(key: _kAccessTokenKey));

  Future<void> writeAccessToken(String token) =>
      _serialized(() => _writeResilient(_kAccessTokenKey, token));

  Future<String?> readRefreshToken() =>
      _serialized(() => _storage.read(key: _kRefreshTokenKey));

  Future<void> writeRefreshToken(String token) =>
      _serialized(() => _writeResilient(_kRefreshTokenKey, token));

  Future<void> clearAccessToken() =>
      _serialized(() => _deleteBestEffort(_kAccessTokenKey));

  Future<void> clearRefreshToken() =>
      _serialized(() => _deleteBestEffort(_kRefreshTokenKey));

  /// JSON from [UserProfile.toJson] for cold-start UI before network fetch.
  Future<String?> readCachedProfileJson() =>
      _serialized(() => _storage.read(key: _kCachedProfileJsonKey));

  Future<void> writeCachedProfileJson(String json) =>
      _serialized(() => _writeResilient(_kCachedProfileJsonKey, json));

  Future<void> clearCachedProfile() =>
      _serialized(() => _deleteBestEffort(_kCachedProfileJsonKey));

  /// ISO 8601 UTC timestamp when the stored access token expires.
  Future<String?> readTokenExpiresAt() =>
      _serialized(() => _storage.read(key: _kTokenExpiresAtKey));

  Future<void> writeTokenExpiresAt(String expiresAt) =>
      _serialized(() => _writeResilient(_kTokenExpiresAtKey, expiresAt));

  Future<void> clearTokenExpiresAt() =>
      _serialized(() => _deleteBestEffort(_kTokenExpiresAtKey));

  /// Clears bearer token, refresh token, cached profile, and token expiry (sign out / invalid session).
  ///
  /// Best-effort by design: sign-out must always complete (the caller flips
  /// the UI to signed-out right after), so each delete failure is logged and
  /// the remaining keys are still attempted instead of aborting on the first.
  Future<void> clearAllAuthSecrets() => _serialized(() async {
    for (final key in const [
      _kAccessTokenKey,
      _kRefreshTokenKey,
      _kCachedProfileJsonKey,
      _kTokenExpiresAtKey,
    ]) {
      try {
        await _deleteRaw(key);
      } on PlatformException catch (e) {
        _log.warning('secure storage delete failed for "$key"', e);
      }
    }
  });

  Future<T> _serialized<T>(Future<T> Function() operation) =>
      _opLock.run(operation);

  Future<void> _deleteBestEffort(String key) async {
    try {
      await _deleteRaw(key);
    } on PlatformException catch (e) {
      _log.warning('secure storage delete failed for "$key"', e);
    }
  }

  Future<void> _deleteRaw(String key) =>
      deleteSecureStorageKey(_storage, key: key);

  /// Writes to the keychain/keystore, healing a stale entry that conflicts
  /// with the current write, and — on Linux — verifying the value actually
  /// stuck.
  Future<void> _writeResilient(String key, String value) async {
    await _writeWithDuplicateHeal(key, value);
    if (defaultTargetPlatform != TargetPlatform.linux) return;

    if (value.isEmpty || await _storage.read(key: key) == value) return;
    _log.warning(
      'secure storage write did not stick for "$key"; deleting and retrying',
    );
    await _deleteRaw(key);
    await _writeWithDuplicateHeal(key, value);
    if (value.isEmpty || await _storage.read(key: key) == value) return;
    throw PlatformException(
      code: 'secure_storage_write_lost',
      message:
          'Secure storage failed to persist "$key" (write not readable back '
          'after retry). The system keyring may be broken or locked.',
    );
  }

  Future<void> _writeWithDuplicateHeal(String key, String value) =>
      writeSecureStorageKey(_storage, key: key, value: value, log: _log);
}
