import 'package:enjoy_player/features/player/application/engines/youtube/youtube_frame_watchdog.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FrameSample blackFrame() => (mean: 0.01, deviation: 0.005);

  test('fires once after the required consecutive stalled pairs', () {
    fakeAsync((async) {
      var stalledCalls = 0;
      var sampleFlip = false;
      final watchdog = YoutubeFrameWatchdog(
        sampleProvider: () async {
          sampleFlip = !sampleFlip;
          return blackFrame();
        },
        playingCheck: () => true,
        stalledCallback: () => stalledCalls++,
        requiredStalledPairs: 3,
        sleepFn: (delay) => Future<void>.value(),
      )..start();

      async.elapse(const Duration(seconds: 10));

      expect(watchdog.verdictFired, isTrue);
      expect(stalledCalls, 1);
      expect(watchdog.isRunning, isFalse);

      async.elapse(const Duration(seconds: 30));
      expect(stalledCalls, 1, reason: 'the verdict fires exactly once');

      watchdog.dispose();
    });
  });

  test('does not fire while the content moves (drift above threshold)', () {
    fakeAsync((async) {
      var stalledCalls = 0;
      var sampleFlip = false;
      final watchdog = YoutubeFrameWatchdog(
        sampleProvider: () async {
          sampleFlip = !sampleFlip;
          return sampleFlip ? blackFrame() : (mean: 0.01, deviation: 0.05);
        },
        playingCheck: () => true,
        stalledCallback: () => stalledCalls++,
        sleepFn: (delay) => Future<void>.value(),
      )..start();

      async.elapse(const Duration(seconds: 30));

      expect(watchdog.verdictFired, isFalse);
      expect(stalledCalls, 0);
      watchdog.dispose();
    });
  });

  test('does not accumulate while playback is paused', () {
    fakeAsync((async) {
      var stalledCalls = 0;
      var playing = false;
      final watchdog = YoutubeFrameWatchdog(
        sampleProvider: () async => blackFrame(),
        playingCheck: () => playing,
        stalledCallback: () => stalledCalls++,
        sleepFn: (delay) => Future<void>.value(),
      )..start();

      async.elapse(const Duration(seconds: 30));
      expect(watchdog.verdictFired, isFalse);

      playing = true;
      async.elapse(const Duration(seconds: 10));
      expect(watchdog.verdictFired, isTrue);
      watchdog.dispose();
    });
  });

  test('does not fire for bright static content (not the stall signature)', () {
    fakeAsync((async) {
      var stalledCalls = 0;
      final watchdog = YoutubeFrameWatchdog(
        sampleProvider: () async => (mean: 0.9, deviation: 0.02),
        playingCheck: () => true,
        stalledCallback: () => stalledCalls++,
        sleepFn: (delay) => Future<void>.value(),
      )..start();

      async.elapse(const Duration(seconds: 30));

      expect(watchdog.verdictFired, isFalse);
      watchdog.dispose();
    });
  });
}
