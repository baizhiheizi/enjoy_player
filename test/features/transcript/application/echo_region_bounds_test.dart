import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/echo_region_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EchoState echo({
    required bool active,
    required int start,
    required int end,
    double startTime = 0,
    double endTime = 1,
  }) => EchoState(
    active: active,
    startLineIndex: start,
    endLineIndex: end,
    startTimeSeconds: startTime,
    endTimeSeconds: endTime,
  );

  group('activeEchoForTranscript', () {
    test('returns null when the echo is off', () {
      expect(
        activeEchoForTranscript(echo(active: false, start: 0, end: 3), 10),
        isNull,
      );
    });

    test('returns null when the transcript has no lines', () {
      expect(
        activeEchoForTranscript(echo(active: true, start: 0, end: 3), 0),
        isNull,
      );
      expect(
        activeEchoForTranscript(echo(active: true, start: 0, end: 3), -1),
        isNull,
      );
    });

    test('returns null when the segment starts past the last line', () {
      expect(
        activeEchoForTranscript(echo(active: true, start: 10, end: 12), 10),
        isNull,
      );
    });

    test('returns null when the segment ends before the first line', () {
      expect(
        activeEchoForTranscript(echo(active: true, start: -5, end: -1), 10),
        isNull,
      );
    });

    test('returns null for an inverted segment', () {
      expect(
        activeEchoForTranscript(echo(active: true, start: 5, end: 2), 10),
        isNull,
      );
    });

    test('returns the original echo when it already fits the list', () {
      final state = echo(active: true, start: 2, end: 5);
      expect(activeEchoForTranscript(state, 10), same(state));
    });

    test('clamps a start below the first line', () {
      final result = activeEchoForTranscript(
        echo(active: true, start: -3, end: 4),
        10,
      );
      expect(result, isNotNull);
      expect(result!.startLineIndex, 0);
      expect(result.endLineIndex, 4);
    });

    test('clamps an end past the last line', () {
      final result = activeEchoForTranscript(
        echo(active: true, start: 3, end: 40),
        10,
      );
      expect(result!.startLineIndex, 3);
      expect(result.endLineIndex, 9);
    });

    test('clamps both ends', () {
      final result = activeEchoForTranscript(
        echo(active: true, start: -2, end: 99),
        5,
      );
      expect(result!.startLineIndex, 0);
      expect(result.endLineIndex, 4);
    });

    test('keeps the echo active and its timing after clamping', () {
      final result = activeEchoForTranscript(
        echo(active: true, start: -2, end: 99, startTime: 1.5, endTime: 9.25),
        5,
      );
      expect(result!.active, isTrue);
      expect(result.startTimeSeconds, 1.5);
      expect(result.endTimeSeconds, 9.25);
    });

    test('treats a single-line transcript as one addressable line', () {
      final result = activeEchoForTranscript(
        echo(active: true, start: 0, end: 0),
        1,
      );
      expect(result!.startLineIndex, 0);
      expect(result.endLineIndex, 0);
    });
  });
}
