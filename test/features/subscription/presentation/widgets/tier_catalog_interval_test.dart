import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalogIntervalWire', () {
    test('serializes year to the wire string', () {
      expect(catalogIntervalWire(CatalogInterval.year), 'year');
    });

    test('serializes month to the wire string', () {
      expect(catalogIntervalWire(CatalogInterval.month), 'month');
    });
  });

  group('catalogIntervalFromString', () {
    test('parses the wire month', () {
      expect(catalogIntervalFromString('month'), CatalogInterval.month);
    });

    test('parses the wire year', () {
      expect(catalogIntervalFromString('year'), CatalogInterval.year);
    });

    test('falls back to month when the value is null', () {
      expect(catalogIntervalFromString(null), CatalogInterval.month);
    });

    test('falls back to month for an unknown interval', () {
      expect(catalogIntervalFromString('quarter'), CatalogInterval.month);
    });
  });

  test('wire round-trips year and month', () {
    for (final interval in CatalogInterval.values) {
      expect(
        catalogIntervalFromString(catalogIntervalWire(interval)),
        interval,
        reason: 'interval ${interval.name} should survive the wire round-trip',
      );
    }
  });
}
