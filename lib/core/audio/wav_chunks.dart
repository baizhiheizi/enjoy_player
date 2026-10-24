/// Shared RIFF/WAVE container reader for every WAV consumer.
library;

import 'dart:typed_data';

/// Parsed `fmt ` chunk fields.
final class WavFmtLayout {
  const WavFmtLayout({
    required this.audioFormat,
    required this.numChannels,
    required this.sampleRate,
    required this.byteRate,
    required this.bitsPerSample,
    required this.blockAlign,
  });

  /// 1 = PCM integer, 3 = IEEE float (common for Windows MF captures).
  final int audioFormat;
  final int numChannels;
  final int sampleRate;
  final int byteRate;
  final int bitsPerSample;
  final int blockAlign;
}

/// The `fmt ` layout plus the `data` chunk extent.
final class WavChunks {
  const WavChunks({
    required this.fmt,
    required this.dataStart,
    required this.dataSize,
  });

  final WavFmtLayout fmt;
  final int dataStart;
  final int dataSize;
}

/// Walks the RIFF container and returns the `fmt ` fields and `data` extent.
///
/// Returns `null` when [bytes] is not RIFF/WAVE, a required chunk is missing
/// or truncated, or the `fmt ` chunk is shorter than the 16-byte PCM layout.
WavChunks? readWavChunks(Uint8List bytes) {
  if (bytes.length < 44) return null;
  if (!_fourCc(bytes, 0, 'RIFF') || !_fourCc(bytes, 8, 'WAVE')) return null;

  WavFmtLayout? fmt;
  int? dataStart;
  int? dataSize;

  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = _u32(bytes, offset + 4);
    final chunkData = offset + 8;
    if (chunkData + chunkSize > bytes.length) return null;

    if (chunkId == 'fmt ') {
      if (chunkSize < 16) return null;
      fmt = WavFmtLayout(
        audioFormat: _u16(bytes, chunkData),
        numChannels: _u16(bytes, chunkData + 2),
        sampleRate: _u32(bytes, chunkData + 4),
        byteRate: _u32(bytes, chunkData + 8),
        blockAlign: _u16(bytes, chunkData + 12),
        bitsPerSample: _u16(bytes, chunkData + 14),
      );
    } else if (chunkId == 'data') {
      dataStart = chunkData;
      dataSize = chunkSize;
    }

    if (fmt != null && dataStart != null) break;

    final padded = chunkSize + (chunkSize.isOdd ? 1 : 0);
    offset += 8 + padded;
  }

  final layout = fmt;
  final start = dataStart;
  final size = dataSize;
  if (layout == null || start == null || size == null || size <= 0) {
    return null;
  }
  return WavChunks(fmt: layout, dataStart: start, dataSize: size);
}

bool _fourCc(Uint8List bytes, int offset, String ascii) {
  if (offset + 4 > bytes.length) return false;
  for (var i = 0; i < 4; i++) {
    if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

int _u16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);
int _u32(Uint8List b, int o) =>
    b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);
