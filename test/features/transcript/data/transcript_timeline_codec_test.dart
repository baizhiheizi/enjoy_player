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
        final json = '[{"text":"ok","startMs":0,"durationMs":100}, 42]';
        expect(tryDecodeTimelineJson(json), isNull);
      },
    );
  });

  group('encodeTimelineJsonGated (issue #810 D4)', () {
    test('small payloads stay on the calling isolate', () {
      final lines = [
        for (var i = 0; i < 4; i++)
          TranscriptLine(text: 'line $i', startMs: i * 1000, durationMs: 900),
      ];
      expect(timelineEncodeNeedsIsolate(lines), isFalse);
    });

    test('large payloads are routed to a background isolate', () {
      const phone = TranscriptPhone(
        phone: 'w',
        text: 'w',
        startTime: 0,
        endTime: 0.2,
      );
      const word = TranscriptWord(
        text: 'word',
        startMs: 0,
        durationMs: 400,
        phones: [phone],
      );
      final lines = [
        for (var i = 0; i < 200; i++)
          TranscriptLine(
            text: 'line $i with enough length to cross the gate threshold',
            startMs: i * 1000,
            durationMs: 900,
            timeline: const [word],
          ),
      ];
      expect(timelineEncodeNeedsIsolate(lines), isTrue);
    });

    test('both paths round-trip through decodeTimelineJson', () async {
      const small = [TranscriptLine(text: 'hi', startMs: 0, durationMs: 100)];
      final smallEncoded = await encodeTimelineJsonGated(small);
      expect(smallEncoded, encodeTimelineJson(small));
      expect(decodeTimelineJson(smallEncoded), equals(small));

      const phone = TranscriptPhone(
        phone: 'w',
        text: 'w',
        startTime: 0,
        endTime: 0.2,
      );
      final large = [
        for (var i = 0; i < 200; i++)
          TranscriptLine(
            text: 'line $i with enough length to cross the gate threshold',
            startMs: i * 1000,
            durationMs: 900,
            timeline: const [
              TranscriptWord(
                text: 'word',
                startMs: 0,
                durationMs: 400,
                phones: [phone],
              ),
            ],
          ),
      ];
      expect(timelineEncodeNeedsIsolate(large), isTrue);
      final largeEncoded = await encodeTimelineJsonGated(large);
      expect(largeEncoded, encodeTimelineJson(large));
      expect(decodeTimelineJson(largeEncoded), equals(large));
    });

    test('estimatedTimelineJsonBytes grows with nested spans', () {
      const plain = [
        TranscriptLine(text: 'hello', startMs: 0, durationMs: 100),
      ];
      const enriched = [
        TranscriptLine(
          text: 'hello',
          startMs: 0,
          durationMs: 100,
          timeline: [
            TranscriptWord(text: 'hello', startMs: 0, durationMs: 100),
          ],
        ),
      ];
      expect(
        estimatedTimelineJsonBytes(enriched),
        greaterThan(estimatedTimelineJsonBytes(plain)),
      );
    });
  });

  group('TranscriptTimelineCache', () {
    TranscriptTimelineRevision revisionFor(String json, DateTime updatedAt) =>
        (updatedAt: updatedAt, jsonLength: json.length);

    test('memoizes on (rowId, revision) — same instance on hit', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));

      final first = cache.linesFor(
        rowId: 'r1',
        revision: revision,
        timelineJson: json,
      );
      final second = cache.linesFor(
        rowId: 'r1',
        revision: revision,
        timelineJson: json,
      );
      expect(identical(first, second), isTrue);
    });

    test('a cache hit does not require timelineJson', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));

      final first = cache.linesFor(
        rowId: 'r1',
        revision: revision,
        timelineJson: json,
      );
      final hit = cache.linesFor(rowId: 'r1', revision: revision);
      expect(identical(hit, first), isTrue);
    });

    test('a miss without timelineJson throws StateError', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));

      expect(
        () => cache.linesFor(rowId: 'r1', revision: revision),
        throwsStateError,
      );
    });

    test('issue #659: a revision change under the same row id re-decodes', () {
      final cache = TranscriptTimelineCache();
      final before = timelineJson([
        lineJson(startMs: 0, durationMs: 2000, text: 'one long cue'),
      ]);
      final after = timelineJson([
        lineJson(startMs: 0, durationMs: 1000, text: 'split'),
        lineJson(startMs: 1000, durationMs: 1000, text: 'apart'),
      ]);
      final t0 = DateTime.utc(2026);
      final t1 = t0.add(const Duration(seconds: 1));

      final stale = cache.linesFor(
        rowId: 'r1',
        revision: revisionFor(before, t0),
        timelineJson: before,
      );
      expect(stale, hasLength(1));

      final fresh = cache.linesFor(
        rowId: 'r1',
        revision: revisionFor(after, t1),
        timelineJson: after,
      );
      expect(fresh, hasLength(2));
      expect(fresh.first.text, 'split');
      expect(identical(fresh, stale), isFalse);
    });

    test('same content under a new revision still re-decodes', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final t0 = DateTime.utc(2026);
      final t1 = t0.add(const Duration(seconds: 1));

      final first = cache.linesFor(
        rowId: 'r1',
        revision: revisionFor(json, t0),
        timelineJson: json,
      );
      final second = cache.linesFor(
        rowId: 'r1',
        revision: revisionFor(json, t1),
        timelineJson: json,
      );
      expect(identical(first, second), isFalse);
      expect(second, equals(first));
    });

    test('separates rows with identical content', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));

      final a = cache.linesFor(
        rowId: 'r1',
        revision: revision,
        timelineJson: json,
      );
      final b = cache.linesFor(
        rowId: 'r2',
        revision: revision,
        timelineJson: json,
      );
      expect(identical(a, b), isFalse);
    });

    test('isCached/store round-trip serves the stored instance', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));
      expect(cache.isCached(rowId: 'r1', revision: revision), isFalse);

      final decodedOffThread = decodeTimelineJson(json);
      cache.store(rowId: 'r1', revision: revision, lines: decodedOffThread);
      expect(cache.isCached(rowId: 'r1', revision: revision), isTrue);
      expect(
        identical(
          cache.linesFor(rowId: 'r1', revision: revision, timelineJson: json),
          decodedOffThread,
        ),
        isTrue,
      );
    });

    test('isCached is a pure probe — it does not touch LRU order', () {
      final cache = TranscriptTimelineCache();
      String jsonFor(int i) =>
          timelineJson([lineJson(startMs: i * 1000, durationMs: 100)]);

      cache.linesFor(
        rowId: 'r0',
        revision: revisionFor(jsonFor(0), DateTime.utc(2026)),
        timelineJson: jsonFor(0),
      );
      cache.linesFor(
        rowId: 'r1',
        revision: revisionFor(jsonFor(1), DateTime.utc(2026)),
        timelineJson: jsonFor(1),
      );
      expect(
        cache.isCached(
          rowId: 'r0',
          revision: revisionFor(jsonFor(0), DateTime.utc(2026)),
        ),
        isTrue,
      );
      for (var i = 2; i <= kTranscriptTimelineMemoCapacity; i++) {
        cache.linesFor(
          rowId: 'r$i',
          revision: revisionFor(jsonFor(i), DateTime.utc(2026)),
          timelineJson: jsonFor(i),
        );
      }

      expect(
        cache.isCached(
          rowId: 'r0',
          revision: revisionFor(jsonFor(0), DateTime.utc(2026)),
        ),
        isFalse,
      );
      expect(
        cache.isCached(
          rowId: 'r1',
          revision: revisionFor(jsonFor(1), DateTime.utc(2026)),
        ),
        isTrue,
      );
    });

    test('remove drops the memo so the next read re-decodes', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));
      final first = cache.linesFor(
        rowId: 'r1',
        revision: revision,
        timelineJson: json,
      );
      cache.remove('r1');
      expect(cache.isCached(rowId: 'r1', revision: revision), isFalse);
      expect(
        identical(
          cache.linesFor(rowId: 'r1', revision: revision, timelineJson: json),
          first,
        ),
        isFalse,
      );
    });

    test('overflow drops the least-recently-used decode (issue #810 C1)', () {
      final cache = TranscriptTimelineCache();
      final t0 = DateTime.utc(2026);
      String jsonFor(int i) =>
          timelineJson([lineJson(startMs: i * 1000, durationMs: 100)]);
      TranscriptTimelineRevision revisionForIndex(int i) => (
        updatedAt: t0.add(Duration(seconds: i)),
        jsonLength: jsonFor(i).length,
      );

      final oldest = cache.linesFor(
        rowId: 'r0',
        revision: revisionForIndex(0),
        timelineJson: jsonFor(0),
      );
      for (var i = 1; i <= kTranscriptTimelineMemoCapacity; i++) {
        cache.linesFor(
          rowId: 'r$i',
          revision: revisionForIndex(i),
          timelineJson: jsonFor(i),
        );
      }

      expect(
        identical(
          cache.linesFor(
            rowId: 'r0',
            revision: revisionForIndex(0),
            timelineJson: jsonFor(0),
          ),
          oldest,
        ),
        isFalse,
      );
      final newestId = 'r$kTranscriptTimelineMemoCapacity';
      final newestJson = jsonFor(kTranscriptTimelineMemoCapacity);
      final newestRevision = revisionForIndex(kTranscriptTimelineMemoCapacity);
      final newest = cache.linesFor(
        rowId: newestId,
        revision: newestRevision,
        timelineJson: newestJson,
      );
      expect(
        identical(
          cache.linesFor(
            rowId: newestId,
            revision: newestRevision,
            timelineJson: newestJson,
          ),
          newest,
        ),
        isTrue,
      );
    });

    test('a re-read row survives overflow, the untouched one is evicted', () {
      final cache = TranscriptTimelineCache();
      final t0 = DateTime.utc(2026);
      String jsonFor(int i) =>
          timelineJson([lineJson(startMs: i * 1000, durationMs: 100)]);
      TranscriptTimelineRevision revisionForIndex(int i) => (
        updatedAt: t0.add(Duration(seconds: i)),
        jsonLength: jsonFor(i).length,
      );

      final untouched = cache.linesFor(
        rowId: 'r1',
        revision: revisionForIndex(1),
        timelineJson: jsonFor(1),
      );
      final touched = cache.linesFor(
        rowId: 'r0',
        revision: revisionForIndex(0),
        timelineJson: jsonFor(0),
      );
      cache.linesFor(
        rowId: 'r0',
        revision: revisionForIndex(0),
        timelineJson: jsonFor(0),
      );
      for (var i = 2; i <= kTranscriptTimelineMemoCapacity; i++) {
        cache.linesFor(
          rowId: 'r$i',
          revision: revisionForIndex(i),
          timelineJson: jsonFor(i),
        );
      }
      expect(
        identical(
          cache.linesFor(
            rowId: 'r0',
            revision: revisionForIndex(0),
            timelineJson: jsonFor(0),
          ),
          touched,
        ),
        isTrue,
      );
      expect(
        identical(
          cache.linesFor(
            rowId: 'r1',
            revision: revisionForIndex(1),
            timelineJson: jsonFor(1),
          ),
          untouched,
        ),
        isFalse,
      );
    });

    test('store over capacity also evicts the least-recently-used row', () {
      final cache = TranscriptTimelineCache();
      final json = timelineJson([lineJson(startMs: 0, durationMs: 100)]);
      final revision = revisionFor(json, DateTime.utc(2026));

      final first = cache.linesFor(
        rowId: 'r0',
        revision: revision,
        timelineJson: json,
      );
      for (var i = 1; i <= kTranscriptTimelineMemoCapacity; i++) {
        cache.store(
          rowId: 'r$i',
          revision: revision,
          lines: decodeTimelineJson(json),
        );
      }

      expect(
        identical(
          cache.linesFor(rowId: 'r0', revision: revision, timelineJson: json),
          first,
        ),
        isFalse,
      );
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

    test('agrees at every cue boundary (starts and ends, off-grid)', () {
      final lines = [
        cue(0, 1000),
        cue(1200, 800),
        cue(3000, 1000),
        cue(4500, 1500),
      ];
      const boundaries = [0.0, 1.0, 1.2, 2.0, 3.0, 4.0, 4.5, 6.0];
      for (final t in boundaries) {
        expect(
          indexOfActiveLine(lines, t),
          transcriptActiveIndex(lines, t),
          reason: 'policies disagree at boundary t=$t',
        );
      }
    });

    test('boundary pinning: start of a cue is inside, end is a gap', () {
      final lines = [cue(0, 1000), cue(1200, 800)];
      expect(indexOfActiveLine(lines, 1.2), 1);
      expect(transcriptActiveIndex(lines, 1.2), 1);
      expect(indexOfActiveLine(lines, 2.0), 1);
      expect(transcriptActiveIndex(lines, 2.0), 1);
      expect(indexOfActiveLine(lines, 1.0), 0);
      expect(transcriptActiveIndex(lines, 1.0), 0);
    });
  });
}
