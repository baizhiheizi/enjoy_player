import 'dart:typed_data';

import 'package:enjoy_player/features/craft/domain/wav_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wavDurationMs', () {
    test('parses a minimal WAV header correctly', () {
      // Build a minimal WAV header: 44 bytes RIFF header + 1600 bytes data
      // 16 kHz, mono, 16-bit → 32000 bytes/sec → 1600 bytes = 50 ms
      final bytes = ByteData(44 + 1600);
      // RIFF header
      bytes.setUint8(0, 0x52); // 'R'
      bytes.setUint8(1, 0x49); // 'I'
      bytes.setUint8(2, 0x46); // 'F'
      bytes.setUint8(3, 0x46); // 'F'
      // ChunkSize = 36 + dataSize
      bytes.setUint32(4, 36 + 1600, Endian.little);
      // WAVE format
      bytes.setUint8(8, 0x57); // 'W'
      bytes.setUint8(9, 0x41); // 'A'
      bytes.setUint8(10, 0x56); // 'V'
      bytes.setUint8(11, 0x45); // 'E'
      // fmt chunk
      bytes.setUint8(12, 0x66); // 'f'
      bytes.setUint8(13, 0x6D); // 'm'
      bytes.setUint8(14, 0x74); // 't'
      bytes.setUint8(15, 0x20); // ' '
      // Subchunk1Size = 16
      bytes.setUint32(16, 16, Endian.little);
      // AudioFormat = 1 (PCM)
      bytes.setUint16(20, 1, Endian.little);
      // NumChannels = 1
      bytes.setUint16(22, 1, Endian.little);
      // SampleRate = 16000
      bytes.setUint32(24, 16000, Endian.little);
      // ByteRate = 32000
      bytes.setUint32(28, 32000, Endian.little);
      // BlockAlign = 2
      bytes.setUint16(32, 2, Endian.little);
      // BitsPerSample = 16
      bytes.setUint16(34, 16, Endian.little);
      // data chunk
      bytes.setUint8(36, 0x64); // 'd'
      bytes.setUint8(37, 0x61); // 'a'
      bytes.setUint8(38, 0x74); // 't'
      bytes.setUint8(39, 0x61); // 'a'
      // DataSize = 1600
      bytes.setUint32(40, 1600, Endian.little);

      final result = wavDurationMs(bytes.buffer.asUint8List());
      // 1600 bytes / (16000 * 1 * 2) = 0.05 sec = 50 ms
      expect(result, 50);
    });

    test('returns 0 for too-short input', () {
      expect(wavDurationMs(Uint8List(10)), 0);
    });

    test('returns 0 for zero sample rate', () {
      final bytes = ByteData(44);
      bytes.setUint16(22, 1, Endian.little); // channels = 1
      bytes.setUint32(24, 0, Endian.little); // sampleRate = 0
      bytes.setUint16(34, 16, Endian.little); // bitsPerSample = 16
      bytes.setUint32(40, 1600, Endian.little); // dataSize
      expect(wavDurationMs(bytes.buffer.asUint8List()), 0);
    });
  });
}
