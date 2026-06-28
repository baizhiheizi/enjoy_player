import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/share_poster/domain/practice_poster_data.dart';
import 'package:flutter_test/flutter_test.dart';

RecordingRow _recording({
  required String id,
  required int start,
  required int duration,
  String referenceText = 'ref',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return RecordingRow(
    id: id,
    targetType: 'Video',
    targetId: 'media-1',
    referenceStart: start,
    referenceDuration: duration,
    referenceText: referenceText,
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

void main() {
  group('isLikelyIncompleteSentence', () {
    test('fragment without terminal punctuation is incomplete', () {
      expect(
        isLikelyIncompleteSentence(
          'so I could get away from the incessant buzzing',
        ),
        isTrue,
      );
    });

    test('complete sentence with period is not incomplete', () {
      expect(isLikelyIncompleteSentence('Longer practiced line.'), isFalse);
    });

    test('CJK terminal punctuation is complete', () {
      expect(isLikelyIncompleteSentence('这是完整句子。'), isFalse);
    });
  });

  group('computePracticePosterStats', () {
    test('empty recordings yields zeros', () {
      final stats = computePracticePosterStats(
        recordings: const [],
        lines: const [],
      );
      expect(stats.takes, 0);
      expect(stats.sentencesPracticed, 0);
      expect(stats.spokenDurationMs, 0);
    });

    test('counts takes, spoken ms, and practiced lines', () {
      const lineA = TranscriptLine(text: 'A', startMs: 0, durationMs: 2000);
      const lineB = TranscriptLine(text: 'B', startMs: 2000, durationMs: 2000);
      final recordings = [
        _recording(id: 'r1', start: 100, duration: 800),
        _recording(id: 'r2', start: 2100, duration: 500),
        _recording(id: 'r3', start: 2200, duration: 600),
      ];

      final stats = computePracticePosterStats(
        recordings: recordings,
        lines: const [lineA, lineB],
      );

      expect(stats.takes, 3);
      expect(stats.spokenDurationMs, 1900);
      expect(stats.sentencesPracticed, 2);
    });
  });

  group('resolvePracticePosterQuote', () {
    const lineShort = TranscriptLine(text: 'Hi.', startMs: 0, durationMs: 1000);
    const lineLong = TranscriptLine(
      text: 'Longer practiced line.',
      startMs: 1000,
      durationMs: 2000,
    );
    const lineFragment = TranscriptLine(
      text: 'so I could get away from the buzzing',
      startMs: 3000,
      durationMs: 2000,
    );
    const lineTie = TranscriptLine(text: 'OK', startMs: 5000, durationMs: 1000);

    test('picks most-recorded line', () {
      final quote = resolvePracticePosterQuote(
        lines: const [lineShort, lineLong],
        recordings: [
          _recording(id: 'a', start: 0, duration: 500),
          _recording(id: 'b', start: 1100, duration: 500),
          _recording(id: 'c', start: 1200, duration: 500),
        ],
      );
      expect(quote?.line.text, 'Longer practiced line.');
      expect(quote?.line.trailingEllipsis, isFalse);
    });

    test('strips subtitle markup from quote lines', () {
      const lineWithMarkup = TranscriptLine(
        text: '<font size="54">JUST \'CAUSE I DON\'T</font>',
        startMs: 0,
        durationMs: 2000,
      );
      final quote = resolvePracticePosterQuote(
        lines: const [lineWithMarkup],
        recordings: [_recording(id: 'a', start: 100, duration: 500)],
      );
      expect(quote?.line.text, "JUST 'CAUSE I DON'T");
    });

    test('prefers active echo region over most-practiced line', () {
      const lineA = TranscriptLine(
        text: 'First echo line.',
        startMs: 0,
        durationMs: 1000,
      );
      const lineB = TranscriptLine(
        text: 'Second echo line.',
        startMs: 1000,
        durationMs: 1000,
      );
      const lineOther = TranscriptLine(
        text: 'Most practiced but outside echo.',
        startMs: 3000,
        durationMs: 1000,
      );
      final quote = resolvePracticePosterQuote(
        lines: const [lineA, lineB, lineOther],
        recordings: [
          _recording(id: 'a', start: 3100, duration: 500),
          _recording(id: 'b', start: 3200, duration: 500),
          _recording(id: 'c', start: 3200, duration: 500),
        ],
        echoStartLineIndex: 0,
        echoEndLineIndex: 1,
      );
      expect(quote?.line.text, 'First echo line. Second echo line.');
    });

    test('appends ellipsis for incomplete fragment', () {
      final quote = resolvePracticePosterQuote(
        lines: const [lineFragment],
        recordings: [_recording(id: 'a', start: 3100, duration: 500)],
      );
      expect(quote?.line.displayText, endsWith('...'));
      expect(quote?.line.trailingEllipsis, isTrue);
    });

    test('returns only the top practiced line when several exist', () {
      final quote = resolvePracticePosterQuote(
        lines: const [lineShort, lineLong, lineFragment],
        recordings: [
          _recording(id: 'a', start: 1100, duration: 500),
          _recording(id: 'b', start: 1200, duration: 500),
          _recording(id: 'c', start: 3100, duration: 500),
          _recording(id: 'd', start: 100, duration: 500),
        ],
      );
      expect(quote?.line.text, 'Longer practiced line.');
    });

    test('tie-breaks by longer text', () {
      final quote = resolvePracticePosterQuote(
        lines: const [lineShort, lineTie],
        recordings: [
          _recording(id: 'a', start: 0, duration: 400),
          _recording(id: 'b', start: 5100, duration: 400),
        ],
      );
      expect(quote?.line.text, 'Hi.');
    });

    test('falls back to longest referenceText without transcript overlap', () {
      final quote = resolvePracticePosterQuote(
        lines: const [],
        recordings: [
          _recording(id: 'a', start: 0, duration: 400, referenceText: 'Short'),
          _recording(
            id: 'b',
            start: 0,
            duration: 400,
            referenceText: 'Much longer reference text',
          ),
        ],
      );
      expect(quote?.line.text, 'Much longer reference text');
    });

    test('returns null when no usable text', () {
      final quote = resolvePracticePosterQuote(
        lines: const [],
        recordings: [
          _recording(id: 'a', start: 0, duration: 400, referenceText: '  '),
        ],
      );
      expect(quote, isNull);
    });
  });
}
