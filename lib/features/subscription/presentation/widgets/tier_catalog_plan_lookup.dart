/// Catalog-row lookup shared by the tier catalog cards and the unified
/// purchase sheet.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart';

/// Resolves the catalog row for [tier] billed at [interval], or `null` when
/// [plans] holds no matching row — callers fall back to the monthly row or
/// render the price skeleton.
SubscriptionPlan? resolveCatalogPlan(
  List<SubscriptionPlan> plans,
  CatalogInterval interval,
  SubscriptionTier tier,
) {
  final tierName = tier.name;
  for (final plan in plans) {
    if (catalogIntervalFromString(plan.interval) == interval &&
        plan.tier == tierName) {
      return plan;
    }
  }
  return null;
}
