import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:enjoy_player/data/files/chunked_file_hash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('chunkedContentSha256HexFromFileSync', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('enjoy_chunk_hash');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('hashes entire file when under 4 MiB', () async {
      final data = Uint8List.fromList(List.generate(500, (i) => i % 256));
      final path = p.join(tmp.path, 'small.bin');
      await File(path).writeAsBytes(data);
      final got = chunkedContentSha256HexFromFileSync(path);
      expect(got, sha256.convert(data).toString());
    });

    test('4 MiB file uses first+last 4 MiB (duplicate) like web', () async {
      final n = kEnjoyHashChunkSize;
      final data = Uint8List.fromList(List.generate(n, (i) => (i * 7 + 11) % 256));
      final path = p.join(tmp.path, '4mb.bin');
      await File(path).writeAsBytes(data);
      final combined = Uint8List.fromList([...data, ...data]);
      final want = sha256.convert(combined).toString();
      expect(chunkedContentSha256HexFromFileSync(path), want);
    });

    test('5 MiB file uses first and last 4 MiB', () async {
      final n = kEnjoyHashChunkSize;
      final size = 5 * 1024 * 1024;
      final data = Uint8List(size);
      for (var i = 0; i < size; i++) {
        data[i] = (i * 13 + 5) & 0xff;
      }
      final path = p.join(tmp.path, '5mb.bin');
      await File(path).writeAsBytes(data);
      final first = data.sublist(0, n);
      final last = data.sublist(size - n);
      final want = sha256.convert(Uint8List.fromList([...first, ...last])).toString();
      expect(chunkedContentSha256HexFromFileSync(path), want);
    });

    test('12 MiB file uses first, middle, and last 4 MiB', () async {
      final n = kEnjoyHashChunkSize;
      final size = 12 * 1024 * 1024;
      final data = Uint8List(size);
      for (var i = 0; i < size; i++) {
        data[i] = (i * 3 + 19) & 0xff;
      }
      final path = p.join(tmp.path, '12mb.bin');
      await File(path).writeAsBytes(data);
      final middleOffset = (size ~/ 2) - (n ~/ 2);
      final first = data.sublist(0, n);
      final mid = data.sublist(middleOffset, middleOffset + n);
      final last = data.sublist(size - n);
      final want =
          sha256.convert(Uint8List.fromList([...first, ...mid, ...last])).toString();
      expect(chunkedContentSha256HexFromFileSync(path), want);
    });
  });
}
