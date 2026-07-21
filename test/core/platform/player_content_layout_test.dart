import 'package:enjoy_player/core/platform/player_content_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('usePlayerSideBySideLayout', () {
    test('landscape is side-by-side', () {
      expect(usePlayerSideBySideLayout(width: 900, height: 600), isTrue);
      expect(usePlayerSideBySideLayout(width: 700, height: 400), isTrue);
    });

    test('portrait is stacked including wide portrait', () {
      expect(usePlayerSideBySideLayout(width: 800, height: 1000), isFalse);
      expect(usePlayerSideBySideLayout(width: 500, height: 700), isFalse);
    });

    test('square is stacked', () {
      expect(usePlayerSideBySideLayout(width: 600, height: 600), isFalse);
    });
  });
}
