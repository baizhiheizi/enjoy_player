/// Live subscription snapshot from `GET /api/v1/subscriptions`.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_billing.dart';

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
          _subscriptionTierFromJson(json['subscriptionTier']) ??
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

  /// True when the user has a living auto-renew Stripe subscription.
  bool get hasActiveAutoRenewPlan => autoRenew?.isActivelyRenewing ?? false;

  int get dailyCreditsLimit => isPro ? 60_000 : 1_000;

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

SubscriptionTier? _subscriptionTierFromJson(Object? value) {
  if (value == null) return null;
  final s = value.toString().toLowerCase();
  if (s == 'pro') return SubscriptionTier.pro;
  return SubscriptionTier.free;
}
