import 'package:enjoy_player/data/api/secure_storage_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingStorage extends FlutterSecureStorage {
  _ThrowingStorage(this.error);

  final PlatformException error;
  final List<String> deletedKeys = [];

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
    throw error;
  }
}

class _DuplicateItemOnceStorage extends FlutterSecureStorage {
  _DuplicateItemOnceStorage(this._failingKeys);

  final Set<String> _failingKeys;

  final Map<String, String> written = {};
  final List<String> deletedKeys = [];
  int writeAttempts = 0;
  bool alwaysFail = false;

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
    if (alwaysFail) {
      throw PlatformException(code: 'some other error', message: 'nope');
    }
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

void main() {
  group('keychain status parsing', () {
    test('a missing keychain entitlement reads as already absent', () async {
      final storage = _ThrowingStorage(
        PlatformException(
          code: 'Unexpected security result code',
          message:
              'Code: -34018, Message: A required entitlement is not present.',
          details: -34018,
        ),
      );

      await expectLater(
        deleteSecureStorageKey(
          storage,
          key: 'enjoy_player.cached_profile_json',
        ),
        completes,
      );
      expect(storage.deletedKeys, ['enjoy_player.cached_profile_json']);
    });

    test('the entitlement status is also read from the message', () async {
      final storage = _ThrowingStorage(
        PlatformException(
          code: 'Unexpected security result code',
          message:
              'Code: -34018, Message: A required entitlement is not present.',
        ),
      );

      await expectLater(deleteSecureStorageKey(storage, key: 'k'), completes);
    });

    test('other keychain failures still surface', () async {
      final storage = _ThrowingStorage(
        PlatformException(
          code: 'Unexpected security result code',
          message:
              'Code: -25299, Message: The specified item already exists '
              'in the keychain.',
          details: -25299,
        ),
      );

      await expectLater(
        deleteSecureStorageKey(storage, key: 'k'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('the entitlement status is matched on its own', () {
      expect(
        isMissingKeychainEntitlement(
          PlatformException(code: 'x', message: 'y', details: -34018),
        ),
        isTrue,
      );
      expect(
        isMissingKeychainEntitlement(
          PlatformException(code: 'x', message: 'y', details: -25300),
        ),
        isFalse,
      );
    });

    test('the duplicate-item status is matched on its own', () {
      expect(
        isDuplicateKeychainItem(
          PlatformException(code: 'x', message: 'y', details: -25299),
        ),
        isTrue,
      );
      expect(
        isDuplicateKeychainItem(
          PlatformException(code: 'x', message: 'y', details: -34018),
        ),
        isFalse,
      );
    });
  });

  group('healing write', () {
    test(
      'a duplicate keychain item is deleted and the write is retried',
      () async {
        final storage = _DuplicateItemOnceStorage({
          'enjoy_player.access_token',
        });

        await writeSecureStorageKey(
          storage,
          key: 'enjoy_player.access_token',
          value: 'token-123',
        );

        expect(storage.deletedKeys, ['enjoy_player.access_token']);
        expect(storage.writeAttempts, 2);
        expect(storage.written['enjoy_player.access_token'], 'token-123');
      },
    );

    test('failures unrelated to a duplicate item still surface', () async {
      final storage = _DuplicateItemOnceStorage({'enjoy_player.access_token'})
        ..alwaysFail = true;

      await expectLater(
        writeSecureStorageKey(
          storage,
          key: 'enjoy_player.access_token',
          value: 'token-123',
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
