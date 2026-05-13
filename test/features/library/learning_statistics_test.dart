import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/api/case_conversion.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';

void main() {
  test('LearningStatistics.fromJson reads periods after convertKeysToCamel '
      '(nested Map<dynamic, dynamic>)', () {
    final decoded = convertKeysToCamel({
      'today': {'recording_duration': 125_000, 'recording_count': 2},
      'week': {'recording_duration': 200_000, 'recording_count': 3},
      'month': {'recording_duration': 900_000, 'recording_count': 10},
    });
    final json = Map<String, dynamic>.from(
      (decoded as Map).map((k, v) => MapEntry(k.toString(), v)),
    );

    final stats = LearningStatistics.fromJson(json);

    expect(stats.today.recordingDurationMs, 125_000);
    expect(stats.today.recordingCount, 2);
    expect(stats.week.recordingDurationMs, 200_000);
    expect(stats.month.recordingCount, 10);
  });
}
