import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/update/domain/semver_compare.dart';

void main() {
  group('compareSemver', () {
    test('orders major.minor.patch', () {
      expect(compareSemver('0.1.0', '0.2.0'), lessThan(0));
      expect(compareSemver('1.0.0', '0.9.9'), greaterThan(0));
      expect(compareSemver('v1.2.3', '1.2.3'), 0);
    });

    test('strips build metadata', () {
      expect(compareSemver('1.0.0+99', '1.0.0+1'), 0);
    });
  });

  group('isVersionLessThan', () {
    test('detects older running version', () {
      expect(isVersionLessThan('0.1.0', '0.2.0'), isTrue);
      expect(isVersionLessThan('0.2.0', '0.1.0'), isFalse);
    });
  });
}
