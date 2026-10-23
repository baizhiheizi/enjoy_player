/// Secure storage for BYOK API keys (device-local, not in Drift).
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/api/secure_storage_guard.dart';
import 'package:enjoy_player/data/api/secure_storage_op_lock.dart';
import 'package:enjoy_player/data/api/secure_storage_options.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';

part 'byok_secret_store.g.dart';

String byokSecretKeyFor(ModalityKind modality) =>
    'enjoy_player.byok.${modality.name}.api_key';

/// BYOK secret persistence (secure storage).
abstract interface class ByokSecretStoreBase {
  Future<void> writeApiKey(ModalityKind modality, String apiKey);
  Future<String?> readApiKey(ModalityKind modality);
  Future<void> deleteApiKey(ModalityKind modality);
  Future<bool> hasApiKey(ModalityKind modality);
}

@Riverpod(keepAlive: true)
ByokSecretStoreBase byokSecretStore(Ref ref) {
  return ByokSecretStore(secureStorageBackend);
}

class ByokSecretStore implements ByokSecretStoreBase {
  ByokSecretStore(this._storage, {SecureStorageOpLock? opLock})
    : _opLock = opLock ?? sharedSecureStorageOpLock;

  final FlutterSecureStorage _storage;
  final SecureStorageOpLock _opLock;

  @visibleForTesting
  FlutterSecureStorage get storage => _storage;

  @override
  Future<void> writeApiKey(ModalityKind modality, String apiKey) => _opLock.run(
    () => writeSecureStorageKey(
      _storage,
      key: byokSecretKeyFor(modality),
      value: apiKey,
    ),
  );

  @override
  Future<String?> readApiKey(ModalityKind modality) =>
      _opLock.run(() => _storage.read(key: byokSecretKeyFor(modality)));

  @override
  Future<void> deleteApiKey(ModalityKind modality) => _opLock.run(
    () => deleteSecureStorageKey(_storage, key: byokSecretKeyFor(modality)),
  );

  @override
  Future<bool> hasApiKey(ModalityKind modality) async {
    final value = await readApiKey(modality);
    return value != null && value.isNotEmpty;
  }
}
