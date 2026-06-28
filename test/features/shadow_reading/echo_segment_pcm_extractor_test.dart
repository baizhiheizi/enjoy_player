import 'dart:io';

import 'package:enjoy_player/features/shadow_reading/data/echo_segment_pcm_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory tempRoot;

  setUp(() {
    originalPathProvider = PathProviderPlatform.instance;
    tempRoot = Directory.systemTemp.createTempSync('echo_pcm_test');
    PathProviderPlatform.instance = TestPathProvider(tempRoot.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  group('extractMonoFloat32Segment', () {
    test('returns null for non-positive duration', () async {
      expect(
        await extractMonoFloat32Segment(
          mediaFilePath: '/tmp/media.mp3',
          startSec: 0,
          durationSec: 0,
        ),
        isNull,
      );
      expect(
        await extractMonoFloat32Segment(
          mediaFilePath: '/tmp/media.mp3',
          startSec: 1,
          durationSec: -1,
        ),
        isNull,
      );
    });

    test('returns null for blank media path', () async {
      expect(
        await extractMonoFloat32Segment(
          mediaFilePath: '  ',
          startSec: 0,
          durationSec: 1,
        ),
        isNull,
      );
    });
  });

  group('extractEntireFileMonoF32', () {
    test('returns null for blank media path', () async {
      expect(await extractEntireFileMonoF32(''), isNull);
      expect(await extractEntireFileMonoF32('   '), isNull);
    });

    test('returns null when media file is missing', () async {
      expect(
        await extractEntireFileMonoF32('/nonexistent/echo_recording.wav'),
        isNull,
      );
    });
  });
}
