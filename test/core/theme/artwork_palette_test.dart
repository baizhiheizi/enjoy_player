import 'dart:io';

import 'package:enjoy_player/core/theme/dynamic_color/artwork_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFE53935);
const _blue = Color(0xFF1E88E5);

int _mtime(FileStat stat) => stat.modified.millisecondsSinceEpoch;

ArtworkPalette _palette(Color c) => ArtworkPalette(
  dominant: c,
  accent: c,
  onAccent: const Color(0xFF0B0B10),
  vibrant: c,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    debugResetArtworkPaletteCache();
    tmp = await Directory.systemTemp.createTemp('artwork_palette_test_');
  });

  tearDown(() async {
    debugResetArtworkPaletteCache();
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('artworkPaletteCacheKey', () {
    test('encodes path, size and mtime from a real FileStat', () async {
      final path = '${tmp.path}/cover.png';
      await File(path).writeAsBytes(List<int>.filled(128, 0xAA));
      final stat = await File(path).stat();

      final key = artworkPaletteCacheKey(path, stat);
      expect(key.path, path);
      expect(key.size, 128);
      expect(key.mtime, _mtime(stat));
    });

    test('differs when file content (and therefore size) changes', () async {
      final path = '${tmp.path}/cover.png';
      await File(path).writeAsBytes(List<int>.filled(64, 0x10));
      final statSmall = await File(path).stat();

      await File(path).writeAsBytes(List<int>.filled(256, 0x20));
      File(path).setLastModifiedSync(
        DateTime.fromMillisecondsSinceEpoch(_mtime(statSmall) + 2000),
      );
      final statLarge = await File(path).stat();

      final keyA = artworkPaletteCacheKey(path, statSmall);
      final keyB = artworkPaletteCacheKey(path, statLarge);
      expect(keyA, isNot(keyB));
    });

    test('differs when only mtime changes (same byte count)', () async {
      final path = '${tmp.path}/cover.png';
      await File(path).writeAsBytes(List<int>.filled(64, 0x10));
      final statA = await File(path).stat();

      await File(path).writeAsBytes(List<int>.filled(64, 0x10));
      File(path).setLastModifiedSync(
        DateTime.fromMillisecondsSinceEpoch(_mtime(statA) + 3000),
      );
      final statB = await File(path).stat();

      expect(statA.size, statB.size);
      expect(_mtime(statB), greaterThan(_mtime(statA)));

      final keyA = artworkPaletteCacheKey(path, statA);
      final keyB = artworkPaletteCacheKey(path, statB);
      expect(keyA, isNot(keyB));
    });
  });

  group('artwork palette cache invalidation', () {
    test('repeated call for same file returns the cached palette', () async {
      final path = '${tmp.path}/cover.png';
      await File(path).writeAsBytes(List<int>.filled(32, 0x33));
      final stat = await File(path).stat();
      final seeded = _palette(_red);

      debugPutArtworkPalette(path, stat, seeded);

      final hit = debugLookupArtworkPalette(path, stat);
      expect(hit, isNotNull);
      expect(hit, seeded);
      expect(debugArtworkPaletteCacheContainsPath(path), isTrue);
    });

    test(
      're-thumbnailed file (different size) invalidates the entry',
      () async {
        final path = '${tmp.path}/cover.png';
        await File(path).writeAsBytes(List<int>.filled(32, 0x33));
        final stat = await File(path).stat();
        debugPutArtworkPalette(path, stat, _palette(_red));

        await File(path).writeAsBytes(List<int>.filled(1024, 0xEE));
        File(path).setLastModifiedSync(
          DateTime.fromMillisecondsSinceEpoch(_mtime(stat) + 2000),
        );
        final freshStat = await File(path).stat();

        final hit = debugLookupArtworkPalette(path, freshStat);
        expect(hit, isNull, reason: 'stale cache entry must be evicted');
        expect(
          debugArtworkPaletteCacheContainsPath(path),
          isFalse,
          reason: 'all stale entries for this path should be gone',
        );
      },
    );

    test('rewritten file (same size, different mtime) invalidates', () async {
      final path = '${tmp.path}/cover.png';
      await File(path).writeAsBytes(List<int>.filled(32, 0x33));
      final stat = await File(path).stat();
      debugPutArtworkPalette(path, stat, _palette(_red));

      await File(path).writeAsBytes(List<int>.filled(32, 0x77));
      File(path).setLastModifiedSync(
        DateTime.fromMillisecondsSinceEpoch(_mtime(stat) + 2000),
      );
      final freshStat = await File(path).stat();

      expect(_mtime(freshStat), greaterThan(_mtime(stat)));

      final hit = debugLookupArtworkPalette(path, freshStat);
      expect(hit, isNull);
      expect(debugArtworkPaletteCacheContainsPath(path), isFalse);
    });

    test('different paths with identical stats remain independent', () async {
      final pathA = '${tmp.path}/a.png';
      final pathB = '${tmp.path}/b.png';
      await File(pathA).writeAsBytes(List<int>.filled(64, 0x01));
      final statA = await File(pathA).stat();

      debugPutArtworkPalette(pathA, statA, _palette(_blue));
      expect(debugArtworkPaletteCacheContainsPath(pathA), isTrue);

      await File(pathB).writeAsBytes(List<int>.filled(64, 0x02));
      File(
        pathB,
      ).setLastModifiedSync(DateTime.fromMillisecondsSinceEpoch(_mtime(statA)));
      final statB = await File(pathB).stat();

      final hitForB = debugLookupArtworkPalette(pathB, statB);
      expect(statB.size, statA.size, reason: 'sanity: aligned sizes');
      if (_mtime(statB) == _mtime(statA)) {
        expect(hitForB, isNull);
      } else {
        final hitForBExact = debugLookupArtworkPalette(pathB, statA);
        expect(hitForBExact, isNull);
        expect(debugLookupArtworkPalette(pathA, statA), isNotNull);
      }
      expect(debugArtworkPaletteCacheContainsPath(pathA), isTrue);
      expect(debugArtworkPaletteCacheContainsPath(pathB), isFalse);
    });
  });

  group('ArtworkPalette value equality', () {
    test('two palettes with the same colors compare equal', () {
      final a = _palette(_blue);
      final b = _palette(_blue);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different vibrant colors do not compare equal', () {
      final a = _palette(_red);
      final b = _palette(_blue);
      expect(a, isNot(b));
    });
  });

  group('extractArtworkPalette', () {
    test('samples from a decode-resized image, not full resolution', () {
      final file = File('${tmp.path}/cover.png');
      final provider = artworkPaletteImageProvider(file);

      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.width, 200);
      expect(resize.allowUpscaling, isFalse);
      expect(resize.imageProvider, isA<FileImage>());
      expect((resize.imageProvider as FileImage).file, file);
    });

    test('returns null for null or empty input', () async {
      expect(await extractArtworkPalette(null), isNull);
      expect(await extractArtworkPalette(''), isNull);
    });

    test('returns null when the file does not exist', () async {
      final missing = '${tmp.path}/nope.png';
      expect(await extractArtworkPalette(missing), isNull);
      expect(debugArtworkPaletteCacheContainsPath(missing), isFalse);
    });

    test('returns null and does not cache when palette decode fails', () async {
      final path = '${tmp.path}/not-an-image.png';
      await File(path).writeAsBytes(List<int>.filled(64, 0x55));
      final result = await extractArtworkPalette(path);
      expect(result, isNull);
      expect(debugArtworkPaletteCacheContainsPath(path), isFalse);
    });
  });
}
