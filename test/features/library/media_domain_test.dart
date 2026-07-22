import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';

Media _media({
  String id = 'm1',
  MediaKind kind = MediaKind.video,
  String title = 'Test',
  String sourceUri = '/tmp/test.mp4',
  String? thumbnailPath,
  int durationMs = 60000,
  String language = 'en',
  String contentHash = 'abc123',
  int fileSize = 1024,
  String? mediaUrl,
  String? source,
  String provider = 'user',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Media(
    id: id,
    kind: kind,
    title: title,
    sourceUri: sourceUri,
    thumbnailPath: thumbnailPath,
    durationMs: durationMs,
    language: language,
    contentHash: contentHash,
    fileSize: fileSize,
    mediaUrl: mediaUrl,
    source: source,
    provider: provider,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MediaKindX', () {
    test('storageValue returns lowercase kind', () {
      expect(MediaKind.audio.storageValue, 'audio');
      expect(MediaKind.video.storageValue, 'video');
    });

    test('dexieTargetType returns capitalized kind', () {
      expect(MediaKind.audio.dexieTargetType, 'Audio');
      expect(MediaKind.video.dexieTargetType, 'Video');
    });

    test('fromStorage parses video', () {
      expect(MediaKindX.fromStorage('video'), MediaKind.video);
    });

    test('fromStorage defaults to audio for unknown', () {
      expect(MediaKindX.fromStorage('audio'), MediaKind.audio);
      expect(MediaKindX.fromStorage('unknown'), MediaKind.audio);
      expect(MediaKindX.fromStorage(''), MediaKind.audio);
    });
  });

  group('Media equality', () {
    test('equal instances are equal', () {
      final a = _media();
      final b = _media();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id means not equal', () {
      final a = _media(id: 'm1');
      final b = _media(id: 'm2');
      expect(a, isNot(equals(b)));
    });

    test('different kind means not equal', () {
      final a = _media(kind: MediaKind.video);
      final b = _media(kind: MediaKind.audio);
      expect(a, isNot(equals(b)));
    });

    test('identical returns true', () {
      final a = _media();
      expect(a == a, isTrue);
    });
  });

  group('MediaSourceKind', () {
    test('isLink true when mediaUrl is non-empty', () {
      final m = _media(mediaUrl: 'https://example.com/video.mp4');
      expect(m.isLink, isTrue);
      expect(m.isLocal, isFalse);
    });

    test('isLink false when mediaUrl is null', () {
      final m = _media(mediaUrl: null);
      expect(m.isLink, isFalse);
      expect(m.isLocal, isTrue);
    });

    test('isLink false when mediaUrl is empty', () {
      final m = _media(mediaUrl: '');
      expect(m.isLink, isFalse);
      expect(m.isLocal, isTrue);
    });
  });

  group('MediaCoverSeed', () {
    test('hasThumbnailPath true for non-empty path', () {
      final m = _media(thumbnailPath: '/tmp/thumb.jpg');
      expect(m.hasThumbnailPath, isTrue);
    });

    test('hasThumbnailPath false for null', () {
      final m = _media(thumbnailPath: null);
      expect(m.hasThumbnailPath, isFalse);
    });

    test('hasThumbnailPath false for whitespace-only', () {
      final m = _media(thumbnailPath: '   ');
      expect(m.hasThumbnailPath, isFalse);
    });

    test('coverSeed uses contentHash when non-empty', () {
      final m = _media(contentHash: 'hash123');
      expect(m.coverSeed, 'hash123');
    });

    test('coverSeed falls back to id when contentHash is empty', () {
      final m = _media(id: 'media-1', contentHash: '');
      expect(m.coverSeed, 'media-1');
    });

    test('coverSeed falls back to id when contentHash is whitespace', () {
      final m = _media(id: 'media-1', contentHash: '  ');
      expect(m.coverSeed, 'media-1');
    });
  });

  group('Media getters', () {
    test('vidOrAid returns contentHash', () {
      final m = _media(contentHash: 'vid123');
      expect(m.vidOrAid, 'vid123');
    });

    test('dexieTargetType delegates to kind', () {
      final v = _media(kind: MediaKind.video);
      final a = _media(kind: MediaKind.audio);
      expect(v.dexieTargetType, 'Video');
      expect(a.dexieTargetType, 'Audio');
    });
  });
}
