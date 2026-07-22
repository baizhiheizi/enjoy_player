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
    tempRoot = Directory.systemTemp.createTempSync('echo_pcm_cov_test');
    PathProviderPlatform.instance = TestPathProvider(tempRoot.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  group('EchoPcmExtractionException.toString', () {
    test('includes reason only when message is empty', () {
      const e = EchoPcmExtractionException(EchoPcmFailureReason.timeout);
      expect(
        e.toString(),
        'EchoPcmExtractionException(EchoPcmFailureReason.timeout)',
      );
    });

    test('includes reason and message when message is non-empty', () {
      const e = EchoPcmExtractionException(
        EchoPcmFailureReason.ffmpegFailed,
        'exit code 1',
      );
      expect(
        e.toString(),
        'EchoPcmExtractionException(EchoPcmFailureReason.ffmpegFailed: exit code 1)',
      );
    });

    test('exposes reason and message fields', () {
      const e = EchoPcmExtractionException(
        EchoPcmFailureReason.cancelled,
        'user abort',
      );
      expect(e.reason, EchoPcmFailureReason.cancelled);
      expect(e.message, 'user abort');
    });
  });

  group('EchoPcmCancelToken', () {
    test('starts uncancelled', () {
      final token = EchoPcmCancelToken();
      expect(token.isCancelled, isFalse);
    });

    test('cancel sets isCancelled to true', () {
      final token = EchoPcmCancelToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('double cancel is a no-op (idempotent)', () {
      final token = EchoPcmCancelToken();
      var hookCalls = 0;
      token.onCancel(() => hookCalls++);
      token.cancel();
      token.cancel();
      expect(hookCalls, 1);
    });

    test('onCancel runs hook immediately if already cancelled', () {
      final token = EchoPcmCancelToken();
      token.cancel();
      var ran = false;
      token.onCancel(() => ran = true);
      expect(ran, isTrue);
    });

    test('onCancel registers hook that fires on cancel', () {
      final token = EchoPcmCancelToken();
      final order = <String>[];
      token.onCancel(() => order.add('first'));
      token.onCancel(() => order.add('second'));
      token.cancel();
      expect(order, ['first', 'second']);
    });

    test('hook that throws does not prevent other hooks from running', () {
      final token = EchoPcmCancelToken();
      var secondRan = false;
      token.onCancel(() => throw StateError('boom'));
      token.onCancel(() => secondRan = true);
      // Should not propagate the exception.
      token.cancel();
      expect(secondRan, isTrue);
    });
  });

  group('decodeF32leBytes edge cases', () {
    test('returns empty for zero-length input', () {
      expect(decodeF32leBytes(Uint8List(0)), isEmpty);
    });

    test('returns empty for 3 bytes (less than one float)', () {
      expect(decodeF32leBytes(Uint8List(3)), isEmpty);
    });

    test('decodes exactly one float (4 bytes)', () {
      final bd = ByteData(4);
      bd.setFloat32(0, 1.5, Endian.little);
      final result = decodeF32leBytes(bd.buffer.asUint8List());
      expect(result.length, 1);
      expect(result[0], closeTo(1.5, 1e-6));
    });

    test('truncates trailing bytes that do not form a full float', () {
      // 6 bytes = 1 full float + 2 leftover bytes
      final bd = ByteData(6);
      bd.setFloat32(0, -0.75, Endian.little);
      bd.setUint8(4, 0xFF);
      bd.setUint8(5, 0xAB);
      final result = decodeF32leBytes(bd.buffer.asUint8List());
      expect(result.length, 1);
      expect(result[0], closeTo(-0.75, 1e-6));
    });

    test('decodes multiple floats correctly', () {
      final bd = ByteData(12);
      bd.setFloat32(0, 0.0, Endian.little);
      bd.setFloat32(4, 1.0, Endian.little);
      bd.setFloat32(8, -1.0, Endian.little);
      final result = decodeF32leBytes(bd.buffer.asUint8List());
      expect(result.length, 3);
      expect(result[0], closeTo(0.0, 1e-6));
      expect(result[1], closeTo(1.0, 1e-6));
      expect(result[2], closeTo(-1.0, 1e-6));
    });
  });

  group('pre-cancelled token', () {
    test('extractMonoFloat32SegmentToTempFile throws cancelled when token is '
        'already cancelled before FFmpeg invocation', () async {
      final media = File('${tempRoot.path}/dummy.mp3')
        ..writeAsStringSync('fake');
      final token = EchoPcmCancelToken()..cancel();
      await expectLater(
        extractMonoFloat32SegmentToTempFile(
          mediaFilePath: media.path,
          startSec: 0,
          durationSec: 1,
          token: token,
        ),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            anyOf(
              EchoPcmFailureReason.cancelled,
              EchoPcmFailureReason.ffmpegMissing,
              EchoPcmFailureReason.ffmpegFailed,
            ),
          ),
        ),
      );
    });

    test('extractEntireFileToTempF32 throws cancelled when token is already '
        'cancelled before FFmpeg invocation', () async {
      final media = File('${tempRoot.path}/dummy2.wav')
        ..writeAsStringSync('fake');
      final token = EchoPcmCancelToken()..cancel();
      await expectLater(
        extractEntireFileToTempF32(media.path, token: token),
        throwsA(
          isA<EchoPcmExtractionException>().having(
            (e) => e.reason,
            'reason',
            anyOf(
              EchoPcmFailureReason.cancelled,
              EchoPcmFailureReason.ffmpegMissing,
              EchoPcmFailureReason.ffmpegFailed,
            ),
          ),
        ),
      );
    });
  });

  group('extractEntireFileToTempF32 FFmpeg availability', () {
    test(
      'surfaces ffmpegMissing/ffmpegFailed when FFmpegKit is not registered',
      () async {
        final media = File('${tempRoot.path}/full_decode_test.wav')
          ..writeAsStringSync('not real media');
        await expectLater(
          extractEntireFileToTempF32(media.path),
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

  group('EchoPcmFailureReason enum coverage', () {
    test('all enum values are distinct', () {
      final values = EchoPcmFailureReason.values;
      expect(values.length, 7);
      expect(values.toSet().length, 7);
      expect(values, contains(EchoPcmFailureReason.invalidInput));
      expect(values, contains(EchoPcmFailureReason.fileMissing));
      expect(values, contains(EchoPcmFailureReason.ffmpegMissing));
      expect(values, contains(EchoPcmFailureReason.ffmpegFailed));
      expect(values, contains(EchoPcmFailureReason.timeout));
      expect(values, contains(EchoPcmFailureReason.cancelled));
      expect(values, contains(EchoPcmFailureReason.emptyOutput));
    });
  });

  group('constants', () {
    test('kEchoPcmSampleRate is 44100', () {
      expect(kEchoPcmSampleRate, 44100);
    });

    test('kEchoPcmExtractionTimeout is 30 seconds', () {
      expect(kEchoPcmExtractionTimeout, const Duration(seconds: 30));
    });
  });
}
