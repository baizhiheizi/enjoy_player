/// Encrypted storage for API bearer token.
library;

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';

part 'secure_token_store.g.dart';

final Logger _log = logNamed('secureTokenStore');

const _kAccessTokenKey = 'enjoy_player.access_token';
const _kRefreshTokenKey = 'enjoy_player.refresh_token';
const _kCachedProfileJsonKey = 'enjoy_player.cached_profile_json';

/// Pin Android to the v10 default RSA-OAEP / AES-GCM ciphers (migrates from
/// the deprecated Jetpack Security `encryptedSharedPreferences` on first read)
/// and iOS to `first_unlock` so tokens survive device reboot but stay
/// inaccessible until the user has unlocked the device at least once.
const _kAndroidOptions = AndroidOptions();
const _kIosOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock,
);

@Riverpod(keepAlive: true)
SecureTokenStore secureTokenStore(Ref ref) {
  return SecureTokenStore(
    const FlutterSecureStorage(
      aOptions: _kAndroidOptions,
      iOptions: _kIosOptions,
    ),
  );
}

/// Thin wrapper around [FlutterSecureStorage].
class SecureTokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _kAccessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _writeResilient(_kAccessTokenKey, token);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _writeResilient(_kRefreshTokenKey, token);

  Future<void> clearAccessToken() => _storage.delete(key: _kAccessTokenKey);

  Future<void> clearRefreshToken() => _storage.delete(key: _kRefreshTokenKey);

  /// JSON from [UserProfile.toJson] for cold-start UI before network fetch.
  Future<String?> readCachedProfileJson() =>
      _storage.read(key: _kCachedProfileJsonKey);

  Future<void> writeCachedProfileJson(String json) =>
      _writeResilient(_kCachedProfileJsonKey, json);

  Future<void> clearCachedProfile() =>
      _storage.delete(key: _kCachedProfileJsonKey);

  /// Clears bearer token, refresh token, and cached profile (sign out / invalid session).
  Future<void> clearAllAuthSecrets() async {
    await clearAccessToken();
    await clearRefreshToken();
    await clearCachedProfile();
  }

  /// Writes to the keychain/keystore, self-healing from a stale entry that
  /// conflicts with the current write.
  ///
  /// On iOS/macOS, `flutter_secure_storage`'s `write()` first checks
  /// existence with a query that includes `kSecAttrAccessible` (our pinned
  /// `first_unlock`), then falls back to `SecItemAdd` when nothing matches.
  /// `kSecAttrAccessible` is **not** part of a keychain item's primary key,
  /// so a leftover item for the same account/service stored under a
  /// *different* accessibility (e.g. from an older app build, or a run that
  /// was killed mid-write) makes that existence check report "not found"
  /// while `SecItemAdd` still finds a primary-key collision — surfacing as
  /// `PlatformException(Unexpected security result code, ..., -25299 /
  /// errSecDuplicateItem, ...)` and permanently blocking sign-in (see the
  /// PKCE callback failure this was introduced to fix). Deleting the key
  /// (which searches without an accessibility filter) and retrying once
  /// clears any such stale entry regardless of its accessibility level.
  Future<void> _writeResilient(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      if (!_isDuplicateKeychainItem(e)) rethrow;
      _log.warning(
        'secure storage write hit a stale keychain item for "$key" '
        '(errSecDuplicateItem); deleting and retrying once',
        e,
      );
      await _storage.delete(key: key);
      await _storage.write(key: key, value: value);
    }
  }

  static bool _isDuplicateKeychainItem(PlatformException e) {
    const duplicateItemStatus = -25299; // errSecDuplicateItem
    return e.details == duplicateItemStatus ||
        (e.message?.contains('$duplicateItemStatus') ?? false);
  }
}
