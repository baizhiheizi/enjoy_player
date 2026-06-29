/// Learning statistics from `GET /api/v1/mine/stats` (camelCase JSON).
library;

/// Nested maps from [decodeJsonToCamel] are [Map<dynamic, dynamic>], not
/// [Map<String, dynamic>], so strict `is Map<String, dynamic>` loses `today` /
/// `week` / `month` and stats read as zero.
Map<String, dynamic>? _jsonObjectAsStringMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
  return null;
}

class PeriodStats {
  const PeriodStats({
    required this.recordingDurationMs,
    required this.recordingCount,
  });

  final int recordingDurationMs;
  final int recordingCount;

  static PeriodStats zero() =>
      const PeriodStats(recordingDurationMs: 0, recordingCount: 0);

  static PeriodStats fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return PeriodStats.zero();
    final dur = json['recordingDuration'];
    final durMs = dur is num ? dur.round() : int.tryParse('$dur') ?? 0;
    final cnt = json['recordingCount'];
    final count = cnt is num ? cnt.round() : int.tryParse('$cnt') ?? 0;
    return PeriodStats(recordingDurationMs: durMs, recordingCount: count);
  }
}

class LearningStatistics {
  factory LearningStatistics.fromJson(Map<String, dynamic> json) {
    return LearningStatistics(
      today: PeriodStats.fromJson(_jsonObjectAsStringMap(json['today'])),
      week: PeriodStats.fromJson(_jsonObjectAsStringMap(json['week'])),
      month: PeriodStats.fromJson(_jsonObjectAsStringMap(json['month'])),
    );
  }
  const LearningStatistics({
    required this.today,
    required this.week,
    required this.month,
  });

  final PeriodStats today;
  final PeriodStats week;
  final PeriodStats month;

  static LearningStatistics empty() => LearningStatistics(
    today: PeriodStats.zero(),
    week: PeriodStats.zero(),
    month: PeriodStats.zero(),
  );
}
