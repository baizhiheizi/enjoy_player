import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_plan_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

SubscriptionPlan plan(String tier, String interval) => SubscriptionPlan(
  id: '$tier-$interval',
  tier: tier,
  interval: interval,
  amount: 9.9,
);

void main() {
  group('resolveCatalogPlan', () {
    test('returns the row matching tier and interval', () {
      final plans = [
        plan('lite', 'month'),
        plan('lite', 'year'),
        plan('pro', 'month'),
      ];
      expect(
        resolveCatalogPlan(plans, CatalogInterval.year, SubscriptionTier.lite),
        same(plans[1]),
      );
    });

    test('returns null when the tier has no row at the interval', () {
      final plans = [plan('lite', 'month'), plan('pro', 'month')];
      expect(
        resolveCatalogPlan(plans, CatalogInterval.year, SubscriptionTier.lite),
        isNull,
      );
    });

    test('returns null for an empty catalog', () {
      expect(
        resolveCatalogPlan(
          const [],
          CatalogInterval.month,
          SubscriptionTier.pro,
        ),
        isNull,
      );
    });

    test('matches the tier wire name, so free never resolves', () {
      final plans = [plan('lite', 'month'), plan('pro', 'month')];
      expect(
        resolveCatalogPlan(plans, CatalogInterval.month, SubscriptionTier.free),
        isNull,
      );
    });

    test('treats an unknown interval string as month', () {
      final plans = [plan('pro', 'quarter')];
      expect(
        resolveCatalogPlan(plans, CatalogInterval.month, SubscriptionTier.pro),
        same(plans[0]),
      );
    });
  });
}
