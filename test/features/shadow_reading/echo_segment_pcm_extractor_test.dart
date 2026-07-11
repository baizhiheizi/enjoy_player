import 'dart:io';
import 'dart:typed_data';

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

  group('extractMonoFloat32SegmentToTempFile', () {
    test('throws invalidInput for non-positive duration', () async {
      await expectLater(
        extractMonoFloat32SegmentToTempFile(
          mediaFilePath: '/tmp/media.mp3',
          startSec: 0,
          durationSec: 0,
        ),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            EchoPcmFailureReason.invalidInput,
          ),
        ),
      );
      await expectLater(
        extractMonoFloat32SegmentToTempFile(
          mediaFilePath: '/tmp/media.mp3',
          startSec: 1,
          durationSec: -1,
        ),
        throwsA(isA<EchoPcmExtractionException>()),
      );
    });

    test('throws invalidInput for blank media path', () async {
      await expectLater(
        extractMonoFloat32SegmentToTempFile(
          mediaFilePath: '  ',
          startSec: 0,
          durationSec: 1,
        ),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            EchoPcmFailureReason.invalidInput,
          ),
        ),
      );
    });

    test('throws fileMissing when media file is absent', () async {
      await expectLater(
        extractMonoFloat32SegmentToTempFile(
          mediaFilePath: '${tempRoot.path}/nope.mp3',
          startSec: 0,
          durationSec: 1,
        ),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            EchoPcmFailureReason.fileMissing,
          ),
        ),
      );
    });
  });

  group('extractEntireFileToTempF32', () {
    test('throws invalidInput for blank media path', () async {
      await expectLater(
        extractEntireFileToTempF32(''),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            EchoPcmFailureReason.invalidInput,
          ),
        ),
      );
      await expectLater(
        extractEntireFileToTempF32('   '),
        throwsA(isA<EchoPcmExtractionException>()),
      );
    });

    test('throws fileMissing when media file is missing', () async {
      await expectLater(
        extractEntireFileToTempF32('${tempRoot.path}/nonexistent.wav'),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            EchoPcmFailureReason.fileMissing,
          ),
        ),
      );
    });
  });

  group('FFmpeg availability', () {
    test(
      'surfaces a ffmpegMissing error instead of a silent null when FFmpegKit '
      'is not registered (e.g. flutter test)',
      () async {
        // Provide a real (but non-empty) input file so the guard clauses pass
        // and execution reaches the FFmpeg/FFmpegKit invocation.
        final media = File('${tempRoot.path}/dummy.mp3')
          ..writeAsStringSync('not real media');
        await expectLater(
          extractMonoFloat32SegmentToTempFile(
            mediaFilePath: media.path,
            startSec: 0,
            durationSec: 0.5,
          ),
          throwsA(
            isA<EchoPcmExtractionException>().having(
              (e) => e.reason,
              'reason',
              // On non-Windows hosts without the FFmpegKit platform impl
              // (flutter test), the failure is surfaced as ffmpegMissing.
              anyOf(
                EchoPcmFailureReason.ffmpegMissing,
                EchoPcmFailureReason.ffmpegFailed,
              ),
            ),
          ),
        );
      },
    );
  });

  group('decodeF32leBytes', () {
    test('decodes little-endian f32 bytes without extra copy', () {
      final bd = ByteData(8);
      bd.setFloat32(0, 0.5, Endian.little);
      bd.setFloat32(4, -0.25, Endian.little);
      final samples = decodeF32leBytes(bd.buffer.asUint8List());
      expect(samples, [0.5, -0.25]);
    });

    test('returns empty for too-short input', () {
      expect(decodeF32leBytes(Uint8List(2)), isEmpty);
    });
  });
}
