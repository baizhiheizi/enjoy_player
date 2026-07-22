/// Worker `GET /credits/summary` wallet standing.
library;

class CreditsSummary {
  const CreditsSummary({
    required this.tier,
    required this.dailyUsed,
    required this.dailyLimit,
    required this.dailyRemaining,
    required this.permanentAvailable,
    required this.resetAt,
  });

  factory CreditsSummary.fromJson(Map<String, dynamic> json) {
    return CreditsSummary(
      tier: json['tier']?.toString() ?? '',
      dailyUsed: _int(json['dailyUsed']),
      dailyLimit: _int(json['dailyLimit']),
      dailyRemaining: _int(json['dailyRemaining']),
      permanentAvailable: _int(json['permanentAvailable']),
      resetAt: _int(json['resetAt']),
    );
  }

  final String tier;
  final int dailyUsed;
  final int dailyLimit;
  final int dailyRemaining;
  final int permanentAvailable;
  final int resetAt;

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'dailyUsed': dailyUsed,
    'dailyLimit': dailyLimit,
    'dailyRemaining': dailyRemaining,
    'permanentAvailable': permanentAvailable,
    'resetAt': resetAt,
  };
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
