import 'package:enjoy_player/data/api/secure_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates the real-world iOS/macOS bug this store guards against: a
/// stale keychain item under a different `kSecAttrAccessible` value makes
/// `flutter_secure_storage`'s own existence check miss it, so it falls
/// through to `SecItemAdd`, which then fails with `errSecDuplicateItem`
/// (-25299) because that check *does* match on account/service alone.
class _DuplicateItemOnceStorage extends FlutterSecureStorage {
  _DuplicateItemOnceStorage(this._failingKeys);

  final Set<String> _failingKeys;

  final Map<String, String> written = {};
  final List<String> deletedKeys = [];
  int writeAttempts = 0;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    writeAttempts++;
    if (_failingKeys.contains(key) && !deletedKeys.contains(key)) {
      throw PlatformException(
        code: 'Unexpected security result code',
        message:
            'Code: -25299, Message: The specified item already exists '
            'in the keychain.',
        details: -25299,
      );
    }
    written[key] = value!;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deletedKeys.add(key);
  }
}

class _AlwaysFailsStorage extends FlutterSecureStorage {
  const _AlwaysFailsStorage();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(code: 'some other error', message: 'nope');
  }
}

void main() {
  group('SecureTokenStore write self-healing', () {
    test(
      'writeAccessToken deletes the stale item and retries once on '
      'errSecDuplicateItem (-25299)',
      () async {
        final storage = _DuplicateItemOnceStorage({
          'enjoy_player.access_token',
        });
        final store = SecureTokenStore(storage);

        await store.writeAccessToken('token-123');

        expect(storage.deletedKeys, ['enjoy_player.access_token']);
        expect(storage.writeAttempts, 2);
        expect(storage.written['enjoy_player.access_token'], 'token-123');
      },
    );

    test(
      'writeRefreshToken and writeCachedProfileJson also self-heal',
      () async {
        final storage = _DuplicateItemOnceStorage({
          'enjoy_player.refresh_token',
          'enjoy_player.cached_profile_json',
        });
        final store = SecureTokenStore(storage);

        await store.writeRefreshToken('refresh-123');
        await store.writeCachedProfileJson('{"id":"u1"}');

        expect(storage.written['enjoy_player.refresh_token'], 'refresh-123');
        expect(
          storage.written['enjoy_player.cached_profile_json'],
          '{"id":"u1"}',
        );
      },
    );

    test('rethrows PlatformExceptions unrelated to errSecDuplicateItem', () {
      final store = SecureTokenStore(const _AlwaysFailsStorage());

      expect(
        () => store.writeAccessToken('token-123'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
