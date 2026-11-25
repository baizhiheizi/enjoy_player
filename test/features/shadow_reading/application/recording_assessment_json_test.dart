import 'package:enjoy_player/features/shadow_reading/application/recording_assessment_json.dart';
import 'package:flutter_test/flutter_test.dart';

const _kScored =
    '{"NBest":[{"Lexical":"hi","Display":"Hi.",'
    '"PronunciationAssessment":{"AccuracyScore":90,"FluencyScore":88,'
    '"CompletenessScore":95,"PronScore":91.4,"ProsodyScore":80},'
    '"Words":[{"Word":"hi","Offset":0,"Duration":10000000,'
    '"PronunciationAssessment":{"AccuracyScore":92,'
    '"ErrorType":"Mispronunciation"}}]}]}';

const _kNoScore = '{"NBest":[{"PronunciationAssessment":{}}]}';

const _kStringScore =
    '{"NBest":[{"PronunciationAssessment":{"PronScore":"91"}}]}';

const _kUnreadable = [
  '',
  'not json',
  'null',
  '42',
  '"quoted"',
  '[1, 2]',
  '{"NBest":[tru',
];

void main() {
  group('tryParseStoredAssessment', () {
    test('parses a stored document into the typed result', () {
      final result = tryParseStoredAssessment(_kScored)!;
      expect(result.primaryScores?.pronScore, 91.4);
      expect(result.primaryNBest?.words.single.word, 'hi');
    });

    test('a document without hypotheses parses to an empty list', () {
      expect(tryParseStoredAssessment('{}')?.nBest, isEmpty);
      expect(tryParseStoredAssessment('{"NBest":[42]}')?.nBest, isEmpty);
    });

    test('unreadable or non-object payloads yield null', () {
      for (final raw in _kUnreadable) {
        expect(tryParseStoredAssessment(raw), isNull, reason: raw);
      }
    });
  });

  group('decodeStoredPronScore', () {
    test('rounds the first hypothesis score', () {
      expect(decodeStoredPronScore(_kScored), 91);
      expect(
        decodeStoredPronScore(
          '{"NBest":[{"PronunciationAssessment":{"PronScore":91.5}}]}',
        ),
        92,
      );
    });

    test('a missing score stays null where the typed result reads 0', () {
      expect(decodeStoredPronScore(_kNoScore), isNull);
      expect(tryParseStoredAssessment(_kNoScore)!.primaryScores?.pronScore, 0);
    });

    test('a string score stays null where the typed result parses it', () {
      expect(decodeStoredPronScore(_kStringScore), isNull);
      expect(
        tryParseStoredAssessment(_kStringScore)!.primaryScores?.pronScore,
        91,
      );
    });

    test('unreadable or non-object payloads yield null', () {
      for (final raw in _kUnreadable) {
        expect(decodeStoredPronScore(raw), isNull, reason: raw);
      }
    });
  });
}
