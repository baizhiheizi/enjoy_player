import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDurationHms', () {
    test('zero renders as 00:00', () {
      expect(formatDurationHms(Duration.zero), '00:00');
    });

    test('under one minute pads seconds', () {
      expect(formatDurationHms(const Duration(seconds: 5)), '00:05');
      expect(formatDurationHms(const Duration(seconds: 59)), '00:59');
    });

    test('minutes and seconds render with colon', () {
      expect(
        formatDurationHms(const Duration(minutes: 1, seconds: 2)),
        '01:02',
      );
      expect(
        formatDurationHms(const Duration(minutes: 15, seconds: 30)),
        '15:30',
      );
    });

    test('minutes wrap past 60 by carrying into hours', () {
      // Duration stores minutes up to 59; the implementation uses
      // inMinutes.remainder(60) so 75 minutes becomes 01:15:00.
      expect(formatDurationHms(const Duration(minutes: 75)), '01:15:00');
    });

    test('exactly one hour renders as 01:00:00 (zero-padded)', () {
      // Hours are zero-padded to width 2 by [formatDurationHms] — the
      // function never emits single-digit hours.
      expect(formatDurationHms(const Duration(hours: 1)), '01:00:00');
    });

    test('hours, minutes, and seconds are zero-padded', () {
      expect(
        formatDurationHms(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '02:03:04',
      );
    });

    test('sub-second durations round down to 00:00', () {
      expect(formatDurationHms(const Duration(milliseconds: 500)), '00:00');
    });

    test('very large duration still formats correctly', () {
      expect(
        formatDurationHms(const Duration(hours: 99, minutes: 59, seconds: 59)),
        '99:59:59',
      );
    });
  });

  group('formatDuration', () {
    test('behaves as an alias of formatDurationHms', () {
      const d = Duration(minutes: 12, seconds: 34);
      expect(formatDuration(d), formatDurationHms(d));
      expect(formatDuration(d), '12:34');
    });
  });

  group('formatPracticeDurationMs', () {
    test('zero and negative milliseconds render as 0m', () {
      expect(formatPracticeDurationMs(0), '0m');
      expect(formatPracticeDurationMs(-1), '0m');
      expect(formatPracticeDurationMs(-1000), '0m');
    });

    test('sub-second renders as 0s', () {
      expect(formatPracticeDurationMs(500), '0s');
    });

    test('seconds only with no minutes', () {
      expect(formatPracticeDurationMs(1000), '1s');
      expect(formatPracticeDurationMs(45 * 1000), '45s');
    });

    test('minutes and seconds combined', () {
      expect(formatPracticeDurationMs(15 * 60 * 1000 + 30 * 1000), '15m 30s');
      expect(formatPracticeDurationMs(60 * 1000), '1m 0s');
    });

    test('hours wrap minutes remainder', () {
      expect(
        formatPracticeDurationMs(2 * 60 * 60 * 1000 + 5 * 60 * 1000),
        '2h 5m',
      );
    });

    test('hours plus seconds drop the zero-second tail', () {
      // 1 hour exactly: minutes=0 after mod → falls to the hours branch
      // (which already excludes the trailing 0s), so the output is `1h 0m`.
      expect(formatPracticeDurationMs(60 * 60 * 1000), '1h 0m');
    });
  });
}
