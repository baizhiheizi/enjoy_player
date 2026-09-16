import 'dart:typed_data';

import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/share_poster/application/practice_poster_echo_frame_capture.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_player_engine.dart';

PlaybackSession _videoSession({required String mediaId}) {
  final now = DateTime.utc(2026, 1, 1);
  return PlaybackSession(
    mediaId: mediaId,
    dexieTargetType: 'Video',
    mediaType: 'video',
    mediaTitle: 'Title',
    durationSeconds: 60,
    currentTimeSeconds: 10,
    currentSegmentIndex: 0,
    language: 'en',
    startedAt: now,
    lastActiveAt: now,
  );
}

void main() {
  group('capturePracticePosterEchoFrame', () {
    test('returns null when echo is inactive', () async {
      final fake = FakePlayerEngine();
      fake.screenshotReturnValue = Uint8List.fromList(const [1, 2, 3]);

      final bytes = await capturePracticePosterEchoFrame(
        capture: fake,
        echo: EchoState.inactive,
        session: _videoSession(mediaId: 'm1'),
        mediaId: 'm1',
      );

      expect(bytes, isNull);
      expect(fake.screenshotCalls, 0);
    });

    test('returns null for audio session', () async {
      final fake = FakePlayerEngine();
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 0,
        startTimeSeconds: 0,
        endTimeSeconds: 2,
      );
      final now = DateTime.utc(2026, 1, 1);

      final bytes = await capturePracticePosterEchoFrame(
        capture: fake,
        echo: echo,
        session: PlaybackSession(
          mediaId: 'm1',
          dexieTargetType: 'Audio',
          mediaType: 'audio',
          mediaTitle: 'Title',
          durationSeconds: 60,
          currentTimeSeconds: 10,
          currentSegmentIndex: 0,
          language: 'en',
          startedAt: now,
          lastActiveAt: now,
        ),
        mediaId: 'm1',
      );

      expect(bytes, isNull);
      expect(fake.screenshotCalls, 0);
    });

    test('captures jpeg from video engine when echo is active', () async {
      final fake = FakePlayerEngine();
      fake.screenshotReturnValue = Uint8List.fromList(const [9, 8, 7]);
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 1,
        startTimeSeconds: 0,
        endTimeSeconds: 2,
      );

      final bytes = await capturePracticePosterEchoFrame(
        capture: fake,
        echo: echo,
        session: _videoSession(mediaId: 'm1'),
        mediaId: 'm1',
      );

      expect(bytes, fake.screenshotReturnValue);
      expect(fake.screenshotCalls, 1);
    });

    test('returns null without capturing when engine has no poster surface '
        '(e.g. YouTube WebView, to avoid a black frame)', () async {
      final fake = FakePlayerEngine()..supportsVideoPosterCaptureValue = false;
      fake.screenshotReturnValue = Uint8List.fromList(const [9, 8, 7]);
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 1,
        startTimeSeconds: 0,
        endTimeSeconds: 2,
      );

      final bytes = await capturePracticePosterEchoFrame(
        capture: fake,
        echo: echo,
        session: _videoSession(mediaId: 'm1'),
        mediaId: 'm1',
      );

      expect(bytes, isNull);
      expect(fake.screenshotCalls, 0);
    });
  });
}
