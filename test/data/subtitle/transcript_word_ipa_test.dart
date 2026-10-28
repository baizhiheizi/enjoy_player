import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/data/subtitle/transcript_word_ipa.dart';

void main() {
  group('wordIpaPieces', () {
    test('concatenates ordered non-empty phone labels', () {
      const word = TranscriptWord(
        text: 'an',
        phones: [
          TranscriptPhone(phone: 'æ', text: 'æ', startTime: 0, endTime: 0.05),
          TranscriptPhone(phone: 'n', text: 'n', startTime: 0.05, endTime: 0.1),
        ],
      );
      expect(wordIpaPieces(word), ['æ', 'n']);
    });

    test('skips empty and whitespace-only pieces', () {
      const word = TranscriptWord(
        text: 'an',
        phones: [
          TranscriptPhone(phone: 'æ', text: 'æ', startTime: 0, endTime: 0.05),
          TranscriptPhone(
            phone: '  ',
            text: '',
            startTime: 0.05,
            endTime: 0.08,
          ),
          TranscriptPhone(phone: '', text: '', startTime: 0.08, endTime: 0.1),
          TranscriptPhone(phone: 'n', text: 'n', startTime: 0.1, endTime: 0.15),
        ],
      );
      expect(wordIpaPieces(word), ['æ', 'n']);
    });

    test('returns empty when phones are missing', () {
      const word = TranscriptWord(text: 'Hello');
      expect(wordIpaPieces(word), isEmpty);
    });
  });

  group('wordIpaSpelling', () {
    test('joins pieces without inventing labels', () {
      const word = TranscriptWord(
        text: 'an',
        phones: [
          TranscriptPhone(phone: 'æ', text: 'æ', startTime: 0, endTime: 0.05),
          TranscriptPhone(phone: 'n', text: 'n', startTime: 0.05, endTime: 0.1),
        ],
      );
      expect(wordIpaSpelling(word), 'æn');
    });

    test('returns null when there are no stored phones', () {
      expect(wordIpaSpelling(const TranscriptWord(text: 'Hello')), isNull);
      expect(
        wordIpaSpelling(
          const TranscriptWord(
            text: 'Hello',
            phones: [
              TranscriptPhone(
                phone: '   ',
                text: '',
                startTime: 0,
                endTime: 0.1,
              ),
            ],
          ),
        ),
        isNull,
      );
    });

    test('repairs Latin-1 mojibake from mis-decoded UTF-8 phones', () {
      final haveMojibake = String.fromCharCodes(const [0x68, 0xC3, 0xA6, 0x76]);
      final gMojibake = String.fromCharCodes(const [0xC9, 0xA1]);
      expect(repairUtf8Mojibake(haveMojibake), 'hæv');
      expect(repairUtf8Mojibake(gMojibake), 'ɡ');
      expect(
        wordIpaSpelling(
          TranscriptWord(
            text: 'have',
            phones: [
              TranscriptPhone(
                phone: haveMojibake,
                text: haveMojibake,
                startTime: 0,
                endTime: 0.1,
              ),
            ],
          ),
        ),
        'hæv',
      );
    });
  });

  group('wordIpaSpelling memoization', () {
    test('derives the familiar form once for a repeated word', () {
      const word = TranscriptWord(
        text: 'memo',
        phones: [
          TranscriptPhone(phone: 'm', text: 'm', startTime: 0, endTime: 0.05),
          TranscriptPhone(phone: 'ɛ', text: 'ɛ', startTime: 0.05, endTime: 0.1),
        ],
      );

      final before = wordIpaDerivationCount;
      expect(wordIpaSpelling(word), 'me');
      expect(wordIpaDerivationCount, before + 1);

      expect(wordIpaSpelling(word), 'me');
      expect(wordIpaDerivationCount, before + 1);
    });

    test('reuses the memoized familiar form for every word of a line', () {
      final words = [
        for (var i = 0; i < 12; i++)
          TranscriptWord(
            text: 'w$i',
            phones: const [
              TranscriptPhone(
                phone: 'h',
                text: 'h',
                startTime: 0,
                endTime: 0.1,
              ),
            ],
          ),
      ];

      final before = wordIpaDerivationCount;
      for (final word in words) {
        expect(wordIpaSpelling(word), 'h');
      }
      expect(wordIpaDerivationCount, before + words.length);

      for (final word in words) {
        expect(wordIpaSpelling(word), 'h');
      }
      expect(wordIpaDerivationCount, before + words.length);
    });

    test('memoizes a word without displayable phones as null', () {
      const word = TranscriptWord(
        text: 'silent',
        phones: [
          TranscriptPhone(phone: '  ', text: '', startTime: 0, endTime: 0.1),
        ],
      );

      final before = wordIpaDerivationCount;
      expect(wordIpaSpelling(word), isNull);
      expect(wordIpaDerivationCount, before + 1);
      expect(wordIpaSpelling(word), isNull);
      expect(wordIpaDerivationCount, before + 1);
    });
  });
}
