/// Catalog row from `GET /api/v1/subscriptions/plans`.
library;

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.interval,
    required this.amount,
    this.currencyNote,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'pro',
      interval: json['interval']?.toString() ?? '',
      amount: _num(json['amount']),
      currencyNote: json['currencyNote']?.toString(),
    );
  }

  final String id;
  final String tier;
  final String interval;
  final num amount;
  final String? currencyNote;

  bool get isMonthly => interval == 'month';
  bool get isYearly => interval == 'year';

  Map<String, dynamic> toJson() => {
    'id': id,
    'tier': tier,
    'interval': interval,
    'amount': amount,
    if (currencyNote != null) 'currencyNote': currencyNote,
  };
}

num _num(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}
