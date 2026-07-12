import 'package:enjoy_player/core/utils/duration_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParseHmsDuration', () {
    group('SRT format (comma separator)', () {
      test('00:01:23,456', () {
        final d = tryParseHmsDuration('00:01:23,456');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 83456);
        expect(d.inSeconds, 83);
      });

      test('01:23:45,100', () {
        final d = tryParseHmsDuration('01:23:45,100');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 5025100);
      });
    });

    group('VTT format (dot separator)', () {
      test('00:01:23.456', () {
        final d = tryParseHmsDuration('00:01:23.456');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 83456);
      });
    });

    group('ffmpeg format', () {
      test('01:23:45.67', () {
        final d = tryParseHmsDuration('01:23:45.67');
        expect(d, isNotNull);
        expect(d!.inSeconds, 5025);
        expect(d.inMilliseconds, 5025670);
      });

      test('00:00:00.00', () {
        final d = tryParseHmsDuration('00:00:00.00');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 0);
      });
    });

    group('edge cases', () {
      test('no sub-seconds', () {
        final d = tryParseHmsDuration('01:02:03');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 3723000);
      });

      test('H:MM:SS without leading zero', () {
        final d = tryParseHmsDuration('1:02:03.456');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 3723456);
      });

      test('single-digit sub-seconds', () {
        final d = tryParseHmsDuration('00:00:01.5');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 1500);
      });

      test('too many parts', () {
        expect(tryParseHmsDuration('1:2:3:4'), isNull);
      });

      test('invalid numbers', () {
        expect(tryParseHmsDuration('ab:cd:ef'), isNotNull);
        expect(tryParseHmsDuration('ab:cd:ef')!.inMilliseconds, 0);
      });

      test('negative values', () {
        expect(tryParseHmsDuration('-1:00:00'), isNull);
      });

      test('minutes out of range', () {
        expect(tryParseHmsDuration('00:60:00'), isNull);
      });

      test('seconds out of range', () {
        expect(tryParseHmsDuration('00:00:60'), isNull);
      });

      test('empty string', () {
        expect(tryParseHmsDuration(''), isNull);
      });

      test('MM:SS only (no hours)', () {
        final d = tryParseHmsDuration('01:30');
        expect(d, isNotNull);
        expect(d!.inMilliseconds, 90000);
      });
    });
  });
}
