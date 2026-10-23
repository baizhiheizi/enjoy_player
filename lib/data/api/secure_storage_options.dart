/// Platform options and backend shared by every secure-storage store.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Android Keystore v10 defaults: RSA-OAEP key wrapping, AES-GCM payloads.
///
/// Items written by builds that used the deprecated Jetpack Security
/// `encryptedSharedPreferences` are migrated on first read.
const kAndroidSecureStorageOptions = AndroidOptions();

/// iOS items unlock with the first device unlock after boot.
const kIosSecureStorageOptions = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock,
);

/// macOS items live in the legacy keychain, never the data-protection one.
///
/// The data-protection keychain needs a `keychain-access-groups` entitlement
/// that a Developer ID direct-download build cannot carry, so every macOS
/// store reads and writes through the legacy keychain instead.
const kMacOsSecureStorageOptions = MacOsOptions(
  accessibility: KeychainAccessibility.first_unlock,
  usesDataProtectionKeychain: false,
);

/// The keychain/keystore backend every secure-storage store shares.
const secureStorageBackend = FlutterSecureStorage(
  aOptions: kAndroidSecureStorageOptions,
  iOptions: kIosSecureStorageOptions,
  mOptions: kMacOsSecureStorageOptions,
);
