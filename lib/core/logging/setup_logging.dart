/// Attaches [Logger.root] output to Flutter DevTools / debug console.
///
/// Mirrors [Level.INFO] and higher (and any record carrying [LogRecord.error] /
/// [LogRecord.stackTrace]) to [debugPrint] so `flutter run` and plain terminals
/// show the same lines as DevTools. In debug mode, [Level.FINE] and below are
/// also mirrored to [debugPrint].
///
/// All builds also persist redacted records to a rotating file when supported.
/// The session banner ([writeDiagnosticSessionHeader]) is enqueued before any
/// other record: records that arrive while it is still being composed are
/// buffered and flushed after it, so the banner stays the first line of the
/// session in the log file even though startup no longer awaits it.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'diagnostic_log_config.dart';
import 'diagnostic_session_header.dart';
import 'log_file_sink.dart';

bool _loggingHooked = false;
StreamSubscription<LogRecord>? _logSubscription;
Future<void>? _sessionBannerFuture;
bool _sessionBannerReady = false;
final List<LogRecord> _recordsBeforeSessionBanner = <LogRecord>[];

/// Resets the [Logger.root] listener so a subsequent [setupAppLogging] call
/// re-attaches logging. Safe to call even when logging was never initialized.
///
/// Tests **must** call this between test runs (typically in [tearDown]) because
/// [Logger.root], [LogFileSink._instance], and the session-banner state are
/// process-global.
@visibleForTesting
Future<void> debugResetAppLogging() async {
  await _logSubscription?.cancel();
  _logSubscription = null;
  _loggingHooked = false;
  _sessionBannerFuture = null;
  _sessionBannerGeneration++;
  _sessionBannerReady = false;
  _recordsBeforeSessionBanner.clear();
  DiagnosticLogConfig.verboseEnabled = false;
}

/// The in-flight session banner write, or null when none is pending.
@visibleForTesting
Future<void>? get debugSessionBannerFuture => _sessionBannerFuture;

/// Call once after [WidgetsFlutterBinding.ensureInitialized].
///
/// Never blocks the caller on the banner: it returns once the sink is ready
/// and the root listener is attached; the banner write continues in the
/// background and buffers early records until it lands.
Future<void> setupAppLogging() async {
  if (_loggingHooked) return;
  _loggingHooked = true;

  await LogFileSink.ensureInitialized();
  unawaited(DiagnosticLogConfig.loadFromDeviceGlobalSettings());
  _scheduleSessionBanner();

  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  _logSubscription = Logger.root.onRecord.listen((record) {
    final mirrorToStdout =
        record.level >= Level.INFO ||
        record.error != null ||
        record.stackTrace != null;

    if (DiagnosticLogConfig.shouldPersistRecord(record)) {
      _persistRecord(record);
    }

    if (mirrorToStdout || kDebugMode) {
      final header = '[${record.level.name}] ${record.loggerName}:';
      debugPrint('$header ${record.message}');
      if (record.error != null) {
        debugPrint('$header error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('$header stack:\n${record.stackTrace}');
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

int _sessionBannerGeneration = 0;

void _scheduleSessionBanner() {
  final generation = ++_sessionBannerGeneration;
  _sessionBannerFuture = _writeSessionBanner(generation);
}

Future<void> _writeSessionBanner(int generation) async {
  try {
    await writeDiagnosticSessionHeader();
  } on Object catch (e, st) {
    Logger('logging').warning('session header write failed', e, st);
  }
  if (generation != _sessionBannerGeneration) return;
  _sessionBannerReady = true;
  await _flushRecordsBeforeSessionBanner();
}

void _persistRecord(LogRecord record) {
  if (!_sessionBannerReady) {
    _recordsBeforeSessionBanner.add(record);
    return;
  }
  unawaited(LogFileSink.instance?.writeRecord(record));
}

Future<void> _flushRecordsBeforeSessionBanner() async {
  final sink = LogFileSink.instance;
  if (sink == null) {
    _recordsBeforeSessionBanner.clear();
    return;
  }
  final writes = <Future<void>>[
    for (final record in _recordsBeforeSessionBanner) sink.writeRecord(record),
  ];
  _recordsBeforeSessionBanner.clear();
  await Future.wait(writes);
}
