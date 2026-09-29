import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
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
      expect(
        DiagnosticLogConfig.isAllowlistedLogger('YouTubeSomethingCustom'),
        isTrue,
      );
    });

    test('rejects non-allowlisted loggers', () {
      expect(DiagnosticLogConfig.isAllowlistedLogger('library'), isFalse);
      expect(DiagnosticLogConfig.isAllowlistedLogger('player'), isFalse);
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
