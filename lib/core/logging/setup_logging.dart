/// Attaches [Logger.root] output to Flutter DevTools / debug console.
///
/// Mirrors [Level.INFO] and higher (and any record carrying [LogRecord.error] /
/// [LogRecord.stackTrace]) to [debugPrint] so `flutter run` and plain terminals
/// show the same lines as DevTools. In debug mode, [Level.FINE] and below are
/// also mirrored to [debugPrint].
///
/// All builds also persist redacted records to a rotating file when supported.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'diagnostic_log_config.dart';
import 'log_file_sink.dart';

bool _loggingHooked = false;

/// Call once after [WidgetsFlutterBinding.ensureInitialized].
///
/// Call [DiagnosticLogConfig.loadFromGuestSettings] before this when possible.
Future<void> setupAppLogging() async {
  if (_loggingHooked) return;
  _loggingHooked = true;

  await LogFileSink.ensureInitialized();

  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    final mirrorToStdout =
        record.level >= Level.INFO ||
        record.error != null ||
        record.stackTrace != null;

    if (DiagnosticLogConfig.shouldPersistRecord(record)) {
      unawaited(LogFileSink.instance?.writeRecord(record));
    }

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
