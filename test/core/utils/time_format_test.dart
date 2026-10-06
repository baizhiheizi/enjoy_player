import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDurationHms', () {
    test('zero renders as 0:00', () {
      expect(formatDurationHms(Duration.zero), '0:00');
    });

    test('under one minute pads seconds', () {
      expect(formatDurationHms(const Duration(seconds: 5)), '0:05');
      expect(formatDurationHms(const Duration(seconds: 59)), '0:59');
    });

    test('minutes and seconds render with colon', () {
      expect(formatDurationHms(const Duration(minutes: 1, seconds: 2)), '1:02');
      expect(
        formatDurationHms(const Duration(minutes: 15, seconds: 30)),
        '15:30',
      );
    });

    test('minutes wrap past 60 by carrying into hours', () {
      expect(formatDurationHms(const Duration(minutes: 75)), '1:15:00');
    });

    test('exactly one hour renders as 1:00:00', () {
      expect(formatDurationHms(const Duration(hours: 1)), '1:00:00');
    });

    test('minutes and seconds are zero-padded under hours', () {
      expect(
        formatDurationHms(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2:03:04',
      );
    });

    test('sub-second durations round down to 0:00', () {
      expect(formatDurationHms(const Duration(milliseconds: 500)), '0:00');
    });

    test('very large duration still formats correctly', () {
      expect(
        formatDurationHms(const Duration(hours: 99, minutes: 59, seconds: 59)),
        '99:59:59',
      );
    });
  });

  group('formatDurationHmsMs', () {
    test('matches formatDurationHms for the same millisecond value', () {
      expect(formatDurationHmsMs(0), '0:00');
      expect(formatDurationHmsMs(5 * 1000), '0:05');
      expect(formatDurationHmsMs(75 * 60 * 1000), '1:15:00');
      expect(
        formatDurationHmsMs(2 * 60 * 60 * 1000 + 3 * 60 * 1000 + 4 * 1000),
        formatDurationHms(const Duration(hours: 2, minutes: 3, seconds: 4)),
      );
    });
  });

  group('formatDurationHmsSeconds', () {
    test('matches integer-second Duration formatting', () {
      expect(formatDurationHmsSeconds(0), '0:00');
      expect(formatDurationHmsSeconds(5), '0:05');
      expect(formatDurationHmsSeconds(62), '1:02');
      expect(formatDurationHmsSeconds(3600), '1:00:00');
    });

    test('rounds fractional seconds to the nearest millisecond', () {
      expect(formatDurationHmsSeconds(0.4), '0:00');
      expect(formatDurationHmsSeconds(0.6), '0:00');
      expect(formatDurationHmsSeconds(0.9996), '0:01');
      expect(formatDurationHmsSeconds(1.5), '0:01');
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
      expect(formatPracticeDurationMs(60 * 60 * 1000), '1h 0m');
    });
  });
}
