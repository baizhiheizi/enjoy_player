/// Live subscription snapshot from `GET /api/v1/subscriptions`.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_billing.dart';

/// The tier daily-credit table — the single source of truth for the
/// entitlement mapping. [SubscriptionStatus.dailyCreditsLimit] gates the
/// paid tiers behind [SubscriptionStatus.isPaidTier]; cold-start call sites
/// (profile credits card, lookup sheet chip) read the bare tier until the
/// live status resolves.
int dailyCreditsLimitForTier(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.pro:
      return 60000;
    case SubscriptionTier.lite:
      return 12000;
    case SubscriptionTier.free:
      return 1000;
  }
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.subscriptionActive,
    required this.subscriptionTier,
    this.subscriptionExpireDate,
    this.autoRenew,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final autoRenewRaw = json['autoRenew'];
    AutoRenewBilling? autoRenew;
    if (autoRenewRaw is Map) {
      autoRenew = AutoRenewBilling.fromJson(
        Map<String, dynamic>.from(autoRenewRaw),
      );
    }
    return SubscriptionStatus(
      subscriptionActive: json['subscriptionActive'] == true,
      subscriptionTier:
          subscriptionTierFromJson(json['subscriptionTier']) ??
          SubscriptionTier.free,
      subscriptionExpireDate: json['subscriptionExpireDate'] as String?,
      autoRenew: autoRenew,
    );
  }

  final bool subscriptionActive;
  final SubscriptionTier subscriptionTier;
  final String? subscriptionExpireDate;
  final AutoRenewBilling? autoRenew;

  bool get isPro =>
      subscriptionTier == SubscriptionTier.pro && subscriptionActive;

  bool get isLite =>
      subscriptionTier == SubscriptionTier.lite && subscriptionActive;

  bool get isPaidTier => isPro || isLite;

  /// True when the user has a living auto-renew Stripe subscription.
  bool get hasActiveAutoRenewPlan => autoRenew?.isActivelyRenewing ?? false;

  int get dailyCreditsLimit => dailyCreditsLimitForTier(
    isPaidTier ? subscriptionTier : SubscriptionTier.free,
  );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subscriptionActive': subscriptionActive,
      'subscriptionTier': subscriptionTier.name,
      if (subscriptionExpireDate != null)
        'subscriptionExpireDate': subscriptionExpireDate,
      if (autoRenew != null) 'autoRenew': autoRenew!.toJson(),
    };
  }
}
