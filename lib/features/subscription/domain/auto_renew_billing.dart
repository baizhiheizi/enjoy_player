/// Nested auto-renew snapshot from `GET /api/v1/subscriptions`.
library;

class AutoRenewBilling {
  const AutoRenewBilling({
    required this.active,
    required this.provider,
    required this.status,
    required this.autoRenew,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.payUrl,
    this.planId,
    required this.tier,
    required this.interval,
    this.amount,
  });

  factory AutoRenewBilling.fromJson(Map<String, dynamic> json) {
    return AutoRenewBilling(
      active: json['active'] == true,
      provider: json['provider']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      autoRenew: json['autoRenew'] == true,
      currentPeriodEnd: json['currentPeriodEnd'] as String?,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      payUrl: json['payUrl'] as String?,
      planId: json['planId']?.toString(),
      tier: json['tier']?.toString() ?? 'pro',
      interval: json['interval']?.toString() ?? '',
      amount: _numOrNull(json['amount']),
    );
  }

  final bool active;
  final String provider;
  final String status;
  final bool autoRenew;
  final String? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String? payUrl;
  final String? planId;
  final String tier;
  final String interval;
  final num? amount;

  /// Whether the user can request cancel-at-period-end.
  bool get isCancelable =>
      autoRenew &&
      !cancelAtPeriodEnd &&
      status != 'ended' &&
      status != 'canceled';

  bool get isIncomplete => status == 'incomplete';

  Map<String, dynamic> toJson() => {
    'active': active,
    'provider': provider,
    'status': status,
    'autoRenew': autoRenew,
    if (currentPeriodEnd != null) 'currentPeriodEnd': currentPeriodEnd,
    'cancelAtPeriodEnd': cancelAtPeriodEnd,
    if (payUrl != null) 'payUrl': payUrl,
    if (planId != null) 'planId': planId,
    'tier': tier,
    'interval': interval,
    if (amount != null) 'amount': amount,
  };
}

num? _numOrNull(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
