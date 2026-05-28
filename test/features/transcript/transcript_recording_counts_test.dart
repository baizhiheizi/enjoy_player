import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_recording_counts.dart';
import 'package:flutter_test/flutter_test.dart';

RecordingRow _recording({required int start, required int duration}) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: 'r-$start',
    targetType: 'Audio',
    targetId: 'media-1',
    referenceStart: start,
    referenceDuration: duration,
    referenceText: 'ref',
    language: 'en',
    duration: duration,
    md5: null,
    audioUrl: null,
    pronunciationScore: null,
    assessmentJson: null,
    localPath: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

const _lineA = TranscriptLine(text: 'A', startMs: 0, durationMs: 2000);
const _lineB = TranscriptLine(text: 'B', startMs: 2000, durationMs: 2000);

void main() {
  group('recordingOverlapsLine', () {
    test('no overlap when ranges are adjacent', () {
      final r = _recording(start: 2000, duration: 1000);
      expect(recordingOverlapsLine(r, _lineA), isFalse);
    });

    test('partial overlap counts', () {
      final r = _recording(start: 1500, duration: 1000);
      expect(recordingOverlapsLine(r, _lineA), isTrue);
    });

    test('zero-duration line does not overlap', () {
      const zeroLine = TranscriptLine(text: 'Z', startMs: 1000, durationMs: 0);
      final r = _recording(start: 1000, duration: 500);
      expect(recordingOverlapsLine(r, zeroLine), isFalse);
    });

    test('zero-duration recording does not overlap', () {
      final r = _recording(start: 500, duration: 0);
      expect(recordingOverlapsLine(r, _lineA), isFalse);
    });
  });

  group('countRecordingsPerLineIndex', () {
    test('empty inputs yield empty map', () {
      expect(countRecordingsPerLineIndex(const [], const []), isEmpty);
      expect(
        countRecordingsPerLineIndex(const [_lineA], const []),
        isEmpty,
      );
    });

    test('no overlap omits line from map', () {
      final counts = countRecordingsPerLineIndex(
        const [_lineA],
        [_recording(start: 5000, duration: 1000)],
      );
      expect(counts, isEmpty);
    });

    test('multiple recordings on one line', () {
      final counts = countRecordingsPerLineIndex(
        const [_lineA],
        [
          _recording(start: 0, duration: 500),
          _recording(start: 100, duration: 500),
        ],
      );
      expect(counts[0], 2);
    });

    test('one recording spanning two lines', () {
      final counts = countRecordingsPerLineIndex(
        const [_lineA, _lineB],
        [_recording(start: 1500, duration: 2000)],
      );
      expect(counts[0], 1);
      expect(counts[1], 1);
      expect(counts.length, 2);
    });

    test('adjacent line boundary does not double-count at edge', () {
      final counts = countRecordingsPerLineIndex(
        const [_lineA, _lineB],
        [_recording(start: 2000, duration: 1000)],
      );
      expect(counts.containsKey(0), isFalse);
      expect(counts[1], 1);
    });
  });
}
