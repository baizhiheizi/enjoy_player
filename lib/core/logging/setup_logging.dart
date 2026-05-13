/// Attaches [Logger.root] output to Flutter DevTools / debug console.
///
/// Mirrors [Level.INFO] and higher (and any record carrying [LogRecord.error] /
/// [LogRecord.stackTrace]) to [debugPrint] so `flutter run` and plain terminals
/// show the same lines as DevTools. In debug mode, [Level.FINE] and below are
/// also mirrored to [debugPrint].
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Call once after [WidgetsFlutterBinding.ensureInitialized].
void setupAppLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Many terminals only show stdout; [developer.log] is easy to miss there.
    // Always mirror INFO+ (and anything already flagged with an error) to
    // [debugPrint] so `flutter run` / CI consoles match DevTools logging.
    final mirrorToStdout =
        record.level >= Level.INFO ||
        record.error != null ||
        record.stackTrace != null;
    if (mirrorToStdout) {
      final line =
          '[${record.level.name}] ${record.loggerName}: ${record.message}';
      debugPrint(line);
      if (record.error != null) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName} error: '
          '${record.error}',
        );
      }
      if (record.stackTrace != null) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName} stack:\n'
          '${record.stackTrace}',
        );
      }
    } else if (kDebugMode) {
      final line =
          '[${record.level.name}] ${record.loggerName}: ${record.message}';
      debugPrint(line);
      if (record.error != null) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName} error: '
          '${record.error}',
        );
      }
      if (record.stackTrace != null) {
        debugPrint(
          '[${record.level.name}] ${record.loggerName} stack:\n'
          '${record.stackTrace}',
        );
      }
    }
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
