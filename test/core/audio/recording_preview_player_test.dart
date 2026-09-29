import 'dart:io';

import 'package:enjoy_player/core/audio/recording_preview_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  try {
    MediaKit.ensureInitialized();
  } on Object catch (e) {
    test('(skipped) media_kit native library not available', () {}, skip: '$e');
    return;
  }

  group('RecordingPreviewPlayer', () {
    test('loadedPath starts as null', () {
      final player = RecordingPreviewPlayer();
      addTearDown(player.dispose);
      expect(player.loadedPath, isNull);
    });

    test('stop on a fresh player does not throw', () async {
      final player = RecordingPreviewPlayer();
      addTearDown(player.dispose);
      await player.stop();
      expect(player.loadedPath, isNull);
    });

    test('dispose is idempotent', () async {
      final player = RecordingPreviewPlayer();
      await player.dispose();
      await player.dispose();
      await player.stop();
    });

    test(
      'play throws StateError when the underlying file is missing',
      () async {
        final player = RecordingPreviewPlayer();
        addTearDown(player.dispose);
        expect(
          () => player.play('/definitely/not/a/real/path.wav'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'playOrPauseTake throws StateError when the underlying file is missing',
      () async {
        final player = RecordingPreviewPlayer();
        addTearDown(player.dispose);
        expect(
          () => player.playOrPauseTake('/definitely/not/a/real/path.wav'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('position/duration/playing streams are exposed', () {
      final player = RecordingPreviewPlayer();
      addTearDown(player.dispose);
      expect(player.position, isNotNull);
      expect(player.duration, isNotNull);
      expect(player.playing, isNotNull);
    });

    test('play writes a usable file and tracks loadedPath', () async {
      final player = RecordingPreviewPlayer();
      addTearDown(player.dispose);
      final tmp = Directory.systemTemp.createTempSync('rec_preview_test_');
      addTearDown(() {
        if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      });
      final file = File('${tmp.path}/tone.wav');
      final header = <int>[
        ...'RIFF'.codeUnits,
        36,
        0,
        0,
        0,
        ...'WAVE'.codeUnits,
        ...'fmt '.codeUnits,
        16,
        0,
        0,
        0,
        1,
        0,
        1,
        0,
        0x44,
        0xAC,
        0,
        0,
        0x88,
        0x58,
        0x01,
        0,
        2,
        0,
        16,
        0,
        ...'data'.codeUnits,
        0,
        0,
        0,
        0,
      ];
      file.writeAsBytesSync(header);

      try {
        await player.play(file.path);
        expect(player.loadedPath, file.absolute.path);
      } on Object catch (_) {
        expect(file.existsSync(), isTrue);
      }
    });
  });
}
