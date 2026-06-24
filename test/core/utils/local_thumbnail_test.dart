import 'dart:io';

import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localThumbnailFile', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('local_thumbnail_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns null when path is null', () {
      expect(localThumbnailFile(null), isNull);
    });

    test('returns null when path is empty', () {
      expect(localThumbnailFile(''), isNull);
    });

    test('returns null when file does not exist', () {
      final missing = '${tempDir.path}/missing.png';
      expect(localThumbnailFile(missing), isNull);
    });

    test('returns File when file exists', () {
      final file = File('${tempDir.path}/thumb.png');
      file.writeAsBytesSync(<int>[0x89, 0x50, 0x4E, 0x47]);
      final result = localThumbnailFile(file.path);
      expect(result, isNotNull);
      expect(result!.path, file.path);
    });

    test(
      'returns null for whitespace-only path because no such file exists',
      () {
        // Whitespace is not an empty string for `String.isEmpty`, so it falls
        // through to the `File.existsSync` check, which returns null.
        expect(localThumbnailFile('   '), isNull);
      },
    );
  });
}
