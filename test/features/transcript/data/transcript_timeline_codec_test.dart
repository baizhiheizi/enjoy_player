import 'dart:convert';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/transcript_timeline_codec.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptLine cue(int startMs, int durationMs, [String text = 'x']) {
  return TranscriptLine(text: text, startMs: startMs, durationMs: durationMs);
}

String timelineJson(List<Map<String, Object?>> lines) => jsonEncode([...lines]);

Map<String, Object?> lineJson({
  required int startMs,
  required int durationMs,
  String text = 'x',
}) => {'text': text, 'start': startMs, 'duration': durationMs};

void main() {
  group('decodeTimelineJson (strict)', () {
    test('decodes a timeline payload into lines', () {
      final lines = decodeTimelineJson(
        timelineJson([
          lineJson(startMs: 0, durationMs: 1000, text: 'hello'),
          lineJson(startMs: 1000, durationMs: 500, text: 'world'),
        ]),
      );
      expect(lines, hasLength(2));
      expect(lines.first.text, 'hello');
      expect(lines.first.startSeconds, 0);
      expect(lines[1].startSeconds, 1.0);
    });

    test('throws when the top-level JSON is not a list', () {
      expect(
        () => decodeTimelineJson('{"text":"not a list"}'),
        throwsA(anything),
      );
    });

    test('throws when an item is not a map', () {
      expect(() => decodeTimelineJson('[42]'), throwsA(anything));
    });

    test('throws on invalid JSON', () {
      expect(() => decodeTimelineJson('not json'), throwsA(anything));
    });
  });

  group('tryDecodeTimelineJson (fail-closed)', () {
    test('decodes valid input', () {
      final lines = tryDecodeTimelineJson(
        timelineJson([lineJson(startMs: 0, durationMs: 1000)]),
      );
      expect(lines, isNotNull);
      expect(lines, hasLength(1));
    });

    test('returns null on malformed input', () {
      expect(tryDecodeTimelineJson('not json'), isNull);
      expect(tryDecodeTimelineJson('{"a":1}'), isNull);
    });

    test(
      'returns null when a list mixes valid lines with garbage (fail-closed)',
      () {
        // Craft enrichment treats partial input as garbage: a dropped line
        // desynchronizes indices from alignment segments, so the original
        // JSON must survive untouched.
        final json = '[{"text":"ok","startMs":0,"durationMs":100}, 42]';
        expect(tryDecodeTimelineJson(json), isNull);
      },
    );
  });

  group('timelineJsonHash', () {
    test('is stable for equal content and differs for changed content', () {
      final a = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final b = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final c = timelineJson([lineJson(startMs: 0, durationMs: 200)]);
      expect(timelineJsonHash(a), timelineJsonHash(b));
      expect(timelineJsonHash(a), isNot(timelineJsonHash(c)));
    });
  });

  group('TranscriptTimelineCache', () {
    test('memoizes on (rowId, content) — same instance on hit', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);

      final first = cache.linesFor(rowId: 'r1', timelineJson: json);
      final second = cache.linesFor(rowId: 'r1', timelineJson: json);
      expect(identical(first, second), isTrue);
    });

    test('issue #659: re-segmentation under the same row id re-decodes', () {
      // A re-import re-segments cues under the SAME transcript row id.
      // Serving the stale decode would feed echo stale line indices, so
      // the changed timelineJson must force a fresh decode.
      final cache = TranscriptTimelineCache();
      final before = timelineJson([
        lineJson(startMs: 0, durationMs: 2000, text: 'one long cue'),
      ]);
      final after = timelineJson([
        lineJson(startMs: 0, durationMs: 1000, text: 'split'),
        lineJson(startMs: 1000, durationMs: 1000, text: 'apart'),
      ]);

      final stale = cache.linesFor(rowId: 'r1', timelineJson: before);
      expect(stale, hasLength(1));

      final fresh = cache.linesFor(rowId: 'r1', timelineJson: after);
      expect(fresh, hasLength(2));
      expect(fresh.first.text, 'split');
      expect(identical(fresh, stale), isFalse);
    });

    test('separates rows with identical content', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);

      final a = cache.linesFor(rowId: 'r1', timelineJson: json);
      final b = cache.linesFor(rowId: 'r2', timelineJson: json);
      expect(identical(a, b), isFalse);
    });

    test('isCached/store round-trip serves the stored instance', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      expect(cache.isCached(rowId: 'r1', timelineJson: json), isFalse);

      final decodedOffThread = decodeTimelineJson(json);
      cache.store(rowId: 'r1', timelineJson: json, lines: decodedOffThread);
      expect(cache.isCached(rowId: 'r1', timelineJson: json), isTrue);
      expect(
        identical(
          cache.linesFor(rowId: 'r1', timelineJson: json),
          decodedOffThread,
        ),
        isTrue,
      );
    });

    test('clear drops entries', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      cache.linesFor(rowId: 'r1', timelineJson: json);
      cache.clear();
      expect(cache.isCached(rowId: 'r1', timelineJson: json), isFalse);
    });
  });

  group('transcriptActiveIndex (UI highlight policy)', () {
    test('returns index when time is inside a cue', () {
      final lines = [cue(0, 1000), cue(1000, 1000), cue(2000, 1000)];
      expect(transcriptActiveIndex(lines, 0.5), 0);
      expect(transcriptActiveIndex(lines, 1.0), 1);
      expect(transcriptActiveIndex(lines, 1.5), 1);
      expect(transcriptActiveIndex(lines, 2.5), 2);
    });

    test('returns last cue with start <= t when t is in a gap (after end)', () {
      final lines = [cue(0, 500), cue(2000, 500)];
      expect(transcriptActiveIndex(lines, 1.0), 0);
      expect(transcriptActiveIndex(lines, 1.5), 0);
    });

    test('returns last cue when t is in a non-empty gap between cues', () {
      final lines = [
        cue(0, 1000),
        cue(1000, 1000),
        cue(3000, 1000),
        cue(4000, 1000),
      ];
      expect(transcriptActiveIndex(lines, 2.5), 1);
    });

    test('returns -1 when t is before first cue', () {
      final lines = [cue(1000, 500)];
      expect(transcriptActiveIndex(lines, 0.5), -1);
    });

    test('empty lines returns -1', () {
      expect(transcriptActiveIndex([], 1.0), -1);
    });

    test('returns last cue when t is past the final end', () {
      final lines = [cue(0, 1000), cue(2000, 1000)];
      expect(transcriptActiveIndex(lines, 100.0), 1);
    });
  });

  group('indexOfActiveLine (transport policy)', () {
    test('prefers the cue that strictly contains t', () {
      final lines = [cue(0, 1000), cue(1000, 1000), cue(2000, 1000)];
      expect(indexOfActiveLine(lines, 0.5), 0);
      expect(indexOfActiveLine(lines, 2.0), 2);
      expect(indexOfActiveLine(lines, 2.5), 2);
    });

    test('falls back to the rightmost cue started at-or-before t', () {
      final lines = [cue(0, 500), cue(2000, 500)];
      expect(indexOfActiveLine(lines, 1.0), 0);
      expect(indexOfActiveLine(lines, 8.0), 1);
      expect(indexOfActiveLine(lines, 100.0), 1);
    });

    test('returns the earliest containing cue when cues overlap', () {
      // Transport semantics: a tap at t means the FIRST cue covering it.
      final lines = [cue(0, 3000), cue(1000, 1000)];
      expect(indexOfActiveLine(lines, 1.5), 0);
    });

    test('returns -1 before the first cue and for empty lines', () {
      expect(indexOfActiveLine([cue(1000, 500)], 0.5), -1);
      expect(indexOfActiveLine([], 5.0), -1);
    });

    test('agrees with the highlight policy on sorted non-overlapping cues', () {
      final lines = [
        cue(0, 1000),
        cue(1200, 800),
        cue(3000, 1000),
        cue(4500, 1500),
      ];
      for (var t = -0.5; t < 7.0; t += 0.25) {
        expect(
          indexOfActiveLine(lines, t),
          transcriptActiveIndex(lines, t),
          reason: 'policies disagree at t=$t',
        );
      }
    });
  });
}
