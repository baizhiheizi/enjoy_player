import 'dart:convert';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_button.dart';
import 'package:flutter_test/flutter_test.dart';

int? legacyPronScore(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final nb = m['NBest'] as List<dynamic>?;
    if (nb == null || nb.isEmpty) return null;
    final first = nb.first;
    if (first is! Map<String, dynamic>) return null;
    final pa = first['PronunciationAssessment'];
    if (pa is! Map<String, dynamic>) return null;
    final v = pa['PronScore'];
    if (v is num) return v.round();
    return null;
  } on Object {
    return null;
  }
}

final String azureFixture = jsonEncode({
  'RecognitionStatus': 'Success',
  'Offset': 0,
  'Duration': 10000000,
  'DisplayText': 'Hi.',
  'NBest': [
    {
      'Confidence': 0.9,
      'Lexical': 'hi',
      'ITN': 'hi',
      'MaskedITN': 'hi',
      'Display': 'Hi.',
      'PronunciationAssessment': {
        'AccuracyScore': 90,
        'FluencyScore': 88,
        'CompletenessScore': 95,
        'PronScore': 91,
        'ProsodyScore': 80,
      },
      'Words': [
        {
          'Word': 'hi',
          'Offset': 0,
          'Duration': 10000000,
          'PronunciationAssessment': {'AccuracyScore': 92, 'ErrorType': 'None'},
        },
      ],
    },
  ],
});

String azureDoc({required int words, Object? pronScore, bool pa = true}) {
  final paBlock = pa
      ? '"PronunciationAssessment":${pronScore == null ? '{}' : '{"AccuracyScore":${pronScore is int ? pronScore : 80},"PronScore":$pronScore,"FluencyScore":88}'}'
      : '"AccuracyScore":80';
  final nBest = List.generate(words, (i) {
    return '{"Word":"w$i","Offset":${i * 1000},"Duration":10000,'
        '"Lexical":"word$i","Display":"word$i",'
        '"PronunciationAssessment":{"AccuracyScore":${60 + (i % 40)},'
        '"ErrorType":"None"}}';
  }).join(',');
  return '{"RecognitionStatus":"Success","DisplayText":"doc",'
      '"NBest":[{"Confidence":0.9,"Lexical":"first","Display":"first",'
      '$paBlock,"Words":[$nBest]}]}';
}

List<String> benchCorpus() {
  final docs = <String>[];
  for (final pronScore in [0, 55, 91, null]) {
    docs.add(azureDoc(words: 1, pronScore: pronScore));
  }
  for (var i = 0; i < 8; i++) {
    docs.add(
      azureDoc(words: 10, pronScore: i.isEven ? 40 + i * 5 : null, pa: i != 3),
    );
  }
  for (final pronScore in [70, null]) {
    docs.add(azureDoc(words: 100, pronScore: pronScore));
    docs.add(azureDoc(words: 100, pronScore: pronScore, pa: false));
  }
  return docs;
}

String? freshCopy(String? s) =>
    s == null ? null : String.fromCharCodes(s.codeUnits);

RecordingRow rowWith(String? assessmentJson, {int? pronunciationScore}) {
  final now = DateTime.now();
  return RecordingRow(
    id: 'row-$assessmentJson'.hashCode.toString(),
    targetType: 'Audio',
    targetId: 'm1',
    referenceStart: 0,
    referenceDuration: 5000,
    referenceText: 'Hi',
    language: 'en',
    duration: 1000,
    md5: null,
    audioUrl: null,
    pronunciationScore: pronunciationScore,
    assessmentJson: assessmentJson,
    localPath: '/tmp/fake.wav',
    syncStatus: 'local',
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

String fuzzDoc(int i) {
  switch (i % 6) {
    case 0:
      return azureDoc(words: 1 + (i % 15), pronScore: (i * 7) % 101);
    case 1:
      return azureDoc(words: 1 + (i % 4), pronScore: null);
    case 2:
      final doc = azureDoc(words: 2 + (i % 8), pronScore: i % 101);
      final cut = doc.length ~/ 2 + (i % 7);
      return doc.substring(0, cut.clamp(1, doc.length));
    case 3:
      return '{"NBest":${i.isEven ? '[]' : 'null'}}';
    case 4:
      return i.isEven ? '{"NBest":[42]}' : '{"NBest":["s"}],"extra":$i}';
    default:
      return switch (i % 3) {
        0 => '"just a string $i"',
        1 => '${i * 13}',
        _ => '{"NBst":[{"PronunciationAssessment":{"PronScore":$i}}]}',
      };
  }
}

void main() {
  group('differential: memoized parse equals the fresh decode', () {
    test('curated edge inputs', () {
      final edges = <String?>[
        null,
        '',
        '   \n\t  ',
        'not json',
        'null',
        '42',
        '"quoted"',
        '[]',
        '{}',
        '{"NBest":null}',
        '{"NBest":[]}',
        '{"NBest":[1,2]}',
        '{"NBest":[{"PronunciationAssessment":null}]}',
        '{"NBest":[{"PronunciationAssessment":"x"}]}',
        '{"NBest":[{"PronunciationAssessment":42}]}',
        '{"NBest":[{"PronunciationAssessment":{}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":null}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":"91"}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":true}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":91}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":91.4}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":91.5}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":-3}}]}',
        '{"NBest":[{"PronunciationAssessment":{"PronScore":1e3}}]}',
        '  {"NBest":[{"PronunciationAssessment":{"PronScore":7}}]}  ',
        azureFixture,
        '{"NBest":[{"Confidence":0.9,"Lexical":"first"}]}',
      ];
      var oracleSink = 0;
      for (final raw in edges) {
        final actual = pronunciationScoreFromRecording(
          rowWith(raw, pronunciationScore: null),
        );
        final oracle = legacyPronScore(raw);
        expect(actual, oracle, reason: 'raw=$raw');
        oracleSink += oracle ?? 0;
      }
      expect(oracleSink, 1369);
    });

    test('fuzz corpus across valid, malformed, and wrong-shape documents', () {
      var sink = 0;
      for (var i = 0; i < 300; i++) {
        final raw = fuzzDoc(i);
        final actual = pronunciationScoreFromRecording(
          rowWith(raw, pronunciationScore: null),
        );
        final oracle = legacyPronScore(raw);
        expect(actual, oracle, reason: 'case=$i');
        sink += actual ?? 0;
      }
      expect(sink, greaterThanOrEqualTo(0));
    });

    test('repeat calls stay stable', () {
      const raw =
          '{"NBest":[{"PronunciationAssessment":{"PronScore":64}}],"stable":1}';
      final row = rowWith(raw, pronunciationScore: null);
      final first = pronunciationScoreFromRecording(row);
      for (var i = 0; i < 5; i++) {
        expect(pronunciationScoreFromRecording(row), first);
      }
      expect(first, 64);
    });
  });

  group('structural: parse counts', () {
    test('parses once per raw string; equal strings share the entry', () {
      final doc = azureDoc(
        words: 3,
        pronScore: 83,
      ).replaceFirst('Success', 'OncePerString');
      pronScoreParseCount = 0;
      expect(
        pronunciationScoreFromRecording(rowWith(doc, pronunciationScore: null)),
        83,
      );
      expect(pronScoreParseCount, 1);
      expect(
        pronunciationScoreFromRecording(rowWith(doc, pronunciationScore: null)),
        83,
      );
      expect(pronScoreParseCount, 1);
      final copy = String.fromCharCodes(doc.codeUnits);
      expect(
        pronunciationScoreFromRecording(
          rowWith(copy, pronunciationScore: null),
        ),
        83,
      );
      expect(pronScoreParseCount, 1);
    });

    test('the pronunciationScore column short-circuits before any parse', () {
      final doc = azureDoc(
        words: 2,
        pronScore: 99,
      ).replaceFirst('Success', 'ColumnWins');
      pronScoreParseCount = 0;
      final row = rowWith(doc, pronunciationScore: 41);
      expect(pronunciationScoreFromRecording(row), 41);
      expect(pronScoreParseCount, 0);
      expect(
        pronunciationScoreFromRecording(
          rowWith(null, pronunciationScore: null),
        ),
        isNull,
      );
      expect(
        pronunciationScoreFromRecording(rowWith('', pronunciationScore: null)),
        isNull,
      );
      expect(
        pronunciationScoreFromRecording(
          rowWith('  ', pronunciationScore: null),
        ),
        isNull,
      );
      expect(pronScoreParseCount, 0);
    });

    test('null parses are cached too', () {
      final doc = '{"NBest":[{"PronunciationAssessment":{}}],"nullCase":1}';
      pronScoreParseCount = 0;
      final row = rowWith(doc, pronunciationScore: null);
      expect(pronunciationScoreFromRecording(row), isNull);
      expect(pronScoreParseCount, 1);
      expect(pronunciationScoreFromRecording(row), isNull);
      expect(pronScoreParseCount, 1);
    });

    test('the 129th distinct raw evicts the memo head', () {
      pronScoreParseCount = 0;
      final docs = [
        for (var i = 0; i < 128; i++)
          azureDoc(
            words: 1,
            pronScore: 50 + (i % 40),
          ).replaceFirst('Success', 'MemoEvictFill$i'),
      ];
      for (final doc in docs) {
        expect(
          pronunciationScoreFromRecording(
            rowWith(doc, pronunciationScore: null),
          ),
          isNotNull,
        );
      }
      expect(pronScoreParseCount, 128);
      final fresh = azureDoc(
        words: 1,
        pronScore: 90,
      ).replaceFirst('Success', 'MemoEvictHead');
      expect(
        pronunciationScoreFromRecording(
          rowWith(fresh, pronunciationScore: null),
        ),
        90,
      );
      expect(pronScoreParseCount, 129);
      expect(
        pronunciationScoreFromRecording(
          rowWith(docs.first, pronunciationScore: null),
        ),
        isNotNull,
      );
      expect(pronScoreParseCount, 130);
      expect(
        pronunciationScoreFromRecording(
          rowWith(fresh, pronunciationScore: null),
        ),
        90,
      );
      expect(pronScoreParseCount, 130);
    });
  });

  test('sink parity: legacy and memoized agree over the bench corpus', () {
    final docs = benchCorpus();
    final rows = [
      for (final doc in docs) rowWith(doc, pronunciationScore: null),
    ];
    var legacySink = 0;
    var memoSink = 0;
    for (var pass = 0; pass < 3; pass++) {
      for (var i = 0; i < docs.length; i++) {
        legacySink += legacyPronScore(docs[i]) ?? 0;
        memoSink += pronunciationScoreFromRecording(rows[i]) ?? 0;
      }
    }
    expect(memoSink, legacySink);
  });

  const int benchPasses = 200;

  test(
    'bench (local only): legacy decode, $benchPasses panel passes over 16 takes',
    skip: true,
    () {
      final docs = benchCorpus();
      final rows = [
        for (final doc in docs) rowWith(doc, pronunciationScore: null),
      ];
      int panelPass(List<RecordingRow> rows) {
        var sink = 0;
        for (final row in rows) {
          sink += legacyPronScore(row.assessmentJson) ?? 0;
        }
        return sink;
      }

      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += panelPass(rows);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += panelPass(rows);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy panel rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized parse, $benchPasses panel passes over 16 takes',
    skip: true,
    () {
      final docs = benchCorpus();
      final rows = [
        for (final doc in docs) rowWith(doc, pronunciationScore: null),
      ];
      int panelPass(List<RecordingRow> rows) {
        var sink = 0;
        for (final row in rows) {
          sink += pronunciationScoreFromRecording(row) ?? 0;
        }
        return sink;
      }

      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += panelPass(rows);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += panelPass(rows);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized panel rebuild: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): memoized parse, $benchPasses copy-key panel passes '
    'over 16 takes',
    skip: true,
    () {
      final docs = benchCorpus();
      final rows = [
        for (final doc in docs) rowWith(doc, pronunciationScore: null),
      ];
      int panelPass(List<RecordingRow> rows) {
        var sink = 0;
        for (final row in rows) {
          sink +=
              pronunciationScoreFromRecording(
                rowWith(
                  freshCopy(row.assessmentJson),
                  pronunciationScore: null,
                ),
              ) ??
              0;
        }
        return sink;
      }

      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += panelPass(rows);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += panelPass(rows);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'memoized copy-key panel rebuild: '
        '${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      ); // ignore: avoid_print
    },
  );
}
