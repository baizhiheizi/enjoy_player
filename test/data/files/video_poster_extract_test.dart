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

  group('buildVideoPosterFfmpegArgs', () {
    test(
      'local input with accurate seek omits whitelist and seeks after -i',
      () {
        final args = buildVideoPosterFfmpegArgs(
          input: '/local/video.mp4',
          outputJpegPath: '/tmp/out.jpg',
          seekSeconds: 12.3456,
          accurate: true,
        );

        expect(args, isNot(contains('-protocol_whitelist')));
        final inputIdx = args.indexOf('/local/video.mp4');
        final seekIdx = args.indexOf('12.346');
        expect(inputIdx, isPositive);
        expect(seekIdx, greaterThan(inputIdx));
        expect(
          args.sublist(args.length - 5),
          equals(['-frames:v', '1', '-q:v', '3', '/tmp/out.jpg']),
        );
      },
    );

    test('local input with fast seek seeks before -i', () {
      final args = buildVideoPosterFfmpegArgs(
        input: '/local/video.mp4',
        outputJpegPath: '/tmp/out.jpg',
        seekSeconds: 60.0,
        accurate: false,
      );

      expect(args, isNot(contains('-protocol_whitelist')));
      final inputIdx = args.indexOf('/local/video.mp4');
      final seekIdx = args.indexOf('60.000');
      expect(seekIdx, isPositive);
      expect(inputIdx, greaterThan(seekIdx));
    });

    test('network input carries protocol whitelist before -i', () {
      final args = buildVideoPosterFfmpegArgs(
        input: 'https://cdn.example.com/video.mp4',
        outputJpegPath: '/tmp/poster.jpg',
        seekSeconds: 5.0,
        accurate: true,
      );

      final protoIdx = args.indexOf('-protocol_whitelist');
      final inputIdx = args.indexOf('https://cdn.example.com/video.mp4');
      expect(protoIdx, isPositive);
      expect(args[protoIdx + 1], 'file,http,https,tcp,tls,crypto');
      expect(inputIdx, greaterThan(protoIdx));
    });

    test(
      'network input with fast seek carries protocol whitelist before -ss',
      () {
        final args = buildVideoPosterFfmpegArgs(
          input: 'https://cdn.example.com/video.mp4',
          outputJpegPath: '/tmp/poster.jpg',
          seekSeconds: 55.0,
          accurate: false,
        );

        final protoIdx = args.indexOf('-protocol_whitelist');
        final seekIdx = args.indexOf('55.000');
        expect(protoIdx, isPositive);
        expect(seekIdx, greaterThan(protoIdx));
      },
    );
  });
}
