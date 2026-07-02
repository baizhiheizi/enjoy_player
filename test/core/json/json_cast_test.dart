import 'package:enjoy_player/core/json/json_cast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('castJsonObjectOrNull', () {
    test('returns a Map<String, dynamic> as-is', () {
      final input = <String, dynamic>{'a': 1};
      expect(identical(castJsonObjectOrNull(input), input), isTrue);
    });

    test('re-keys a Map<dynamic, dynamic> via toString', () {
      final input = <dynamic, dynamic>{'a': 1, 'b': 2};
      final result = castJsonObjectOrNull(input);
      expect(result, {'a': 1, 'b': 2});
    });

    test('returns null for null', () {
      expect(castJsonObjectOrNull(null), isNull);
    });

    test('returns null for a non-Map value', () {
      expect(castJsonObjectOrNull('not a map'), isNull);
      expect(castJsonObjectOrNull(42), isNull);
      expect(castJsonObjectOrNull(<dynamic>[1, 2]), isNull);
    });
  });

  group('castJsonObject', () {
    test('returns a Map<String, dynamic> as-is', () {
      final input = <String, dynamic>{'a': 1};
      expect(identical(castJsonObject(input), input), isTrue);
    });

    test('re-keys a Map<dynamic, dynamic> via toString', () {
      final input = <dynamic, dynamic>{'a': 1};
      expect(castJsonObject(input), {'a': 1});
    });

    test('throws FormatException for null', () {
      expect(() => castJsonObject(null), throwsFormatException);
    });

    test('throws FormatException for a non-Map value', () {
      expect(() => castJsonObject('nope'), throwsFormatException);
    });
  });
}
