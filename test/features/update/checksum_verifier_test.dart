import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/update/data/checksum_verifier.dart';

void main() {
  test('verifyFileSha256 matches digest', () async {
    final dir = await Directory.systemTemp.createTemp('enjoy_update_test');
    final file = File('${dir.path}/payload.bin');
    await file.writeAsBytes([1, 2, 3, 4]);
    final expected = sha256HexOfBytes([1, 2, 3, 4]);
    expect(
      await verifyFileSha256(file: file, expectedSha256Hex: expected),
      isTrue,
    );
    await dir.delete(recursive: true);
  });

  test('normalizeSha256Hex rejects invalid hex', () {
    expect(normalizeSha256Hex('not-hex'), isNull);
    expect(normalizeSha256Hex('a' * 64), isNotNull);
  });
}
