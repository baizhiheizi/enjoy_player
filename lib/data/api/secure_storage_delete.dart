/// Delete semantics shared by every secure-storage store.
library;

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const int kErrSecMissingEntitlement = -34018;

/// Whether a keychain failure reports a missing entitlement.
bool isMissingKeychainEntitlement(PlatformException error) =>
    error.details == kErrSecMissingEntitlement ||
    (error.message?.contains('$kErrSecMissingEntitlement') ?? false);

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
