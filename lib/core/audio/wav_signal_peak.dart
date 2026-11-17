/// Best-effort peak scan inside a RIFF WAVE `data` chunk (diagnostics / silence check).
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'wav_chunks.dart';

/// `fmt ` chunk format codes (see [WavFmtLayout.audioFormat]).
const kWavFormatPcm = 0x0001;
const kWavFormatIeeeFloat = 0x0003;

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

/// Reads WAV header + streams `data` up to [maxReadBytes] in fixed chunks.
Future<WavPeakScan?> scanWavDataPeakFromFile(
  String path, {
  int maxReadBytes = 32 * 1024 * 1024,
}) async {
  final f = File(path);
  if (!await f.exists()) return null;
  final len = await f.length();
  if (len < 44) return null;
  final capped = len > maxReadBytes ? maxReadBytes : len;
  final headerWindow = capped < 65536 ? capped : 65536;
  final raf = await f.open();
  try {
    final prefix = await raf.read(headerWindow);
    final chunks = readWavChunksFromHeaderPrefix(prefix);
    if (chunks == null) {
      if (capped <= headerWindow) return null;
      await raf.setPosition(0);
      return scanWavDataPeakFromBytes(await raf.read(capped));
    }
    final fmt = chunks.fmt;
    if (fmt.numChannels <= 0 || fmt.blockAlign <= 0) return null;
    if (!_isSupportedFormat(fmt)) return null;

    final dataEnd = math.min(capped, chunks.dataStart + chunks.dataSize);
    final availableBytes = dataEnd - chunks.dataStart;
    if (availableBytes <= 0) return null;

    final acc = _PeakAccumulator(fmt: fmt, dataBytes: chunks.dataSize);
    final align = fmt.blockAlign;
    var tailLen = 0;
    final carry = Uint8List(align);

    final prefixAvailable = math.min(prefix.length, dataEnd) - chunks.dataStart;
    if (prefixAvailable > 0) {
      final initialView = Uint8List.sublistView(
        prefix,
        chunks.dataStart,
        chunks.dataStart + prefixAvailable,
      );
      final usable = (initialView.length ~/ align) * align;
      if (usable > 0) {
        acc.consume(Uint8List.sublistView(initialView, 0, usable));
      }
      tailLen = initialView.length - usable;
      if (tailLen > 0) {
        carry.setRange(0, tailLen, initialView, usable);
      }
    }

    var remaining =
        availableBytes - (prefixAvailable > 0 ? prefixAvailable : 0);
    if (chunks.dataStart > prefix.length) {
      await raf.setPosition(chunks.dataStart);
    }
    const chunkBytes = 64 * 1024;
    final readBuf = Uint8List(chunkBytes + align);
    while (remaining > 0) {
      final toRead = remaining < chunkBytes ? remaining : chunkBytes;
      final readNow = await raf.readInto(readBuf, tailLen, tailLen + toRead);
      if (readNow <= 0) break;
      remaining -= readNow;
      if (tailLen > 0) {
        readBuf.setRange(0, tailLen, carry);
      }
      final totalInBuf = tailLen + readNow;
      final usable = (totalInBuf ~/ align) * align;
      if (usable > 0) {
        acc.consume(Uint8List.sublistView(readBuf, 0, usable));
      }
      tailLen = totalInBuf - usable;
      if (tailLen > 0) {
        carry.setRange(0, tailLen, readBuf, usable);
      }
    }
    return acc.finish();
  } finally {
    await raf.close();
  }
}

/// Same as [scanWavDataPeakFromFile] but for an in-memory prefix / full file.
WavPeakScan? scanWavDataPeakFromBytes(Uint8List bytes) {
  final chunks = readWavChunks(bytes);
  if (chunks == null) return null;

  final f = chunks.fmt;
  if (f.numChannels <= 0 || f.blockAlign <= 0) return null;
  if (!_isSupportedFormat(f)) return null;

  final end = math.min(chunks.dataStart + chunks.dataSize, bytes.length);
  if (end <= chunks.dataStart) return null;
  final data = Uint8List.sublistView(bytes, chunks.dataStart, end);

  final acc = _PeakAccumulator(fmt: f, dataBytes: chunks.dataSize);
  acc.consume(data);
  return acc.finish();
}

bool _isSupportedFormat(WavFmtLayout f) {
  if (f.audioFormat == kWavFormatPcm) {
    return (f.bitsPerSample == 16 && f.blockAlign == 2 * f.numChannels) ||
        (f.bitsPerSample == 32 && f.blockAlign == 4 * f.numChannels);
  }
  if (f.audioFormat == kWavFormatIeeeFloat) {
    return f.bitsPerSample == 32 && f.blockAlign == 4 * f.numChannels;
  }
  return false;
}

class _PeakAccumulator {
  _PeakAccumulator({required this.fmt, required this.dataBytes})
    : fullScale = fmt.audioFormat == kWavFormatIeeeFloat
          ? 1.0
          : (fmt.bitsPerSample == 16 ? 32768.0 : 2147483648.0),
      silenceThreshold =
          kWavSilencePeakNorm *
          (fmt.audioFormat == kWavFormatIeeeFloat
              ? 1.0
              : (fmt.bitsPerSample == 16 ? 32768.0 : 2147483648.0));

  final WavFmtLayout fmt;
  final int dataBytes;
  final double fullScale;
  final double silenceThreshold;

  double peak = 0.0;
  double sumSquares = 0.0;
  int nonZero = 0;
  int totalSamples = 0;

  void consume(Uint8List data) {
    final align = fmt.blockAlign;
    final channels = fmt.numChannels;
    final frames = data.length ~/ align;
    if (frames <= 0) return;
    totalSamples += frames * channels;

    if (fmt.audioFormat == kWavFormatPcm && fmt.bitsPerSample == 16) {
      for (var i = 0; i < frames; i++) {
        final frameOff = i * align;
        for (var ch = 0; ch < channels; ch++) {
          final off = frameOff + ch * 2;
          final s = data[off] | (data[off + 1] << 8);
          final v = (s > 32767 ? s - 65536 : s).toDouble();
          final av = v < 0 ? -v : v;
          if (av > peak) peak = av;
          if (av > silenceThreshold) nonZero++;
          sumSquares += v * v;
        }
      }
      return;
    }

    final bd = ByteData.sublistView(data);
    if (fmt.audioFormat == kWavFormatPcm) {
      for (var i = 0; i < frames; i++) {
        final frameOff = i * align;
        for (var ch = 0; ch < channels; ch++) {
          final v = bd.getInt32(frameOff + ch * 4, Endian.little).toDouble();
          final av = v < 0 ? -v : v;
          if (av > peak) peak = av;
          if (av > silenceThreshold) nonZero++;
          sumSquares += v * v;
        }
      }
      return;
    }

    for (var i = 0; i < frames; i++) {
      final frameOff = i * align;
      for (var ch = 0; ch < channels; ch++) {
        final v = bd.getFloat32(frameOff + ch * 4, Endian.little);
        final av = v < 0 ? -v : v;
        if (av > peak) peak = av;
        if (av > silenceThreshold) nonZero++;
        sumSquares += v * v;
      }
    }
  }

  WavPeakScan finish() {
    final rms = totalSamples == 0 ? 0.0 : math.sqrt(sumSquares / totalSamples);
    return WavPeakScan(
      fmt: fmt,
      dataBytes: dataBytes,
      peakNormalized: (peak / fullScale).clamp(0.0, 1.0),
      rmsNormalized: (rms / fullScale).clamp(0.0, 1.0),
      nonZeroRatio: totalSamples == 0 ? 0.0 : nonZero / totalSamples,
      totalSamples: totalSamples,
    );
  }
}

/// ~16-bit LSB — below this after normalization we treat FFmpeg output as silent.
const kWavSilencePeakNorm = 0.001;
