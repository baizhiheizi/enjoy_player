/// Plugin-channel bootstrap for the Drift background isolate.
///
/// `driftDatabase()` opens SQLite through `NativeDatabase.createBackgroundConnection`
/// with `isolateSetup: null`, so the isolate that runs `onUpgrade` has no
/// `BinaryMessenger`. Platform-channel calls made there do not merely return a
/// default — they throw, and [AppDatabase]'s migration code swallows the
/// failure. `migration_backup.dart` resolving `getApplicationSupportDirectory()`
/// on that isolate therefore failed silently, skipping the pre-v6 JSON backup
/// immediately before `_dropLegacyTables` destroyed the legacy schema.
///
/// Passing [driftNativeOptions] installs a [BackgroundIsolateBinaryMessenger]
/// before the database opens, so migrations can reach `path_provider` and the
/// backup lands.
library;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';

/// Installs a background-isolate binary messenger bound to [rootToken].
///
/// Idempotent: `ensureInitialized` is a no-op once a messenger is installed, so
/// drift calling this on both the worker and read-pool isolates is safe.
void initializeDriftBackgroundIsolate(RootIsolateToken rootToken) {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
}

/// Native executor options that give the Drift background isolate its
/// plugin-channel messenger.
///
/// [rootToken] is captured by the sent closure, so it must be read on the main
/// isolate — the spawned isolate cannot obtain one for itself.
DriftNativeOptions driftNativeOptions(RootIsolateToken rootToken) {
  return DriftNativeOptions(
    isolateSetup: () => initializeDriftBackgroundIsolate(rootToken),
  );
}

/// [driftNativeOptions] for the current binding, or `null` when no root token
/// exists yet (pre-binding construction) and the executor keeps drift's
/// channel-less default.
DriftNativeOptions? defaultDriftNativeOptions() {
  final rootToken = ServicesBinding.rootIsolateToken;
  return rootToken == null ? null : driftNativeOptions(rootToken);
}
