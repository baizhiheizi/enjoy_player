import 'dart:typed_data';

import 'package:enjoy_player/core/audio/wav_duration_ms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wavDurationMsFromBytes parses 1 s mono PCM @ 44.1 kHz', () {
    final wav = _minimalPcmWav(
      sampleRate: 44100,
      channels: 1,
      bitsPerSample: 16,
      dataByteLength: 44100 * 2,
    );
    expect(wavDurationMsFromBytes(wav), 1000);
  });

  test('wavDurationMsFromBytes returns null for garbage', () {
    expect(wavDurationMsFromBytes(Uint8List(12)), isNull);
  });

  test('wavDurationMsFromBytes rejects a fmt chunk shorter than 16 bytes', () {
    final wav = _minimalPcmWav(
      sampleRate: 44100,
      channels: 1,
      bitsPerSample: 16,
      dataByteLength: 44100 * 2,
    );
    final patched = Uint8List.fromList(wav);
    ByteData.sublistView(patched).setUint32(16, 14, Endian.little);

    expect(wavDurationMsFromBytes(patched), isNull);
  });

  test('wavDurationMsFromBytes ignores a corrupt trailing chunk', () {
    final wav = _minimalPcmWav(
      sampleRate: 44100,
      channels: 1,
      bitsPerSample: 16,
      dataByteLength: 44100 * 2,
    );
    final trailing = BytesBuilder(copy: false)
      ..add('LIST'.codeUnits)
      ..add(_le32(0xFFFFFFF0))
      ..addByte(0);
    final bytes = Uint8List.fromList([...wav, ...trailing.toBytes()]);

    expect(wavDurationMsFromBytes(bytes), 1000);
  });
}

Uint8List _le32(int v) {
  final d = ByteData(4)..setUint32(0, v, Endian.little);
  return d.buffer.asUint8List();
}

/// RIFF WAVE with `fmt ` (PCM) + `data`; PCM payload length is [dataByteLength].
Uint8List _minimalPcmWav({
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
  required int dataByteLength,
}) {
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final fmt = BytesBuilder(copy: false);
  fmt.addByte(0x01);
  fmt.addByte(0x00);
  fmt.addByte(channels & 0xff);
  fmt.addByte((channels >> 8) & 0xff);
  fmt.add(_le32(sampleRate));
  fmt.add(_le32(byteRate));
  fmt.addByte(blockAlign & 0xff);
  fmt.addByte((blockAlign >> 8) & 0xff);
  fmt.addByte(bitsPerSample & 0xff);
  fmt.addByte((bitsPerSample >> 8) & 0xff);
  final fmtBytes = fmt.toBytes();
  expect(fmtBytes.length, 16);

  final pad = dataByteLength.isOdd ? 1 : 0;
  final riffPayloadMinus8 = 4 + (8 + 16) + (8 + dataByteLength + pad);

  final b = BytesBuilder(copy: false);
  b.addByte(0x52);
  b.addByte(0x49);
  b.addByte(0x46);
  b.addByte(0x46);
  b.add(_le32(riffPayloadMinus8));
  b.addByte(0x57);
  b.addByte(0x41);
  b.addByte(0x56);
  b.addByte(0x45);
  b.addByte(0x66);
  b.addByte(0x6d);
  b.addByte(0x74);
  b.addByte(0x20);
  b.add(_le32(16));
  b.add(fmtBytes);
  b.addByte(0x64);
  b.addByte(0x61);
  b.addByte(0x74);
  b.addByte(0x61);
  b.add(_le32(dataByteLength));
  b.add(Uint8List(dataByteLength));
  if (pad != 0) {
    b.addByte(0);
  }
  return Uint8List.fromList(b.toBytes());
}
