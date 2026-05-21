import 'dart:io';

import 'package:enjoy_player/features/transcript/data/sidecar_subtitle_discovery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('discoverSidecarSubtitleFiles', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('enjoy_sidecar_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('finds basename-matched srt and vtt in same folder', () async {
      final media = File(p.join(tempDir.path, 'movie.mp4'));
      await media.writeAsString('video');
      await File(
        p.join(tempDir.path, 'movie.srt'),
      ).writeAsString('1\n00:00:01,000 --> 00:00:02,000\nHi');
      await File(
        p.join(tempDir.path, 'movie.en.vtt'),
      ).writeAsString('WEBVTT\n');

      final found = discoverSidecarSubtitleFiles(media.uri.toString());
      expect(found, hasLength(2));
      expect(found.map((f) => p.basename(f.path)).toSet(), {
        'movie.srt',
        'movie.en.vtt',
      });
    });

    test('ignores non-matching subtitle files', () async {
      final media = File(p.join(tempDir.path, 'movie.mp4'));
      await media.writeAsString('video');
      await File(p.join(tempDir.path, 'other.srt')).writeAsString('x');

      final found = discoverSidecarSubtitleFiles(media.uri.toString());
      expect(found, isEmpty);
    });
  });
}
