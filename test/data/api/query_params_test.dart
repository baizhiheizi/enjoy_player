import 'package:enjoy_player/data/api/query_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildQuery', () {
    test('returns null when all values are null', () {
      expect(buildQuery({'a': null, 'b': null}), isNull);
    });

    test('returns null when the map is empty', () {
      expect(buildQuery(const {}), isNull);
    });

    test('drops null entries but keeps the rest', () {
      expect(
        buildQuery({
          'provider': 'youtube',
          'limit': null,
          'updatedAfter': '2024-01-01',
        }),
        {'provider': 'youtube', 'updatedAfter': '2024-01-01'},
      );
    });

    test('drops empty strings but keeps non-empty ones', () {
      expect(
        buildQuery({
          'startDate': '',
          'endDate': '2024-01-31',
          'serviceType': '  ',
        }),
        {'endDate': '2024-01-31', 'serviceType': '  '},
      );
    });

    test('coerces non-string scalars to their string form', () {
      expect(buildQuery({'limit': 50, 'page': 3, 'flag': true, 'ratio': 0.5}), {
        'limit': '50',
        'page': '3',
        'flag': 'true',
        'ratio': '0.5',
      });
    });

    test('preserves the order of provided keys', () {
      final result = buildQuery({'a': '1', 'b': null, 'c': '3'});
      expect(result, isNotNull);
      expect(result!.map((k, v) => MapEntry(k, v)), {'a': '1', 'c': '3'});
    });
  });
}
