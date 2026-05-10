import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enjoyLocalAudioAid matches sha256(contentHash:userId) hex', () {
    const content = 'abc123';
    const user = 'u1';
    final want = sha256.convert(utf8.encode('$content:$user')).toString();
    expect(enjoyLocalAudioAid(contentHashHex: content, userId: user), want);
  });

  test('enjoyAudioId is stable for a given aid', () {
    const aid = '010203';
    final a = enjoyAudioId(aid: aid);
    final b = enjoyAudioId(aid: aid);
    expect(a, b);
    expect(a.length, 36);
  });
}
