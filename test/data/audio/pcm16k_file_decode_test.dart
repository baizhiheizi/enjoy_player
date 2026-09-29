import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/audio/pcm16k_mono.dart';

Uint8List _pcm16Wav({required int sampleRate, required int channels}) {
  const frames = 800;
  final dataBytes = frames * channels * 2;
  final bytes = Uint8List(44 + dataBytes);
  final bd = ByteData.sublistView(bytes);
  void ascii(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes[o + i] = s.codeUnitAt(i);
    }
  }

  ascii(0, 'RIFF');
  bd.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, channels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * channels * 2, Endian.little);
  bd.setUint16(32, channels * 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bd.setUint32(40, dataBytes, Endian.little);
  var o = 44;
  for (var i = 0; i < frames * channels; i++) {
    bd.setInt16(o, 1000, Endian.little);
    o += 2;
  }
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodeFileToPcm16kMono decodes a local PCM WAV by path', () async {
    final wav = await File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'enjoy_pcm16k_file_${DateTime.now().microsecondsSinceEpoch}.wav',
    ).writeAsBytes(_pcm16Wav(sampleRate: 8000, channels: 1), flush: true);
    addTearDown(() {
      if (wav.existsSync()) wav.deleteSync();
    });

    final pcm = await decodeFileToPcm16kMono(wav.path);
    expect(pcm.length, closeTo(1600, 2));
    expect(pcm.first, closeTo(1000 / 32768.0, 0.001));
  });

  test('decodeFileToPcm16kMono fails when the path is missing', () async {
    expect(
      () => decodeFileToPcm16kMono(r'C:\enjoy-missing-pcm16k-file.wav'),
      throwsA(isA<Pcm16kDecodeException>()),
    );
  });

  test('decodeFileWindowToPcm16kMono fails when the path is missing', () async {
    expect(
      () => decodeFileWindowToPcm16kMono(
        pathOrUri: r'C:\enjoy-missing-pcm16k-window.wav',
        startSeconds: 0,
        durationSeconds: 1,
      ),
      throwsA(isA<Pcm16kDecodeException>()),
    );
  });

  test(
    'decodeFileWindowToPcm16kMono fails closed when FFmpeg cannot decode',
    () async {
      final junk = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'enjoy_pcm16k_not_media_${DateTime.now().microsecondsSinceEpoch}.bin',
      );
      await junk.writeAsBytes(const [0, 1, 2, 3, 4, 5, 6, 7], flush: true);
      addTearDown(() {
        if (junk.existsSync()) junk.deleteSync();
      });
      await expectLater(
        decodeFileWindowToPcm16kMono(
          pathOrUri: junk.path,
          startSeconds: 0,
          durationSeconds: 0.2,
        ),
        throwsA(isA<Pcm16kDecodeException>()),
      );
    },
  );

  test('pcm16kInputIsRemoteHttp detects owned cloud URLs', () {
    expect(pcm16kInputIsRemoteHttp('https://cdn.example/a.mp3'), isTrue);
    expect(pcm16kInputIsRemoteHttp('http://cdn.example/a.mp3'), isTrue);
    expect(pcm16kInputIsRemoteHttp(r'C:\media\a.mp3'), isFalse);
    expect(pcm16kInputIsRemoteHttp('file:///tmp/a.mp3'), isFalse);
  });

  test('decodeFileToPcm16kMono rejects HTTP URLs', () async {
    expect(
      () => decodeFileToPcm16kMono('https://cdn.example/a.mp3'),
      throwsA(isA<Pcm16kDecodeException>()),
    );
  });

  test('decodeFileWindowToPcm16kMono rejects HTTP URLs', () async {
    expect(
      () => decodeFileWindowToPcm16kMono(
        pathOrUri: 'https://cdn.example/a.mp3',
        startSeconds: 0,
        durationSeconds: 1,
      ),
      throwsA(isA<Pcm16kDecodeException>()),
    );
  });
}
