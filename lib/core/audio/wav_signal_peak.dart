/// Best-effort peak scan inside a RIFF WAVE `data` chunk (diagnostics / silence check).
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Parsed `fmt ` chunk fields we need for scanning.
final class WavFmtLayout {
  const WavFmtLayout({
    required this.audioFormat,
    required this.numChannels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.blockAlign,
  });

  /// 1 = PCM integer, 3 = IEEE float (common for Windows MF captures).
  final int audioFormat;
  final int numChannels;
  final int sampleRate;
  final int bitsPerSample;
  final int blockAlign;
}

/// Peak amplitude in the `data` chunk (0–1 full-scale).
final class WavPeakScan {
  const WavPeakScan({
    required this.fmt,
    required this.dataBytes,
    required this.peakNormalized,
    required this.rmsNormalized,
    required this.nonZeroRatio,
    required this.totalSamples,
  });

  final WavFmtLayout fmt;
  final int dataBytes;

  /// Max absolute sample as a fraction of full scale (PCM16: /32768, float: 0–1).
  final double peakNormalized;

  /// Root-mean-square energy of the signal as a fraction of full scale.
  ///
  /// Unlike [peakNormalized], a single click or DC spike cannot inflate this
  /// to a misleading value; real speech typically gives `rmsNormalized` of
  /// roughly 0.02–0.3 even at moderate volume.
  final double rmsNormalized;

  /// Fraction of samples whose absolute value is above ~16-bit LSB
  /// ([kWavSilencePeakNorm] full-scale). Useful to detect "all-zero with a
  /// few stray spikes" output where [peakNormalized] looks healthy.
  final double nonZeroRatio;

  /// Total decoded samples (across all channels) considered.
  final int totalSamples;
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

/// Reads up to [maxReadBytes] from disk (whole file if smaller) and scans `data`.
Future<WavPeakScan?> scanWavDataPeakFromFile(
  String path, {
  int maxReadBytes = 32 * 1024 * 1024,
}) async {
  final f = File(path);
  if (!await f.exists()) return null;
  final len = await f.length();
  if (len < 44) return null;
  final n = len > maxReadBytes ? maxReadBytes : len;
  final builder = BytesBuilder(copy: false);
  await for (final chunk in f.openRead(0, n)) {
    builder.add(chunk);
  }
  return scanWavDataPeakFromBytes(builder.toBytes());
}

/// Same as [scanWavDataPeakFromFile] but for an in-memory prefix / full file.
WavPeakScan? scanWavDataPeakFromBytes(Uint8List bytes) {
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
    final afterChunk = chunkData + chunkSize;
    if (afterChunk > bytes.length) break;

    if (chunkId == 'fmt ') {
      if (chunkSize < 16) return null;
      fmt = WavFmtLayout(
        audioFormat: _u16(bytes, chunkData),
        numChannels: _u16(bytes, chunkData + 2),
        sampleRate: _u32(bytes, chunkData + 4),
        bitsPerSample: _u16(bytes, chunkData + 14),
        blockAlign: _u16(bytes, chunkData + 12),
      );
    } else if (chunkId == 'data') {
      dataStart = chunkData;
      dataSize = chunkSize;
      break;
    }

    final padded = chunkSize + (chunkSize.isOdd ? 1 : 0);
    offset += 8 + padded;
  }

  final f = fmt;
  final ds = dataStart;
  final dz = dataSize;
  if (f == null || ds == null || dz == null || dz <= 0) return null;

  final end = (ds + dz).clamp(0, bytes.length);
  final data = bytes.sublist(ds, end);

  switch (f.audioFormat) {
    case 1: // PCM integer
      if (f.bitsPerSample == 16 && f.blockAlign == 2 * f.numChannels) {
        return _scanInt(
          data: data,
          fmt: f,
          dz: dz,
          fullScale: 32768.0,
          readSampleAtByteOffset: (data, off) {
            final s = data[off] | (data[off + 1] << 8);
            return (s > 32767 ? s - 65536 : s).toDouble();
          },
          sampleStride: 2,
        );
      }
      if (f.bitsPerSample == 32 && f.blockAlign == 4 * f.numChannels) {
        final bd = ByteData.sublistView(data);
        return _scanInt(
          data: data,
          fmt: f,
          dz: dz,
          fullScale: 2147483648.0,
          readSampleAtByteOffset: (data, off) =>
              bd.getInt32(off, Endian.little).toDouble(),
          sampleStride: 4,
        );
      }
      return null;
    case 3: // IEEE float
      if (f.bitsPerSample == 32 && f.blockAlign == 4 * f.numChannels) {
        final bd = ByteData.sublistView(data);
        return _scanInt(
          data: data,
          fmt: f,
          dz: dz,
          fullScale: 1.0,
          readSampleAtByteOffset: (data, off) =>
              bd.getFloat32(off, Endian.little),
          sampleStride: 4,
        );
      }
      return null;
    default:
      return null;
  }
}

WavPeakScan _scanInt({
  required Uint8List data,
  required WavFmtLayout fmt,
  required int dz,
  required double fullScale,
  required double Function(Uint8List data, int byteOffset)
      readSampleAtByteOffset,
  required int sampleStride,
}) {
  var peak = 0.0;
  var sumSquares = 0.0;
  var nonZero = 0;
  final frames = data.length ~/ fmt.blockAlign;
  final totalSamples = frames * fmt.numChannels;
  final silenceThreshold = kWavSilencePeakNorm * fullScale;
  for (var i = 0; i < frames; i++) {
    final frameOff = i * fmt.blockAlign;
    for (var ch = 0; ch < fmt.numChannels; ch++) {
      final off = frameOff + sampleStride * ch;
      final v = readSampleAtByteOffset(data, off);
      final av = v.abs();
      if (av > peak) peak = av;
      if (av > silenceThreshold) nonZero++;
      sumSquares += v * v;
    }
  }
  final rms = totalSamples == 0 ? 0.0 : math.sqrt(sumSquares / totalSamples);
  return WavPeakScan(
    fmt: fmt,
    dataBytes: dz,
    peakNormalized: (peak / fullScale).clamp(0.0, 1.0),
    rmsNormalized: (rms / fullScale).clamp(0.0, 1.0),
    nonZeroRatio: totalSamples == 0 ? 0.0 : nonZero / totalSamples,
    totalSamples: totalSamples,
  );
}

/// ~16-bit LSB — below this after normalization we treat FFmpeg output as silent.
const kWavSilencePeakNorm = 0.001;
