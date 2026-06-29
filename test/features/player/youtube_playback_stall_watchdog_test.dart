import 'package:enjoy_player/features/player/application/engines/youtube/youtube_playback_stall_watchdog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubePlaybackStallWatchdog', () {
    test(
      'fires onStall after timeout when first playing never arrives',
      () async {
        final stalled = <String>[];
        final watchdog = YoutubePlaybackStallWatchdog(
          timeout: const Duration(milliseconds: 20),
          onStall: stalled.add,
        );

        watchdog.onLoadStop('abc12345678');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(stalled, ['abc12345678']);
      },
    );

    test('does not fire when first playing arrives in time', () async {
      final stalled = <String>[];
      final watchdog = YoutubePlaybackStallWatchdog(
        timeout: const Duration(milliseconds: 50),
        onStall: stalled.add,
      );

      watchdog.onLoadStop('abc12345678');
      watchdog.onFirstPlaying();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(stalled, isEmpty);
    });

    test('cancel clears pending stall', () async {
      final stalled = <String>[];
      final watchdog = YoutubePlaybackStallWatchdog(
        timeout: const Duration(milliseconds: 20),
        onStall: stalled.add,
      );

      watchdog.onLoadStop('abc12345678');
      watchdog.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(stalled, isEmpty);
    });

    test('new load_stop resets previous timer', () async {
      final stalled = <String>[];
      final watchdog = YoutubePlaybackStallWatchdog(
        timeout: const Duration(milliseconds: 30),
        onStall: stalled.add,
      );

      watchdog.onLoadStop('first-video');
      await Future<void>.delayed(const Duration(milliseconds: 15));
      watchdog.onLoadStop('second-video');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(stalled, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(stalled, ['second-video']);
    });
  });
}
