import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';

const int _kSweepLines = 512;
const int _kWindowLines = 40;
const int _kWarmup = 100;
const int _kRounds = 3;

final List<String> _kMarkupPrefixes = <String>[
  '<font color="#E5E5E5">',
  '<font color="#CCCCCC">',
  '<b>',
  '',
  '<i>',
];

const List<String> _kSentenceSeeds = <String>[
  'well I think that this is',
  'the first thing you notice',
  'and then it all comes down',
  'somebody has to make a call',
  'I never really thought about',
  'it was a long time ago',
  'so what are you going to do',
  'that is not how it works',
  'we should probably get going',
  'you have to see it to believe',
  'everything happened so fast',
  'do you remember that night',
  'it makes perfect sense now',
  'there is nothing left to say',
  'I will take care of it',
  'how did you find out',
  'nobody knew where it was',
  'that is a strange question',
  'one more thing before we go',
  'it always ends like this',
];

String _cueText(int i) {
  final seed = _kSentenceSeeds[i % _kSentenceSeeds.length];
  final prefix = _kMarkupPrefixes[(i ~/ 7) % _kMarkupPrefixes.length];
  if (prefix.isEmpty) {
    if (i % 23 == 0) return '你好世界，这是第 $i 行。';
    if (i % 17 == 0) return 'Café déjà vu — naïve résumé $i.';
    return '$seed ($i)';
  }
  final tail = i % 11 == 0 ? '<br>second part $i' : '';
  return '$prefix$seed, cue $i.</font>$tail';
}

List<TranscriptLine> _buildLines() {
  return [
    for (var i = 0; i < _kSweepLines; i++)
      TranscriptLine(text: _cueText(i), startMs: i * 2400, durationMs: 2300),
  ];
}

List<TranscriptLine> _buildWindow() => _buildLines().sublist(0, _kWindowLines);

/// The pre-memoization derivation: parse, trim, FNV-1a, stringify.
String _legacyCueIdFor(TranscriptLine line) {
  final start = line.startMs;
  final end = line.startMs + line.durationMs;
  final plain = plainTextFromSubtitleMarkup(line.text).trim();
  if (plain.isEmpty) {
    return '__invalid__:$start:$end';
  }
  var hash = 0x811c9dc5;
  for (final code in plain.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return '$start:$end:${hash.toRadixString(16)}';
}

double _benchWindow(String Function(TranscriptLine) derive) {
  final window = _buildWindow();
  for (final line in window) {
    derive(line);
  }
  final roundMedians = <double>[];
  var sink = 0;
  for (var round = 0; round < _kRounds; round++) {
    final samples = <double>[];
    for (var sample = 0; sample < _kWarmup ~/ 2; sample++) {
      final sw = Stopwatch()..start();
      for (var i = 0; i < 5; i++) {
        for (final line in window) {
          sink += derive(line).length;
        }
      }
      sw.stop();
      samples.add(sw.elapsedMicroseconds / 1000 / 5);
    }
    samples.sort();
    roundMedians.add(samples[samples.length ~/ 2]);
  }
  // ignore: avoid_print
  print(
    'cue-id window rounds: '
    '${roundMedians.map((m) => m.toStringAsFixed(4)).join(' / ')} ms/pass '
    '(${window.length} lines, 200 derivations/pass, sink=$sink)',
  );
  return roundMedians[roundMedians.length ~/ 2];
}

double _benchSweep(String Function(TranscriptLine) derive) {
  final rounds = <double>[];
  var sink = 0;
  for (var round = 0; round < _kRounds; round++) {
    for (var i = 0; i < _kWarmup ~/ 2; i++) {
      sink += derive(_buildLines()[i]).length;
    }
    final samples = <double>[];
    for (var sample = 0; sample < 30; sample++) {
      final lines = _buildLines();
      final sw = Stopwatch()..start();
      for (final line in lines) {
        sink += derive(line).length;
      }
      sw.stop();
      samples.add(sw.elapsedMicroseconds / 1000);
    }
    samples.sort();
    rounds.add(samples[samples.length ~/ 2]);
  }
  // ignore: avoid_print
  print(
    'cue-id sweep rounds: '
    '${rounds.map((m) => m.toStringAsFixed(3)).join(' / ')} ms/sweep '
    '($_kSweepLines fresh lines, sink=$sink)',
  );
  return rounds[rounds.length ~/ 2];
}

void main() {
  test('cue ids match the legacy derivation over the corpus', () {
    final lines = <TranscriptLine>[
      ..._buildLines(),
      const TranscriptLine(text: '', startMs: 100, durationMs: 500),
      const TranscriptLine(
        text: '<font color="#E5E5E5">   </font>',
        startMs: 0,
        durationMs: 0,
      ),
    ];
    for (final line in lines) {
      expect(cueIdFor(line), _legacyCueIdFor(line));
    }
  });

  test('derives each window line once and reuses the memo', () {
    final lines = _buildLines().sublist(0, 8);
    final before = cueIdDerivationCount;
    final ids = <String>[];
    for (var pass = 0; pass < 10; pass++) {
      for (final line in lines) {
        ids.add(cueIdFor(line));
      }
    }
    expect(ids, hasLength(80));
    expect(ids.toSet(), hasLength(8));
    expect(cueIdDerivationCount, before + 8);
  });

  test('a fresh equal-content line derives its own memo entry', () {
    const a = TranscriptLine(
      text: 'memo identity probe',
      startMs: 99000,
      durationMs: 1000,
    );
    final b =
        // ignore: prefer_const_constructors
        TranscriptLine(
          text: 'memo identity probe',
          startMs: 99000,
          durationMs: 1000,
        );
    expect(a, isNot(same(b)));
    final before = cueIdDerivationCount;
    expect(cueIdFor(a), cueIdFor(b));
    expect(cueIdDerivationCount, before + 2);
    expect(cueIdFor(a), _legacyCueIdFor(a));
    expect(cueIdFor(b), _legacyCueIdFor(b));
  });

  test('warm-window derivation stays under the loose ceiling (local only)', () {
    final mode = Platform.environment['CUE_ID_BENCH_MODE'] ?? 'memoized';
    final derive = mode == 'legacy' ? _legacyCueIdFor : cueIdFor;
    final medianMs = _benchWindow(derive);
    expect(medianMs, lessThan(50));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('fresh-line sweep stays under the loose ceiling (local only)', () {
    final mode = Platform.environment['CUE_ID_BENCH_MODE'] ?? 'memoized';
    final derive = mode == 'legacy' ? _legacyCueIdFor : cueIdFor;
    final medianMs = _benchSweep(derive);
    expect(medianMs, lessThan(100));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
