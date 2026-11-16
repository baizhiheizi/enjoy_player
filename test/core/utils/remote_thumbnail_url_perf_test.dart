import 'dart:math';

import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:flutter_test/flutter_test.dart';

String? legacyResolveVideoId({
  String? youtubeVideoId,
  String? thumbnailPath,
  String? mediaUrl,
}) {
  final fromArg = parseYoutubeVideoId(youtubeVideoId ?? '');
  if (fromArg != null) return fromArg;
  final fromThumb = youtubeVideoIdFromThumbnailUrl(thumbnailPath);
  if (fromThumb != null) return fromThumb;
  return parseYoutubeVideoId(mediaUrl ?? '');
}

String? legacyRemoteThumbnailForCard(
  String? thumbnailPath, {
  String? youtubeVideoId,
  String? mediaUrl,
}) {
  final videoId = legacyResolveVideoId(
    youtubeVideoId: youtubeVideoId,
    thumbnailPath: thumbnailPath,
    mediaUrl: mediaUrl,
  );
  if (videoId != null) {
    return youtubeMaxResThumbnailUrl(videoId);
  }
  return isRemoteThumbnailUrl(thumbnailPath) ? thumbnailPath : null;
}

typedef ThumbTuple = (String?, String?, String?);

final Random fuzzRandom = Random(20261116);

String id11(int seed, [String prefix = 'bid']) =>
    '$prefix${seed.toRadixString(36).padLeft(8, '0')}';

String ytimgThumb(String vid) => 'https://i.ytimg.com/vi/$vid/hqdefault.jpg';

String watchUrl(String vid) => 'https://www.youtube.com/watch?v=$vid';

String? _pickThumb(int shape, int seed) {
  return switch (shape % 10) {
    0 || 4 || 9 => ytimgThumb(id11(seed)),
    1 => null,
    2 => 'https://cdn.example/$seed/card.jpg',
    3 => 'C:\\local\\$seed.jpg',
    5 => '$seed.jpg',
    6 => 'file:///local/$seed.jpg',
    7 => 'http://cdn.example/$seed/cover.png',
    _ => '/relative/path/$seed.jpg',
  };
}

String? _pickVideoIdArg(int shape, int seed) {
  return switch (shape % 10) {
    1 => id11(seed),
    6 => 'short-$seed',
    _ => null,
  };
}

String? _pickMediaUrl(int shape, int seed) {
  return switch (shape % 10) {
    4 => watchUrl(id11(seed)),
    7 => 'https://youtu.be/${id11(seed)}',
    8 => 'https://vimeo.com/$seed',
    _ => null,
  };
}

List<ThumbTuple> fuzzTuples({required int count, int offset = 0}) {
  return [
    for (var i = 0; i < count; i++)
      (
        _pickThumb(i, offset + i),
        _pickVideoIdArg(i, offset + i),
        _pickMediaUrl(i, offset + i),
      ),
  ];
}

void main() {
  group('differential: memoized derivation equals the fresh derivation', () {
    test('curated edge inputs', () {
      final edges = <ThumbTuple>[
        (null, null, null),
        ('', null, null),
        (r'C:\a.jpg', null, null),
        ('file:///x/y.jpg', null, null),
        ('/tmp/a.jpg', null, null),
        ('https://x/a.jpg', null, null),
        ('http://x/a.jpg', null, null),
        ('https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg', null, null),
        ('https://i.ytimg.com/vi/short/hq.jpg', null, null),
        (null, 'dQw4w9WgXcQ', null),
        (null, 'not-an-id', null),
        (null, null, watchUrl('dQw4w9WgXcQ')),
        (null, null, 'https://youtu.be/dQw4w9WgXcQ'),
        (null, null, 'https://www.youtube.com/embed/dQw4w9WgXcQ'),
        (null, null, 'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        (null, null, 'https://example.com/video/123'),
        (r'C:\a.jpg', 'dQw4w9WgXcQ', null),
        ('https://x/a.jpg', 'not-an-id', watchUrl('dQw4w9WgXcQ')),
      ];
      for (final (thumb, vidArg, mediaUrl) in edges) {
        expect(
          remoteThumbnailForCard(
            thumb,
            youtubeVideoId: vidArg,
            mediaUrl: mediaUrl,
          ),
          legacyRemoteThumbnailForCard(
            thumb,
            youtubeVideoId: vidArg,
            mediaUrl: mediaUrl,
          ),
          reason: 'thumb=$thumb vidArg=$vidArg mediaUrl=$mediaUrl',
        );
      }
    });

    test('fuzz corpus across all input shapes', () {
      for (final (thumb, vidArg, mediaUrl) in fuzzTuples(count: 800)) {
        final actual = remoteThumbnailForCard(
          thumb,
          youtubeVideoId: vidArg,
          mediaUrl: mediaUrl,
        );
        final oracle = legacyRemoteThumbnailForCard(
          thumb,
          youtubeVideoId: vidArg,
          mediaUrl: mediaUrl,
        );
        expect(actual, oracle, reason: 'thumb=$thumb vidArg=$vidArg');
      }
    });

    test('repeat calls stay stable', () {
      const thumb = 'https://pin-stable.example/repeat.jpg';
      final first = remoteThumbnailForCard(thumb);
      for (var i = 0; i < 5; i++) {
        expect(remoteThumbnailForCard(thumb), first);
      }
      final derived = legacyRemoteThumbnailForCard(
        ytimgThumb(id11(777, 'sta')),
      );
      for (var i = 0; i < 5; i++) {
        expect(remoteThumbnailForCard(ytimgThumb(id11(777, 'sta'))), derived);
      }
    });
  });

  group('structural: derivation counts', () {
    test('derives once per content; repeat calls share the instance', () {
      const thumb = 'https://pin-one.example/once.jpg';
      remoteThumbnailDerivationCount = 0;
      final first = remoteThumbnailForCard(thumb);
      expect(first, thumb);
      expect(remoteThumbnailDerivationCount, 1);
      for (var i = 0; i < 10; i++) {
        expect(remoteThumbnailForCard(thumb), same(first));
      }
      expect(remoteThumbnailDerivationCount, 1);
    });

    test('equal-content key hits the memo', () {
      final thumb = ytimgThumb(id11(4242, 'cpy'));
      remoteThumbnailDerivationCount = 0;
      final first = remoteThumbnailForCard(thumb);
      final second = remoteThumbnailForCard(
        String.fromCharCodes(thumb.codeUnits),
      );
      expect(remoteThumbnailDerivationCount, 1);
      expect(second, same(first));
    });

    test('distinct tuple re-derives', () {
      final vid = id11(9090, 'dst');
      remoteThumbnailDerivationCount = 0;
      remoteThumbnailForCard(null, youtubeVideoId: vid);
      remoteThumbnailForCard(null, youtubeVideoId: vid);
      expect(remoteThumbnailDerivationCount, 1);
      remoteThumbnailForCard(
        null,
        youtubeVideoId: vid,
        mediaUrl: watchUrl(vid),
      );
      expect(remoteThumbnailDerivationCount, 2);
    });

    test('null results are cached too', () {
      const thumb = r'C:\pin-null\none.jpg';
      remoteThumbnailDerivationCount = 0;
      expect(remoteThumbnailForCard(thumb), isNull);
      expect(remoteThumbnailForCard(thumb), isNull);
      expect(remoteThumbnailDerivationCount, 1);
    });

    test('null and empty thumbnails both derive null', () {
      expect(remoteThumbnailForCard(null), isNull);
      expect(remoteThumbnailForCard(''), isNull);
    });

    test('the 257th distinct tuple evicts the LRU head', () {
      remoteThumbnailDerivationCount = 0;
      for (var i = 0; i < 256; i++) {
        remoteThumbnailForCard('https://evict-fill.example/$i.jpg');
      }
      expect(remoteThumbnailDerivationCount, 256);
      remoteThumbnailForCard('https://evict-fill.example/256.jpg');
      expect(remoteThumbnailDerivationCount, 257);
      remoteThumbnailForCard('https://evict-fill.example/0.jpg');
      expect(remoteThumbnailDerivationCount, 258);
      remoteThumbnailForCard('https://evict-fill.example/256.jpg');
      expect(remoteThumbnailDerivationCount, 258);
    });
  });

  List<ThumbTuple> rebuildTuples() {
    return [
      for (var i = 0; i < 10; i++) ...[
        (ytimgThumb(id11(i, 'rbc')), null, null),
        (null, id11(i, 'rbd'), null),
        ('https://cdn.example/rebuild/$i/card.jpg', null, null),
        ('C:\\local\\rebuild\\$i.jpg', null, null),
        (ytimgThumb(id11(i, 'rbe')), id11(i, 'rbe'), watchUrl(id11(i, 'rbe'))),
      ],
    ];
  }

  String? freshCopy(String? s) =>
      s == null ? null : String.fromCharCodes(s.codeUnits);

  int runRebuildPass(
    List<ThumbTuple> tuples,
    String? Function(ThumbTuple) call,
  ) {
    var sink = 0;
    for (final (thumb, vidArg, mediaUrl) in tuples) {
      sink += call((thumb, vidArg, mediaUrl))?.length ?? 0;
    }
    return sink;
  }

  List<String?> discoverThumbs() {
    return [
      for (var i = 0; i < 10; i++) ...[
        ytimgThumb(id11(i, 'dsc')),
        'https://cdn.example/discover/$i/card.jpg',
        'C:\\local\\discover\\$i.jpg',
        '/relative/discover/$i.jpg',
        'http://cdn.example/discover/$i/cover.png',
      ],
    ];
  }

  int runThumbPass(List<String?> thumbs, String? Function(String?) call) {
    var sink = 0;
    for (final thumb in thumbs) {
      sink += call(thumb)?.length ?? 0;
    }
    return sink;
  }

  const int benchPasses = 200;

  test(
    'bench (local only): legacy derive, $benchPasses rebuild passes over 50 '
    'discover paths',
    skip: true,
    () {
      final thumbs = discoverThumbs();
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runThumbPass(thumbs, legacyRemoteThumbnailForCard);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runThumbPass(thumbs, legacyRemoteThumbnailForCard);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy discover rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized derive, $benchPasses rebuild passes over 50 '
    'discover paths',
    skip: true,
    () {
      final thumbs = discoverThumbs();
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runThumbPass(thumbs, remoteThumbnailForCard);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runThumbPass(thumbs, remoteThumbnailForCard);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized discover rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized derive, $benchPasses copy-key discover '
    'passes',
    skip: true,
    () {
      final thumbs = discoverThumbs();
      String? copyCall(String? thumb) =>
          remoteThumbnailForCard(freshCopy(thumb));
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runThumbPass(thumbs, copyCall);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runThumbPass(thumbs, copyCall);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized copy-key discover rebuild: '
        '${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): legacy derive, $benchPasses rebuild passes over 50 tuples',
    skip: true,
    () {
      final tuples = rebuildTuples();
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runRebuildPass(
          tuples,
          (t) => legacyRemoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runRebuildPass(
          tuples,
          (t) => legacyRemoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy tuple rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized derive, $benchPasses rebuild passes over 50 tuples',
    skip: true,
    () {
      final tuples = rebuildTuples();
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runRebuildPass(
          tuples,
          (t) => remoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runRebuildPass(
          tuples,
          (t) => remoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized tuple rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized derive, $benchPasses copy-key rebuild passes',
    skip: true,
    () {
      final tuples = rebuildTuples();
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runRebuildPass(
          tuples,
          (t) => remoteThumbnailForCard(
            freshCopy(t.$1),
            youtubeVideoId: freshCopy(t.$2),
            mediaUrl: freshCopy(t.$3),
          ),
        );
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runRebuildPass(
          tuples,
          (t) => remoteThumbnailForCard(
            freshCopy(t.$1),
            youtubeVideoId: freshCopy(t.$2),
            mediaUrl: freshCopy(t.$3),
          ),
        );
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized copy-key rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): legacy derive, 512-distinct sweep, $benchPasses passes',
    skip: true,
    () {
      var sink = 0;
      var pass = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runRebuildPass(
          fuzzTuples(count: 512, offset: 100000 + pass++ * 512),
          (t) => legacyRemoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runRebuildPass(
          fuzzTuples(count: 512, offset: 100000 + pass++ * 512),
          (t) => legacyRemoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy sweep: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized derive, 512-distinct sweep, $benchPasses passes',
    skip: true,
    () {
      var sink = 0;
      var pass = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runRebuildPass(
          fuzzTuples(count: 512, offset: 100000 + pass++ * 512),
          (t) => remoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runRebuildPass(
          fuzzTuples(count: 512, offset: 100000 + pass++ * 512),
          (t) => remoteThumbnailForCard(
            t.$1,
            youtubeVideoId: t.$2,
            mediaUrl: t.$3,
          ),
        );
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized sweep: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      ); // ignore: avoid_print
    },
  );
}
