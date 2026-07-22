import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/core/utils/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listEquals', () {
    test('returns true for identical lists', () {
      final list = [1, 2, 3];
      expect(listEquals(list, list), isTrue);
    });

    test('returns true for equal content', () {
      expect(listEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('returns false for different lengths', () {
      expect(listEquals([1, 2], [1, 2, 3]), isFalse);
    });

    test('returns false for different elements', () {
      expect(listEquals([1, 2, 3], [1, 2, 4]), isFalse);
    });

    test('returns true for two empty lists', () {
      expect(listEquals(<int>[], <int>[]), isTrue);
    });

    test('works with strings', () {
      expect(listEquals(['a', 'b'], ['a', 'b']), isTrue);
      expect(listEquals(['a', 'b'], ['a', 'c']), isFalse);
    });
  });

  group('rasterAvatarUrl', () {
    test('returns null for null input', () {
      expect(rasterAvatarUrl(null), isNull);
    });

    test('returns null for empty string', () {
      expect(rasterAvatarUrl(''), isNull);
    });

    test('rewrites dicebear svg to png', () {
      expect(
        rasterAvatarUrl('https://api.dicebear.com/7.x/thumbs/svg?seed=abc'),
        'https://api.dicebear.com/7.x/thumbs/png?seed=abc',
      );
    });

    test('leaves non-dicebear urls unchanged', () {
      const url = 'https://example.com/avatar.png';
      expect(rasterAvatarUrl(url), url);
    });

    test('leaves dicebear non-svg paths unchanged', () {
      const url = 'https://api.dicebear.com/7.x/thumbs/png?seed=abc';
      expect(rasterAvatarUrl(url), url);
    });

    test('returns original for unparseable url', () {
      const url = 'not a url :: invalid';
      expect(rasterAvatarUrl(url), url);
    });
  });
}
