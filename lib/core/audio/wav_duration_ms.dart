/// PCM WAVE duration from RIFF `fmt ` + `data` chunks (no codec playback).
library;

import 'dart:typed_data';

import 'wav_chunks.dart';

/// Returns duration in milliseconds, or `null` if [bytes] is not a parsable PCM WAVE.
int? wavDurationMsFromBytes(Uint8List bytes) {
  final chunks = readWavChunks(bytes);
  if (chunks == null) return null;

  final byteRate = chunks.fmt.byteRate;
  if (byteRate <= 0) return null;

  final ms = ((chunks.dataSize * 1000) / byteRate).round();
  if (ms < 0) return null;
  return ms;
}
