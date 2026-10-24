import 'dart:typed_data';

import 'package:enjoy_player/core/audio/wav_chunks.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _ascii(String text) => text.codeUnits;

List<int> _le16(int v) => [v & 0xff, (v >> 8) & 0xff];
List<int> _le32(int v) => [
  v & 0xff,
  (v >> 8) & 0xff,
  (v >> 16) & 0xff,
  (v >> 24) & 0xff,
];

Uint8List _chunk(String id, List<int> payload) {
  final b = BytesBuilder(copy: false)
    ..add(_ascii(id))
    ..add(_le32(payload.length))
    ..add(payload);
  if (payload.length.isOdd) b.addByte(0);
  return b.toBytes();
}

Uint8List _wav(List<Uint8List> chunks) {
  final body = BytesBuilder(copy: false)..add(_ascii('WAVE'));
  for (final chunk in chunks) {
    body.add(chunk);
  }
  final payload = body.toBytes();
  return (BytesBuilder(copy: false)
        ..add(_ascii('RIFF'))
        ..add(_le32(payload.length))
        ..add(payload))
      .toBytes();
}

Uint8List _fmtPayload({
  int audioFormat = 1,
  int channels = 1,
  int sampleRate = 44100,
  int byteRate = 88200,
  int blockAlign = 2,
  int bitsPerSample = 16,
}) {
  return Uint8List.fromList([
    ..._le16(audioFormat),
    ..._le16(channels),
    ..._le32(sampleRate),
    ..._le32(byteRate),
    ..._le16(blockAlign),
    ..._le16(bitsPerSample),
  ]);
}

void main() {
  test('reads fmt fields and the data extent', () {
    final bytes = _wav([
      _chunk('fmt ', _fmtPayload(channels: 2, sampleRate: 48000)),
      _chunk('data', List<int>.filled(16, 1)),
    ]);

    final chunks = readWavChunks(bytes)!;
    expect(chunks.fmt.audioFormat, 1);
    expect(chunks.fmt.numChannels, 2);
    expect(chunks.fmt.sampleRate, 48000);
    expect(chunks.fmt.byteRate, 88200);
    expect(chunks.fmt.blockAlign, 2);
    expect(chunks.fmt.bitsPerSample, 16);
    expect(chunks.dataSize, 16);
    expect(
      bytes.sublist(chunks.dataStart, chunks.dataStart + chunks.dataSize),
      everyElement(1),
    );
  });

  test('skips odd-sized chunks using RIFF padding', () {
    final bytes = _wav([
      _chunk('JUNK', [1, 2, 3]),
      _chunk('fmt ', _fmtPayload()),
      _chunk('data', List<int>.filled(4, 0)),
    ]);

    final chunks = readWavChunks(bytes);
    expect(chunks, isNotNull);
    expect(chunks!.dataSize, 4);
  });

  test('finds fmt after data', () {
    final bytes = _wav([
      _chunk('data', List<int>.filled(4, 0)),
      _chunk('fmt ', _fmtPayload()),
    ]);

    final chunks = readWavChunks(bytes);
    expect(chunks, isNotNull);
    expect(chunks!.fmt.sampleRate, 44100);
  });

  test('rejects a fmt chunk shorter than 16 bytes', () {
    final bytes = _wav([
      _chunk('fmt ', _fmtPayload().sublist(0, 14)),
      _chunk('data', [1, 2]),
    ]);

    expect(readWavChunks(bytes), isNull);
  });

  test('rejects a truncated data chunk', () {
    final bytes = _wav([
      _chunk('fmt ', _fmtPayload()),
      _chunk('data', List<int>.filled(16, 0)),
    ]);

    expect(readWavChunks(bytes.sublist(0, bytes.length - 4)), isNull);
  });

  test('rejects non-RIFF input', () {
    expect(readWavChunks(Uint8List(64)), isNull);
  });
}
