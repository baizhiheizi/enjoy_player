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

  test('decideEchoPlaybackTime loops near end', () {
    final w = (start: 1.0, end: 2.0);
    final d = decideEchoPlaybackTime(2.0, w);
    expect(d, isA<EchoLoop>());
    expect((d as EchoLoop).timeSeconds, w.start);
  });
}
