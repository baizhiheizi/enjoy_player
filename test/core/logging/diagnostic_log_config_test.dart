import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  // DiagnosticLogConfig exposes static state. Tests that mutate it must
  // snapshot and restore the original value to avoid leaking across files.
  final originalVerbose = DiagnosticLogConfig.verboseEnabled;
  tearDown(() {
    DiagnosticLogConfig.setVerboseEnabled(originalVerbose);
  });

  LogRecord recordAt(
    Level level, {
    String name = 'test',
    Object? error,
    StackTrace? stackTrace,
  }) {
    return LogRecord(level, 'msg', name, error, stackTrace);
  }

  group('isAllowlistedLogger', () {
    test('matches allowlisted logger names', () {
      for (final name in kDiagnosticVerboseLoggerNames) {
        expect(
          DiagnosticLogConfig.isAllowlistedLogger(name),
          isTrue,
          reason: '$name should be allowlisted',
        );
      }
    });

    test('matches any YouTube-prefixed logger', () {
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubePlayerEngine'),
        isTrue,
      );
      expect(DiagnosticLogConfig.isAllowlistedLogger('YouTubeWebView'), isTrue);
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubeWebViewController'),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubeWebViewEvents'),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubeWebViewNavigation'),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubeWebViewPollLoop'),
        isTrue,
      );
      // Not in the allowlist directly, but the prefix rule covers it.
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubeSomethingCustom'),
        isTrue,
      );
    });

    test('rejects non-allowlisted loggers', () {
      expect(DiagnosticLogConfig.isAllowlistedLogger('library'), isFalse);
      expect(DiagnosticLogConfig.isAllowlistedLogger('player'), isFalse);
      // Case-sensitive: lowercase 'youtube' prefix is not allowlisted.
      expect(DiagnosticLogConfig.isAllowlistedLogger('youtubePlayer'), isFalse);
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YoutubeWebViewEvents'),
        isFalse,
      );
    });
  });

  group('shouldPersistRecord (verbose disabled)', () {
    setUp(() {
      DiagnosticLogConfig.setVerboseEnabled(false);
    });

    test('persists INFO and above regardless of logger', () {
      expect(
        DiagnosticLogConfig.shouldPersistRecord(recordAt(Level.INFO)),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.shouldPersistRecord(recordAt(Level.WARNING)),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.shouldPersistRecord(recordAt(Level.SEVERE)),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.shouldPersistRecord(recordAt(Level.SHOUT)),
        isTrue,
      );
    });

    test('persists records that carry an error even at FINE level', () {
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.FINE, error: StateError('boom')),
        ),
        isTrue,
      );
    });

    test('persists records that carry a stackTrace even at FINE level', () {
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.FINE, stackTrace: StackTrace.current),
        ),
        isTrue,
      );
    });

    test('drops FINE records from non-allowlisted loggers', () {
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.FINE, name: 'library'),
        ),
        isFalse,
      );
    });

    test('drops FINE records from allowlisted loggers when verbose is off', () {
      // Allowlisted logger + FINE + no error/stack -> only persisted if verbose.
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.FINE, name: 'sync'),
        ),
        isFalse,
      );
    });
  });

  group('shouldPersistRecord (verbose enabled)', () {
    setUp(() {
      DiagnosticLogConfig.setVerboseEnabled(true);
    });

    test('persists FINE+ records from allowlisted loggers', () {
      // FINE (500), CONFIG (700), INFO (800) all clear the FINE threshold.
      // FINER (400) is below FINE and should NOT be persisted by this path.
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.FINE, name: 'sync'),
        ),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.CONFIG, name: 'api'),
        ),
        isTrue,
      );
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.INFO, name: 'auth'),
        ),
        isTrue,
      );
    });

    test('persists FINE+ records from any YouTube-prefixed logger', () {
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.CONFIG, name: 'YouTubeCustom'),
        ),
        isTrue,
      );
    });

    test('still persists INFO+ records from any logger', () {
      expect(
        DiagnosticLogConfig.shouldPersistRecord(
          recordAt(Level.INFO, name: 'player'),
        ),
        isTrue,
      );
    });

    test(
      'drops FINE records from non-allowlisted loggers even when verbose',
      () {
        expect(
          DiagnosticLogConfig.shouldPersistRecord(
            recordAt(Level.FINE, name: 'player'),
          ),
          isFalse,
        );
        // FINER is below the FINE threshold and not in the INFO band: dropped
        // even for allowlisted loggers (verified by FINER+non-allowlist combo).
        expect(
          DiagnosticLogConfig.shouldPersistRecord(
            recordAt(Level.FINER, name: 'library'),
          ),
          isFalse,
        );
      },
    );
  });
}
