import 'package:enjoy_player/core/utils/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listEquals', () {
    test('identical lists are equal', () {
      final a = [1, 2, 3];
      expect(listEquals(a, a), isTrue);
    });

    test('equal elements are equal', () {
      expect(listEquals([1, 2], [1, 2]), isTrue);
    });

    test('different lengths are not equal', () {
      expect(listEquals([1], [1, 2]), isFalse);
    });

    test('different elements are not equal', () {
      expect(listEquals(['a', 'b'], ['a', 'c']), isFalse);
    });
  });
}
