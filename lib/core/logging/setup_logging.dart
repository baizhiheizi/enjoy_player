/// Attaches [Logger.root] output to Flutter DevTools / debug console.
///
/// In debug, also mirrors to [debugPrint] so messages appear in the same
/// terminal as `flutter run` (many IDEs do not show [developer.log] there).
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Call once after [WidgetsFlutterBinding.ensureInitialized].
void setupAppLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      final line =
          '[${record.level.name}] ${record.loggerName}: ${record.message}';
      debugPrint(line);
      if (record.error != null) {
        debugPrint('[${record.level.name}] ${record.loggerName} error: '
            '${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('[${record.level.name}] ${record.loggerName} stack:\n'
            '${record.stackTrace}');
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
