import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/data/api/secure_storage_options.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage();

  final Map<String, String> values = {};
  final List<String> deletedKeys = [];

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
    values[key] = value!;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

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
    values.remove(key);
  }
}

class _MissingEntitlementStorage extends FlutterSecureStorage {
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
    throw PlatformException(
      code: 'Unexpected security result code',
      message: 'Code: -34018, Message: A required entitlement is not present.',
      details: -34018,
    );
  }
}

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

void main() {
  group('BYOK secret store', () {
    test('the provider shares the app-wide secure-storage backend', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = container.read(byokSecretStoreProvider) as ByokSecretStore;

      expect(store.storage, same(secureStorageBackend));
    });

    test('macOS uses the legacy keychain, not the data-protection one', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = container.read(byokSecretStoreProvider) as ByokSecretStore;

      expect(store.storage.mOptions, same(kMacOsSecureStorageOptions));
      final macOsOptions = store.storage.mOptions as MacOsOptions;
      expect(macOsOptions.usesDataProtectionKeychain, isFalse);
    });

    test('write, read, and delete round-trip a provider key', () async {
      final storage = _MemoryStorage();
      final store = ByokSecretStore(storage);

      await store.writeApiKey(ModalityKind.asr, 'sk-asr');
      expect(await store.readApiKey(ModalityKind.asr), 'sk-asr');
      expect(await store.hasApiKey(ModalityKind.asr), isTrue);

      await store.deleteApiKey(ModalityKind.asr);
      expect(await store.readApiKey(ModalityKind.asr), isNull);
      expect(await store.hasApiKey(ModalityKind.asr), isFalse);
      expect(storage.deletedKeys, ['enjoy_player.byok.asr.api_key']);
    });

    test('delete tolerates a missing keychain entitlement', () async {
      final store = ByokSecretStore(_MissingEntitlementStorage());

      await expectLater(store.deleteApiKey(ModalityKind.llm), completes);
    });

    test('replacing a key heals a stale keychain item', () async {
      final storage = _DuplicateItemOnceStorage({
        'enjoy_player.byok.asr.api_key',
      });
      final store = ByokSecretStore(storage);

      await store.writeApiKey(ModalityKind.asr, 'sk-asr');

      expect(storage.deletedKeys, ['enjoy_player.byok.asr.api_key']);
      expect(storage.writeAttempts, 2);
      expect(storage.written['enjoy_player.byok.asr.api_key'], 'sk-asr');
    });
  });
}
