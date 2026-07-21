/// Test utilities for testing logging infrastructure.
///
/// Provides safe setup/teardown of the process-global logging state
/// ([Logger.root], [LogFileSink]) so tests can exercise
/// [setupAppLogging], [LogFileSink], and record-handling logic without
/// state leaking across tests.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:enjoy_player/core/logging/log_file_sink.dart';
import 'package:enjoy_player/core/logging/setup_logging.dart';

/// Manages the lifecycle of global logging state for a test group.
///
/// Call [setUp] before each test to reset state and optionally attach
/// a record collector. Call [tearDown] after each test to restore
/// pristine state.
///
/// ```dart
/// final logging = TestLoggingScope(captureDebugPrint: true);
/// setUp(() => logging.setUp());
/// tearDown(() => logging.tearDown());
///
/// test('collects records', () async {
///   Logger('test').info('hello');
///   expect(logging.records, hasLength(1));
/// });
/// ```
class TestLoggingScope {
  TestLoggingScope({this.captureDebugPrint = false});

  final bool captureDebugPrint;

  /// [LogRecord]s emitted through [Logger.root] while this scope was active.
  final List<LogRecord> records = [];

  /// [debugPrint] lines captured when [captureDebugPrint] is true.
  final List<String> debugPrintLines = [];

  StreamSubscription<LogRecord>? _sub;
  DebugPrintCallback? _savedDebugPrint;

  /// Resets global logging state and begins collecting records.
  Future<void> setUp() async {
    // Wipe any leftover state from a previous test.
    LogFileSink.debugResetInstance();
    await debugResetAppLogging();

    // Collect all log records.
    Logger.root.level = Level.ALL;
    _sub = Logger.root.onRecord.listen(records.add);

    // Capture debugPrint when requested.
    if (captureDebugPrint) {
      _savedDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        debugPrintLines.add(message ?? 'null');
        _savedDebugPrint?.call(message, wrapWidth: wrapWidth);
      };
    }
  }

  /// Cancels the log collector and resets global state.
  Future<void> tearDown() async {
    await _sub?.cancel();
    _sub = null;

    if (_savedDebugPrint != null) {
      debugPrint = _savedDebugPrint!;
      _savedDebugPrint = null;
    }

    LogFileSink.debugResetInstance();
    await debugResetAppLogging();
    records.clear();
    debugPrintLines.clear();
  }

  /// Shortcut: returns records with the given [loggerName].
  List<LogRecord> forLogger(String loggerName) =>
      records.where((r) => r.loggerName == loggerName).toList();

  /// Shortcut: returns records at or above [level].
  List<LogRecord> atOrAbove(Level level) =>
      records.where((r) => r.level >= level).toList();
}
