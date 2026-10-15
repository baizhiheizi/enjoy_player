import 'package:enjoy_player/features/credits/domain/credits_thresholds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('creditsUsedFraction', () {
    test('is 0 when usage is unknown', () {
      expect(creditsUsedFraction(used: null, limit: 1000), 0.0);
    });

    test('is 0 when the pool is empty', () {
      expect(creditsUsedFraction(used: 50, limit: 0), 0.0);
      expect(creditsUsedFraction(used: null, limit: 0), 0.0);
    });

    test('is 0 when nothing is used', () {
      expect(creditsUsedFraction(used: 0, limit: 1000), 0.0);
    });

    test('is 1 when the pool is exhausted', () {
      expect(creditsUsedFraction(used: 1000, limit: 1000), 1.0);
    });

    test('clamps overuse to 1', () {
      expect(creditsUsedFraction(used: 1200, limit: 1000), 1.0);
    });

    test('is the used share mid-pool', () {
      expect(creditsUsedFraction(used: 450, limit: 1000), 0.45);
    });
  });

  group('creditsLow', () {
    test('is false for unknown usage or an empty pool', () {
      expect(creditsLow(used: null, limit: 1000), isFalse);
      expect(creditsLow(used: 500, limit: 0), isFalse);
      expect(creditsLow(used: null, limit: 0), isFalse);
    });

    test('is false below the threshold', () {
      expect(creditsLow(used: 899, limit: 1000), isFalse);
    });

    test('is true at and above the threshold', () {
      expect(creditsLow(used: 900, limit: 1000), isTrue);
      expect(creditsLow(used: 1000, limit: 1000), isTrue);
    });

    test('matches the remaining-credits formulation used by the chip', () {
      const limit = 12000;
      const remaining = 1000;
      final used = limit - remaining.clamp(0, limit);
      expect(
        creditsLow(used: used, limit: limit),
        1 - remaining / limit >= kLowCreditsUsedFraction,
      );
    });
  });
}
