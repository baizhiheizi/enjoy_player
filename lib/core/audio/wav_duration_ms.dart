/// PCM WAVE duration from RIFF `fmt ` + `data` chunks (no codec playback).
library;

import 'dart:typed_data';

/// Returns duration in milliseconds, or `null` if [bytes] is not a parsable PCM WAVE.
int? wavDurationMsFromBytes(Uint8List bytes) {
  if (bytes.length < 44) return null;
  if (!_fourCc(bytes, 0, 'RIFF') || !_fourCc(bytes, 8, 'WAVE')) return null;

  var offset = 12;
  int? byteRate;
  int? dataBytes;

  while (offset + 8 <= bytes.length && (byteRate == null || dataBytes == null)) {
    final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = _readUint32Le(bytes, offset + 4);
    final dataStart = offset + 8;
    final afterChunk = dataStart + chunkSize;
    if (afterChunk > bytes.length) return null;

    if (chunkId == 'fmt ') {
      if (chunkSize < 14) return null;
      byteRate = _readUint32Le(bytes, dataStart + 8);
      if (byteRate <= 0) return null;
    } else if (chunkId == 'data') {
      dataBytes = chunkSize;
    }

    final padded = chunkSize + (chunkSize.isOdd ? 1 : 0);
    offset += 8 + padded;
  }

  if (byteRate == null || dataBytes == null || dataBytes <= 0) return null;
  final ms = ((dataBytes * 1000) / byteRate).round();
  if (ms < 0) return null;
  return ms;
}

bool _fourCc(Uint8List bytes, int offset, String ascii) {
  if (offset + 4 > bytes.length) return false;
  for (var i = 0; i < 4; i++) {
    if (bytes[offset + i] != ascii.codeUnitAt(i)) return false;
  }
  return true;
}

int _readUint32Le(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}
