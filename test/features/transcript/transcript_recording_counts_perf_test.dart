import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_recording_counts.dart';

const int _kTranscriptLines = 2000;
const int _kRecordings = 200;

RecordingRow _recording({
  required String id,
  required int start,
  required int duration,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: id,
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

/// The overlap rule applied by scanning every recording for every line.
Map<int, int> _nestedCounts(
  List<TranscriptLine> lines,
  List<RecordingRow> recordings,
) {
  if (lines.isEmpty || recordings.isEmpty) return const {};
  final counts = <int, int>{};
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    var count = 0;
    for (final r in recordings) {
      if (recordingOverlapsLine(r, line)) count++;
    }
    if (count > 0) counts[i] = count;
  }
  return counts;
}

List<TranscriptLine> _buildTranscript(int lineCount) {
  return [
    for (var i = 0; i < lineCount; i++)
      TranscriptLine(text: 'line $i', startMs: i * 2000, durationMs: 2000),
  ];
}

List<RecordingRow> _buildRecordings(int count, int spanMs) {
  final rng = Random(7);
  return [
    for (var i = 0; i < count; i++)
      _recording(
        id: 'r-$i',
        start: rng.nextInt(spanMs),
        duration: 5000 + rng.nextInt(15000),
      ),
  ];
}

void main() {
  test('matches the nested scan over random fixtures', () {
    final rng = Random(11);
    for (var round = 0; round < 60; round++) {
      final lineCount = 1 + rng.nextInt(60);
      final recordingCount = 1 + rng.nextInt(20);
      final lines = <TranscriptLine>[
        for (var i = 0; i < lineCount; i++)
          TranscriptLine(
            text: 'l$i',
            startMs: rng.nextInt(6000),
            durationMs: rng.nextInt(5) == 0 ? 0 : rng.nextInt(3000),
          ),
      ];
      final recordings = <RecordingRow>[
        for (var i = 0; i < recordingCount; i++)
          _recording(
            id: 'r-$round-$i',
            start: rng.nextInt(6000),
            duration: rng.nextInt(5) == 0 ? 0 : rng.nextInt(3000),
          ),
      ];
      expect(
        countRecordingsPerLineIndex(lines, recordings),
        _nestedCounts(lines, recordings),
        reason: 'round $round',
      );
    }
  });

  test('degenerate windows never overlap', () {
    const lines = <TranscriptLine>[
      TranscriptLine(text: 'a', startMs: 1000, durationMs: 0),
      TranscriptLine(text: 'b', startMs: 1000, durationMs: -5),
    ];
    final recordings = <RecordingRow>[
      _recording(id: 'r1', start: 500, duration: 2000),
      _recording(id: 'r2', start: 1200, duration: 0),
      _recording(id: 'r3', start: 900, duration: -100),
    ];
    expect(countRecordingsPerLineIndex(lines, recordings), isEmpty);
    expect(_nestedCounts(lines, recordings), isEmpty);
  });

  test('a zero-duration recording is excluded from the count', () {
    final counts = countRecordingsPerLineIndex(
      const [TranscriptLine(text: 'a', startMs: 0, durationMs: 2000)],
      [
        _recording(id: 'r0', start: 100, duration: 0),
        _recording(id: 'r1', start: 100, duration: 500),
      ],
    );
    expect(counts[0], 1);
  });

  test('counting overlaps stays under the loose ceiling (local only)', () {
    final mode =
        Platform.environment['RECORDING_COUNTS_BENCH_MODE'] ?? 'sorted';
    final Map<int, int> Function(List<TranscriptLine>, List<RecordingRow>)
    count = mode == 'nested' ? _nestedCounts : countRecordingsPerLineIndex;

    for (final scale in const [
      (_kRecordings, _kTranscriptLines),
      (800, 4000),
    ]) {
      final (recordingCount, lineCount) = scale;
      final fixtureLines = _buildTranscript(lineCount);
      final fixtureRecordings = _buildRecordings(
        recordingCount,
        lineCount * 2000,
      );

      count(fixtureLines, fixtureRecordings);

      final sw = Stopwatch()..start();
      const runs = 20;
      var sink = 0;
      for (var i = 0; i < runs; i++) {
        sink += count(fixtureLines, fixtureRecordings).length;
      }
      sw.stop();

      final medianMs = sw.elapsedMicroseconds / runs / 1000;
      // ignore: avoid_print
      print(
        'recording overlap counts ($mode): '
        '${medianMs.toStringAsFixed(3)} ms/pass '
        '($lineCount lines x $recordingCount recordings, sink=$sink)',
      );
      expect(medianMs, lessThan(400));
    }
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
