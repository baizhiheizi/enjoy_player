/// Partial-file SHA-256 matching [apps/web/src/db/id-generator.ts] `hashBlob`.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Same as web `HASH_CHUNK_SIZE` (4 MiB).
const int kEnjoyHashChunkSize = 4 * 1024 * 1024;

/// Reads only the byte ranges used by the web app, then returns SHA-256 hex.
///
/// Strategy (identical to web):
/// - size &lt; 4MB: hash entire file
/// - 4MB ≤ size ≤ 8MB: hash first 4MB + last 4MB
/// - size &gt; 8MB: hash first 4MB + middle 4MB + last 4MB
String chunkedContentSha256HexFromFileSync(String filePath) {
  final file = File(filePath);
  final raf = file.openSync(mode: FileMode.read);
  try {
    final size = raf.lengthSync();
    final chunk = kEnjoyHashChunkSize;
    final combined = _bytesForPartialHash(raf, size, chunk);
    final digest = sha256.convert(combined);
    return digest.toString();
  } finally {
    raf.closeSync();
  }
}

Uint8List _bytesForPartialHash(RandomAccessFile raf, int size, int chunk) {
  if (size < chunk) {
    raf.setPositionSync(0);
    return Uint8List.fromList(raf.readSync(size));
  }
  if (size <= chunk * 2) {
    final first = Uint8List(chunk);
    raf.setPositionSync(0);
    raf.readIntoSync(first);
    final last = Uint8List(chunk);
    raf.setPositionSync(size - chunk);
    raf.readIntoSync(last);
    return Uint8List.fromList([...first, ...last]);
  }
  final first = Uint8List(chunk);
  raf.setPositionSync(0);
  raf.readIntoSync(first);
  final middleOffset = (size ~/ 2) - (chunk ~/ 2);
  final middle = Uint8List(chunk);
  raf.setPositionSync(middleOffset);
  raf.readIntoSync(middle);
  final last = Uint8List(chunk);
  raf.setPositionSync(size - chunk);
  raf.readIntoSync(last);
  return Uint8List.fromList([...first, ...middle, ...last]);
}
