import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/video_poster_extract.dart';
import 'package:flutter_test/flutter_test.dart';

VideoRow _row({String id = 'row-id', String? md5, int durationSeconds = 60}) {
  return VideoRow(
    id: id,
    vid: 'vid-1',
    provider: 'user',
    title: 't',
    durationSeconds: durationSeconds,
    language: 'en',
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 1),
    md5: md5,
  );
}

void main() {
  group('posterSeekSeconds', () {
    test('returns 6.0 fallback when duration is null', () {
      expect(posterSeekSeconds(null), 6.0);
    });

    test('returns 6.0 fallback when duration is zero', () {
      expect(posterSeekSeconds(0), 6.0);
    });

    test('returns 6.0 fallback when duration is negative', () {
      expect(posterSeekSeconds(-10), 6.0);
    });

    test('clamps to (duration*0.45).clamp(0.1, d-0.05) for short clips', () {
      expect(posterSeekSeconds(1), closeTo(0.45, 1e-9));
      expect(posterSeekSeconds(2), closeTo(0.9, 1e-9));
    });

    test('uses ~12% of duration for clips longer than 2s', () {
      expect(posterSeekSeconds(10), closeTo(2.5, 1e-9));
      expect(posterSeekSeconds(30), closeTo(3.6, 1e-9));
      expect(posterSeekSeconds(60), closeTo(7.2, 1e-9));
    });

    test('caps at 90s even for very long clips', () {
      expect(posterSeekSeconds(1000), 90.0);
      expect(posterSeekSeconds(800), 90.0);
    });

    test('respects upper bound (duration - 0.25)', () {
      expect(posterSeekSeconds(3), closeTo(2.5, 1e-9));
      expect(posterSeekSeconds(2), closeTo(0.9, 1e-9));
    });
  });

  group('posterStorageKeyHexForVideo', () {
    test('returns the row md5 when it is set and non-empty', () {
      final row = _row(md5: 'deadbeef');
      expect(posterStorageKeyHexForVideo(row), 'deadbeef');
    });

    test('falls back to sha256(id) when md5 is null', () {
      final row = _row(id: 'xyz');
      final expected = sha256.convert(utf8.encode('xyz')).toString();
      expect(posterStorageKeyHexForVideo(row), expected);
    });

    test('falls back to sha256(id) when md5 is the empty string', () {
      final row = _row(id: 'id2', md5: '');
      final expected = sha256.convert(utf8.encode('id2')).toString();
      expect(posterStorageKeyHexForVideo(row), expected);
    });

    test('sha256(id) is 64 hex chars long', () {
      final row = _row(id: 'some-uuid');
      final key = posterStorageKeyHexForVideo(row);
      expect(key, hasLength(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(key), isTrue);
    });

    test('different ids yield different storage keys', () {
      final a = posterStorageKeyHexForVideo(_row(id: 'a'));
      final b = posterStorageKeyHexForVideo(_row(id: 'b'));
      expect(a, isNot(b));
    });
  });
}
