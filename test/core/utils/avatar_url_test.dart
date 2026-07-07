import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rasterAvatarUrl', () {
    test('returns null for null or empty input', () {
      expect(rasterAvatarUrl(null), isNull);
      expect(rasterAvatarUrl(''), isNull);
    });

    test('rewrites Dicebear SVG URLs to PNG', () {
      expect(
        rasterAvatarUrl(
          'https://api.dicebear.com/9.x/thumbs/svg?seed=An%20Li',
        ),
        'https://api.dicebear.com/9.x/thumbs/png?seed=An%20Li',
      );
    });

    test('leaves non-Dicebear URLs unchanged', () {
      const yt = 'https://yt3.ggpht.com/abc=s88-c-k-c0x00ffffff-no-rj';
      expect(rasterAvatarUrl(yt), yt);
    });

    test('leaves Dicebear PNG URLs unchanged', () {
      const png =
          'https://api.dicebear.com/9.x/thumbs/png?seed=An%20Li';
      expect(rasterAvatarUrl(png), png);
    });
  });
}
