import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/ipa_mapping.dart';
import 'package:enjoy_player/data/subtitle/transcript_display_readiness.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/data/subtitle/transcript_word_ipa.dart';

/// A 35-word corpus of eSpeak phone chunks.
const List<List<String>> _kCorpus = <List<String>>[
  ['h', 'ə', 'ˈl', 'oʊ'],
  ['w', 'ɝld'],
  ['h', 'ɛ', 'ˈloʊ'],
  ['pɹɪri'],
  ['slɛpt'],
  ['naɪt'],
  ['h', 'ə', 'ɹ', 'oʊ'],
  ['ð', 'ə'],
  ['ˈk', 'ɑ', 'n', 'a', 'p'],
  ['w', 'ə', 'ˈt', 'a'],
  ['ˈm', 'ɔ', 'ɹ', 'ɪ', 'n'],
  ['b', 'ɪ', 's', 'ˈn', 'aɪ'],
  ['ˈf', 'ɪ', 'n', 'ɪ', 'ʃ'],
  ['ˈl', 'ʌ', 'v'],
  ['ˈw', 'ɔ', 'ɹ', 'd'],
  ['ˈt', 'ɪ', 'm', 'ə'],
  ['ˈj', 'u', 's', 't'],
  ['ˈh', 'æ', 'p', 'i'],
  ['ˈb', 'ɛ', 'n', 'd'],
  ['ˈst', 'r', 'aɪ', 't'],
  ['ɹ', 'əʊ', 'd'],
  ['ˈk', 'ɛ', 'n'],
  ['ˈɡ', 'ʌ', 'd'],
  ['ˈv', 'ɛ', 'l', 'i'],
  ['ˈt', 'ɹ', 'aɪ', 'n'],
  ['ˈpl', 'e', 'n', 'i'],
  ['ˈb', 'ʌ', 't'],
  ['ˈfl', 'aʊ', 'n', 'd'],
  ['ˈgr', 'eɪ', 'n'],
  ['ˈbr', 'ɛ', 'k'],
  ['ˈθ', 'r', 'i'],
  ['ˈk', 'ʌ', 'n'],
  ['ˈst', 'r', 'ə', 'ŋ', 'θ'],
];

const int _kVisibleRows = 40;
const int _kWordsPerRow = 12;
const int _kTranscriptLines = 2000;

/// The visible window of a transcript list, rebuilt on every cue change.
List<TranscriptWord> _buildVisibleWindow() {
  final words = <TranscriptWord>[];
  for (var i = 0; i < _kVisibleRows * _kWordsPerRow; i++) {
    final phones = _kCorpus[i % _kCorpus.length];
    words.add(
      TranscriptWord(
        text: 'w$i',
        phones: [
          for (final phone in phones)
            TranscriptPhone(phone: phone, text: phone),
        ],
      ),
    );
  }
  return words;
}

/// The familiar form derived from scratch, without the per-word memo.
String? deriveUnmemoized(TranscriptWord word) {
  final pieces = wordIpaPieces(word);
  if (pieces.isEmpty) return null;
  final spelling = formatPhonesAsFamiliarIpa(pieces);
  return spelling.isEmpty ? null : spelling;
}

/// A transcript of [_kTranscriptLines] timed cues, each with one phone.
List<TranscriptLine> _buildTranscript() {
  return [
    for (var i = 0; i < _kTranscriptLines; i++)
      TranscriptLine(
        text: 'line $i',
        startMs: i * 1000,
        durationMs: 900,
        timeline: [
          TranscriptWord(
            text: 'w$i',
            startMs: 0,
            durationMs: 500,
            phones: const [
              TranscriptPhone(
                phone: 'h',
                text: 'h',
                startTime: 0,
                endTime: 0.1,
              ),
            ],
          ),
        ],
      ),
  ];
}

void main() {
  test('derives the familiar form of every visible word', () {
    final words = _buildVisibleWindow();
    expect(words, hasLength(_kVisibleRows * _kWordsPerRow));
    for (final word in words) {
      expect(wordIpaSpelling(word), isNotNull);
    }
  });

  test(
    'rebuilding the visible window stays under the loose ceiling (local only)',
    () {
      final words = _buildVisibleWindow();
      final mode = Platform.environment['IPA_BENCH_MODE'] ?? 'memoized';
      final derive = mode == 'unmemoized' ? deriveUnmemoized : wordIpaSpelling;

      for (final word in words) {
        derive(word);
      }

      final sw = Stopwatch()..start();
      const runs = 200;
      var sink = 0;
      for (var i = 0; i < runs; i++) {
        for (final word in words) {
          sink += derive(word)?.length ?? 0;
        }
      }
      sw.stop();

      final medianMs = sw.elapsedMicroseconds / runs / 1000;
      // ignore: avoid_print
      print(
        'familiar IPA rebuild ($mode): '
        '${medianMs.toStringAsFixed(3)} ms/pass '
        '(${words.length} visible words, sink=$sink)',
      );
      expect(medianMs, lessThan(100));
    },
    skip: 'Local-only microbenchmark; run with --run-skipped.',
  );

  test('scanning a transcript for readiness stays under the loose ceiling '
      '(local only)', () {
    const runs = 20;
    var sink = 0;
    var elapsedUs = 0;
    for (var i = 0; i < runs; i++) {
      final lines = _buildTranscript();
      final sw = Stopwatch()..start();
      final readiness = transcriptDisplayReadiness(
        lines: lines,
        canTrustWordTimes: true,
      );
      sw.stop();
      elapsedUs += sw.elapsedMicroseconds;
      sink += readiness.hasPhones ? 1 : 0;
    }

    final medianMs = elapsedUs / runs / 1000;
    // ignore: avoid_print
    print(
      'transcript readiness scan: ${medianMs.toStringAsFixed(3)} ms/pass '
      '($_kTranscriptLines fresh lines, sink=$sink)',
    );
    expect(medianMs, lessThan(100));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
