import 'dart:async';

import 'package:drift/drift.dart';

/// Suite-wide test bootstrap (picked up automatically by `flutter test`).
///
/// Matches [lib/main.dart]: device-global + per-user [AppDatabase] instances
/// (and isolated in-memory DBs per test) are intentional. Drift's runtime
/// "multiple databases" check is a false positive for that architecture.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
