import 'package:enjoy_player/features/player/application/engines/youtube/youtube_frame_watchdog.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
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

  test('supported only on Linux', () {
    expect(YoutubeFrameWatchdog.supportedOn(TargetPlatform.linux), isTrue);
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        YoutubeFrameWatchdog.supportedOn(platform),
        isFalse,
        reason: '$platform must not start the Linux-only probe',
      );
    }
  });

  test('backs off after healthy pairs instead of sampling forever fast', () {
    fakeAsync((async) {
      var samples = 0;
      final watchdog = YoutubeFrameWatchdog(
        sampleProvider: () async {
          samples++;
          return (mean: 0.9, deviation: 0.02);
        },
        playingCheck: () => true,
        stalledCallback: () {},
        pairInterval: const Duration(milliseconds: 900),
        slowPairInterval: const Duration(seconds: 15),
        healthyPairsBeforeBackoff: 3,
        sleepFn: (delay) => Future<void>.value(),
      )..start();

      async.elapse(const Duration(seconds: 31));

      expect(watchdog.isRunning, isTrue);
      expect(watchdog.verdictFired, isFalse);
      expect(
        samples,
        lessThanOrEqualTo(12),
        reason: 'three fast pairs then ~15 s cadence, not ~34 fast pairs',
      );
      watchdog.dispose();
    });
  });

  test('a stalled pair returns the probe to the fast cadence', () {
    fakeAsync((async) {
      var samples = 0;
      var black = false;
      final watchdog = YoutubeFrameWatchdog(
        sampleProvider: () async {
          samples++;
          return black
              ? (mean: 0.01, deviation: 0.005)
              : (mean: 0.9, deviation: 0.02);
        },
        playingCheck: () => true,
        stalledCallback: () {},
        pairInterval: const Duration(milliseconds: 900),
        slowPairInterval: const Duration(seconds: 15),
        healthyPairsBeforeBackoff: 1,
        sleepFn: (delay) => Future<void>.value(),
      )..start();

      async.elapse(const Duration(seconds: 5));
      final samplesBeforeSlow = samples;
      expect(samplesBeforeSlow, lessThanOrEqualTo(4));

      black = true;
      async.elapse(const Duration(seconds: 16));
      expect(
        samples,
        greaterThan(samplesBeforeSlow),
        reason:
            'a stalled pair must not leave the probe parked at 15 s; '
            'three stalled pairs then fire the verdict',
      );
      expect(watchdog.verdictFired, isTrue);
      watchdog.dispose();
    });
  });
}
