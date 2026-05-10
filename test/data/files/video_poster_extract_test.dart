import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/video_poster_extract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('posterStorageKeyHexForVideo', () {
    final now = DateTime.utc(2020, 1, 2);

    test('prefers md5 when non-empty', () {
      final row = VideoRow(
        id: 'id1',
        vid: 'v',
        provider: 'user',
        title: 't',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 0,
        language: 'und',
        source: null,
        localUri: null,
        md5: 'abc',
        size: null,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      expect(posterStorageKeyHexForVideo(row), 'abc');
    });

    test('falls back to sha256 of id when md5 missing', () {
      final row = VideoRow(
        id: 'my-id',
        vid: 'v',
        provider: 'user',
        title: 't',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 0,
        language: 'und',
        source: null,
        localUri: null,
        md5: null,
        size: null,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      expect(
        posterStorageKeyHexForVideo(row),
        sha256.convert(utf8.encode('my-id')).toString(),
      );
    });
  });

  group('posterSeekSeconds', () {
    test('unknown duration uses ~6s default', () {
      expect(posterSeekSeconds(null), 6.0);
      expect(posterSeekSeconds(0), 6.0);
    });

    test('short clip stays inside duration', () {
      expect(posterSeekSeconds(2), lessThanOrEqualTo(1.95));
      expect(posterSeekSeconds(2), greaterThan(0));
    });

    test('typical clip uses ~12% capped at 90', () {
      expect(posterSeekSeconds(100), closeTo(12.0, 0.01));
      expect(posterSeekSeconds(800), 90.0);
    });
  });
}
