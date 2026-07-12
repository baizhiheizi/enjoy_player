import 'package:enjoy_player/features/player/domain/echo_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeEchoWindow', () {
    test('returns null when inactive', () {
      expect(
        normalizeEchoWindow((
          active: false,
          startTimeSeconds: 1,
          endTimeSeconds: 2,
          durationSeconds: 10.0,
        )),
        isNull,
      );
    });

    test('clamps to duration', () {
      final w = normalizeEchoWindow((
        active: true,
        startTimeSeconds: 0,
        endTimeSeconds: 100,
        durationSeconds: 10.0,
      ));
      expect(w!.start, 0);
      expect(w.end, 10.0);
    });
  });

  test('clampSeekTimeToEchoWindow stays before end', () {
    final w = (start: 1.0, end: 3.0);
    final t = clampSeekTimeToEchoWindow(10.0, w);
    expect(t, lessThan(w.end));
    expect(t, greaterThanOrEqualTo(w.start));
  });

  test('decideEchoPlaybackTime pauses-and-rewinds near end', () {
    final w = (start: 1.0, end: 2.0);
    final d = decideEchoPlaybackTime(2.0, w);
    expect(d, isA<EchoPauseAndRewind>());
    expect((d as EchoPauseAndRewind).timeSeconds, w.start);
  });

  test('decideEchoPlaybackTime clamps before start-guard', () {
    final w = (start: 1.0, end: 2.0);
    final d = decideEchoPlaybackTime(0.5, w);
    expect(d, isA<EchoClamp>());
    expect((d as EchoClamp).timeSeconds, w.start);
  });

  test('decideEchoPlaybackTime clamps NaN to window start', () {
    final w = (start: 1.0, end: 2.0);
    final d = decideEchoPlaybackTime(double.nan, w);
    expect(d, isA<EchoClamp>());
    expect((d as EchoClamp).timeSeconds, w.start);
  });

  test('decideEchoPlaybackTime is ok inside window', () {
    final w = (start: 1.0, end: 2.0);
    final d = decideEchoPlaybackTime(1.5, w);
    expect(d, isA<EchoOk>());
  });
}
