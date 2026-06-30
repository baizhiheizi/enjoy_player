/// Live subscription snapshot from `GET /api/v1/subscriptions`.
library;

import 'package:enjoy_player/features/auth/domain/user_profile.dart';

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.subscriptionActive,
    required this.subscriptionTier,
    this.subscriptionExpireDate,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscriptionActive: json['subscriptionActive'] == true,
      subscriptionTier:
          _subscriptionTierFromJson(json['subscriptionTier']) ??
          SubscriptionTier.free,
      subscriptionExpireDate: json['subscriptionExpireDate'] as String?,
    );
  }

  final bool subscriptionActive;
  final SubscriptionTier subscriptionTier;
  final String? subscriptionExpireDate;

  bool get isPro =>
      subscriptionTier == SubscriptionTier.pro && subscriptionActive;

  int get dailyCreditsLimit =>
      subscriptionTier == SubscriptionTier.pro ? 60_000 : 1_000;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'subscriptionActive': subscriptionActive,
      'subscriptionTier': subscriptionTier.name,
      if (subscriptionExpireDate != null)
        'subscriptionExpireDate': subscriptionExpireDate,
    };
  }
}

SubscriptionTier? _subscriptionTierFromJson(Object? value) {
  if (value == null) return null;
  final s = value.toString().toLowerCase();
  if (s == 'pro') return SubscriptionTier.pro;
  return SubscriptionTier.free;
}
