/// Parses a WAV header to extract exact audio duration.
library;

import 'dart:typed_data';

/// Returns the duration of a WAV file in milliseconds by reading its header.
///
/// WAV format (RIFF):
///   Bytes 22-23: num channels (uint16 LE)
///   Bytes 24-27: sample rate (uint32 LE)
///   Bytes 34-35: bits per sample (uint16 LE)
///   Bytes 40-43: data chunk size (uint32 LE)
///   Duration_ms = dataChunkSize / (sampleRate * numChannels * bitsPerSample/8) * 1000
int wavDurationMs(Uint8List bytes) {
  if (bytes.length < 44) return 0;

  // Read WAV header fields (little-endian).
  final bd = ByteData.sublistView(bytes);
  final numChannels = bd.getUint16(22, Endian.little);
  final sampleRate = bd.getUint32(24, Endian.little);
  final bitsPerSample = bd.getUint16(34, Endian.little);
  final dataSize = bd.getUint32(40, Endian.little);

  if (sampleRate == 0 || numChannels == 0 || bitsPerSample == 0) return 0;

  final bytesPerSecond = sampleRate * numChannels * (bitsPerSample ~/ 8);
  if (bytesPerSecond == 0) return 0;

  return (dataSize / bytesPerSecond * 1000).round();
}
