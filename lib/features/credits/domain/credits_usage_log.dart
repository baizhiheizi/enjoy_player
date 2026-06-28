/// One row from Worker `GET /credits/usages` (`logs[]`).
library;

class CreditsUsageLog {
  factory CreditsUsageLog.fromJson(Map<String, dynamic> json) {
    final metaRaw = json['meta'];
    Map<String, Object?>? meta;
    if (metaRaw is Map) {
      meta = metaRaw.map((k, v) => MapEntry(k.toString(), v as Object?));
    }

    return CreditsUsageLog(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      timestampMs: _intFromJson(json['timestamp']) ?? 0,
      serviceType: json['serviceType']?.toString() ?? '',
      tier: json['tier']?.toString() ?? '',
      creditsRequired: _intFromJson(json['required']) ?? 0,
      usedBefore: _intFromJson(json['usedBefore']) ?? 0,
      usedAfter: _intFromJson(json['usedAfter']) ?? 0,
      allowed: _boolFromJson(json['allowed']) ?? false,
      meta: meta,
    );
  }
  const CreditsUsageLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.timestampMs,
    required this.serviceType,
    required this.tier,
    required this.creditsRequired,
    required this.usedBefore,
    required this.usedAfter,
    required this.allowed,
    this.meta,
  });

  final String id;
  final String userId;

  /// UTC calendar date `YYYY-MM-DD`.
  final String date;
  final int timestampMs;
  final String serviceType;
  final String tier;
  final int creditsRequired;
  final int usedBefore;
  final int usedAfter;
  final bool allowed;
  final Map<String, Object?>? meta;
}

int? _intFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _boolFromJson(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}
