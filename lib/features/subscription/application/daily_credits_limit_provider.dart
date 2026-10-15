/// Single source of truth for the daily credits limit shown in UI.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';

part 'daily_credits_limit_provider.g.dart';

/// The active daily credits limit: the live [SubscriptionStatus] value when
/// resolved, otherwise the tier table for the [currentTierProvider] tier.
///
/// Every meter / chip / usage surface reads this provider rather than
/// re-deriving `status?.dailyCreditsLimit ?? dailyCreditsLimitForTier(tier)`.
@Riverpod(keepAlive: true)
int dailyCreditsLimit(Ref ref) {
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  final tier = ref.watch(currentTierProvider);
  return status?.dailyCreditsLimit ?? dailyCreditsLimitForTier(tier);
}
