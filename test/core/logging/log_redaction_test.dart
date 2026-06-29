import 'package:enjoy_player/core/logging/log_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactLogLine', () {
    test('redacts Authorization header', () {
      expect(
        redactLogLine('request Authorization: Bearer secret-token-abc'),
        'request Authorization: [REDACTED]',
      );
    });

    test('redacts bearer tokens in message body', () {
      expect(
        redactLogLine('failed with Bearer eyJhbGciOiJIUzI1NiJ9.payload'),
        'failed with Bearer [REDACTED]',
      );
    });

    test('redacts cookie-like pairs', () {
      expect(
        redactLogLine('cookie SID=abc123; SAPISID=xyz789'),
        'cookie SID=[REDACTED]; SAPISID=[REDACTED]',
      );
    });

    test('shortens long Windows absolute paths', () {
      const path =
          r'C:\Users\alice\AppData\Roaming\Enjoy\Enjoy Player\logs\enjoy-player.log';
      final out = redactLogLine('wrote to $path');
      expect(out, contains('.../enjoy-player.log'));
      expect(out, isNot(contains(r'C:\Users\alice')));
    });

    test('shortens long POSIX absolute paths', () {
      const path =
          '/Users/alice/Library/Application Support/Enjoy/logs/out.log';
      final out = redactLogLine('path=$path');
      expect(out, contains('.../out.log'));
      expect(out, isNot(contains('/Users/alice/Library')));
    });
  });
}
