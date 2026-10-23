/// Keychain status handling shared by every secure-storage store.
library;

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

const int kErrSecDuplicateItem = -25299;
const int kErrSecMissingEntitlement = -34018;

/// Whether a keychain failure reports a specific OSStatus.
bool isKeychainStatus(PlatformException error, int status) =>
    error.details == status || (error.message?.contains('$status') ?? false);

/// Whether a keychain failure reports an item that is already there.
bool isDuplicateKeychainItem(PlatformException error) =>
    isKeychainStatus(error, kErrSecDuplicateItem);

/// Whether a keychain failure reports a missing entitlement.
bool isMissingKeychainEntitlement(PlatformException error) =>
    isKeychainStatus(error, kErrSecMissingEntitlement);

/// Deletes a key, treating a missing keychain entitlement as already absent.
Future<void> deleteSecureStorageKey(
  FlutterSecureStorage storage, {
  required String key,
}) async {
  try {
    await storage.delete(key: key);
  } on PlatformException catch (error) {
    if (!isMissingKeychainEntitlement(error)) rethrow;
  }
}

/// Writes a key, clearing a stale keychain item that blocks the write.
///
/// A leftover item stored under a different accessibility reads as absent
/// while the write still collides, so the item is deleted and the write is
/// retried once.
Future<void> writeSecureStorageKey(
  FlutterSecureStorage storage, {
  required String key,
  required String value,
  Logger? log,
}) async {
  try {
    await storage.write(key: key, value: value);
  } on PlatformException catch (error) {
    if (!isDuplicateKeychainItem(error)) rethrow;
    log?.warning(
      'secure storage write hit a stale keychain item for "$key" '
      '(errSecDuplicateItem); deleting and retrying once',
      error,
    );
    await deleteSecureStorageKey(storage, key: key);
    await storage.write(key: key, value: value);
  }
}
