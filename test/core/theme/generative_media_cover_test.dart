import 'package:enjoy_player/core/theme/generative_media_cover.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('coverHash', () {
    test('is stable for a sample seed', () {
      const s = 'abc123deadbeef';
      expect(coverHash(s), coverHash(s));
    });

    test('spreads ids that share a prefix', () {
      expect(coverHash('media-1'), isNot(coverHash('media-2')));
      expect(
        coverHash('media-1') % kGeneratedCoverPalettes.length,
        isNot(coverHash('media-2') % kGeneratedCoverPalettes.length),
        reason:
            'nearby ids should not systematically collapse onto one '
            'palette, though a collision is legal',
      );
    });
  });

  group('generativeAccentForSeed', () {
    test('deterministic per seed', () {
      expect(
        generativeAccentForSeed('same').toARGB32(),
        generativeAccentForSeed('same').toARGB32(),
      );
      expect(
        generativeAccentForSeed('a').toARGB32(),
        isNot(generativeAccentForSeed('b').toARGB32()),
      );
    });
  });
}
