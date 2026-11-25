import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_take_bits.dart';
import 'package:flutter_test/flutter_test.dart';

RecordingRow _row(String id, {int duration = 1500, String? localPath}) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: id,
    targetType: 'Audio',
    targetId: 'm1',
    referenceStart: 0,
    referenceDuration: 5000,
    referenceText: 'Hi',
    language: 'en',
    duration: duration,
    md5: null,
    audioUrl: null,
    pronunciationScore: null,
    assessmentJson: null,
    localPath: localPath,
    syncStatus: 'local',
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('takeNumberOf', () {
    test('numbers takes from 1 at the oldest entry', () {
      final takes = [_row('new'), _row('mid'), _row('old')];
      expect(takeNumberOf(takes, takes[0]), 3);
      expect(takeNumberOf(takes, takes[1]), 2);
      expect(takeNumberOf(takes, takes[2]), 1);
    });

    test('a take missing from the list reads as the next take', () {
      final takes = [_row('new'), _row('old')];
      expect(takeNumberOf(takes, _row('new')), 2);
      expect(takeNumberOf(takes, _row('orphan')), 2);
      expect(takeNumberOf(const [], _row('orphan')), 0);
    });
  });

  group('takeDurationLabel', () {
    test('formats milliseconds as seconds with one decimal', () {
      expect(takeDurationLabel(_row('a', duration: 0)), '0.0 s');
      expect(takeDurationLabel(_row('a', duration: 1000)), '1.0 s');
      expect(takeDurationLabel(_row('a', duration: 1540)), '1.5 s');
      expect(takeDurationLabel(_row('a', duration: 12340)), '12.3 s');
    });
  });

  test('takeIsPlayable needs a non-empty local path', () {
    expect(takeIsPlayable(_row('a', localPath: '/tmp/a.wav')), isTrue);
    expect(takeIsPlayable(_row('a', localPath: '')), isFalse);
    expect(takeIsPlayable(_row('a')), isFalse);
  });
}
