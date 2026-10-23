import 'package:enjoy_player/data/api/secure_storage_delete.dart';
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

void main() {
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
      deleteSecureStorageKey(storage, key: 'enjoy_player.cached_profile_json'),
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
}
