/// Learning statistics from `GET /api/v1/mine/stats` (camelCase JSON).
library;

import 'package:enjoy_player/core/json/json_cast.dart';

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
      // Nested maps from decodeJsonToCamel may be Map<dynamic, dynamic>; see
      // castJsonObjectOrNull doc for why a strict `is Map<String, dynamic>`
      // check would silently read `today` / `week` / `month` as zero.
      today: PeriodStats.fromJson(castJsonObjectOrNull(json['today'])),
      week: PeriodStats.fromJson(castJsonObjectOrNull(json['week'])),
      month: PeriodStats.fromJson(castJsonObjectOrNull(json['month'])),
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
