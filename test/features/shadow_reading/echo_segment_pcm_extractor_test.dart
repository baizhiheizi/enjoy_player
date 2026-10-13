import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/features/shadow_reading/data/echo_segment_pcm_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

final bool _ffmpegCliMissing = () {
  try {
    return Process.runSync('ffmpeg', ['-version']).exitCode != 0;
  } on ProcessException {
    return true;
  }
}();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory tempRoot;

  setUp(() {
    originalPathProvider = PathProviderPlatform.instance;
    tempRoot = Directory.systemTemp.createTempSync('echo_pcm_test');
    final provider = TestPathProvider(tempRoot.path);
    Directory(provider.temporaryPath).createSync(recursive: true);
    PathProviderPlatform.instance = provider;
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

  group('FFmpeg CLI hosts (Windows / Linux)', () {
    File writeToneWav(String path, {double seconds = 1.0}) {
      const rate = 16000;
      final n = (rate * seconds).round();
      final data = ByteData(44 + n * 2);
      void ascii(int offset, String text) {
        for (var i = 0; i < text.length; i++) {
          data.setUint8(offset + i, text.codeUnitAt(i));
        }
      }

      ascii(0, 'RIFF');
      data.setUint32(4, 36 + n * 2, Endian.little);
      ascii(8, 'WAVE');
      ascii(12, 'fmt ');
      data.setUint32(16, 16, Endian.little);
      data.setUint16(20, 1, Endian.little);
      data.setUint16(22, 1, Endian.little);
      data.setUint32(24, rate, Endian.little);
      data.setUint32(28, rate * 2, Endian.little);
      data.setUint16(32, 2, Endian.little);
      data.setUint16(34, 16, Endian.little);
      ascii(36, 'data');
      data.setUint32(40, n * 2, Endian.little);
      for (var i = 0; i < n; i++) {
        final v = (math.sin(2 * math.pi * 440 * i / rate) * 12000).round();
        data.setInt16(44 + i * 2, v, Endian.little);
      }
      return File(path)..writeAsBytesSync(data.buffer.asUint8List());
    }

    test(
      'extracts a segment and a whole file through the ffmpeg CLI',
      () async {
        final wav = writeToneWav('${tempRoot.path}/tone.wav');

        final segment = await extractMonoFloat32SegmentToTempFile(
          mediaFilePath: wav.path,
          startSec: 0.25,
          durationSec: 0.5,
        );
        final segmentSamples = decodeF32leBytes(
          File(segment).readAsBytesSync(),
        );
        expect(
          segmentSamples.length,
          closeTo(kEchoPcmSampleRate * 0.5, kEchoPcmSampleRate * 0.02),
        );
        expect(segmentSamples.any((v) => v.abs() > 0.1), isTrue);

        final full = await extractEntireFileToTempF32(wav.path);
        expect(
          decodeF32leBytes(File(full).readAsBytesSync()).length,
          closeTo(kEchoPcmSampleRate * 1.0, kEchoPcmSampleRate * 0.02),
        );
      },
      skip: !FfmpegMediaProbe.usesFfmpegCli
          ? 'FFmpegKit platform'
          : _ffmpegCliMissing
          ? 'no ffmpeg CLI on this host'
          : false,
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
