import 'dart:math';

import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:flutter_test/flutter_test.dart';

bool legacyMeetsMin(String input) =>
    normalizeCraftText(input).length >= craftMinTextLength;

bool legacyIsDirty(String raw, String rewritten) =>
    normalizeCraftText(raw) != normalizeCraftText(rewritten);

bool scanMeetsMin(String input) => meetsCraftMinTextLength(input);

int scanCollapsedLength(String input) => collapsedLength(input);

List<CraftJobState> dirtyStates(List<(String, String)> pairs) => [
  for (final (raw, rewritten) in pairs)
    CraftJobState(rawTranscript: raw, rewrittenFromTranscript: rewritten),
];

bool stateIsDirty(CraftJobState state) => state.isRawTranscriptDirty;

const List<String> fuzzAlphabet = [
  'a',
  'z',
  'A',
  'Z',
  '0',
  '9',
  '-',
  ' ',
  '\t',
  '\n',
  '\r',
  '\u000B',
  '\u000C',
  ' ',
  '\u0085',
  ' ',
  ' ',
  ' ',
  ' ',
  ' ',
  ' ',
  ' ',
  ' ',
  '　',
  '﻿',
  '​',
  '中',
  '\u{1F600}',
  'é',
];

String fuzzString(Random random, {int? length}) {
  final n = length ?? random.nextInt(65);
  return [
    for (var i = 0; i < n; i++)
      fuzzAlphabet[random.nextInt(fuzzAlphabet.length)],
  ].join();
}

List<String> fuzzCorpus({required int count, int offset = 0}) {
  final random = Random(20261117 + offset);
  return [for (var i = 0; i < count; i++) fuzzString(random)];
}

void expectGateAgrees(String input) {
  expect(
    scanMeetsMin(input),
    legacyMeetsMin(input),
    reason: 'meets: ${String.fromCharCodes(input.codeUnits)}',
  );
  expect(
    scanCollapsedLength(input),
    normalizeCraftText(input).length,
    reason: 'length: ${String.fromCharCodes(input.codeUnits)}',
  );
}

void expectDirtyAgrees(String raw, String rewritten) {
  final state = CraftJobState(
    rawTranscript: raw,
    rewrittenFromTranscript: rewritten,
  );
  expect(
    state.isRawTranscriptDirty,
    legacyIsDirty(raw, rewritten),
    reason:
        'dirty: raw=${String.fromCharCodes(raw.codeUnits)} '
        'rewritten=${String.fromCharCodes(rewritten.codeUnits)}',
  );
}

void main() {
  group('differential: scans equal the collapse+trim composition', () {
    test('curated edge inputs', () {
      const nine = 'aaaaaaaaa';
      const ten = 'aaaaaaaaaa';
      final edges = <String>[
        '',
        ' ',
        '\t\n\r\u000B\u000C',
        '   　﻿',
        '    ',
        '  ',
        '​​​',
        '\u0085\u0085\u0085',
        nine,
        ten,
        '$ten x',
        '$nine x',
        '$nine  ',
        '$nine \t\n ',
        ' $ten',
        '  \n$ten\t ',
        '$nine x $nine',
        'a\u0085b',
        '\u0085ab',
        'ab\u0085',
        '\u0085ab\u0085',
        'a \u0085 b',
        'a \u0085b',
        'a  b',
        'a  b',
        '﻿ab﻿',
        'héllo wörld \u{1F600} 中文字',
        'one two three four',
        'one  two\t three',
        'a​b',
        'a b',
      ];
      for (final input in edges) {
        expectGateAgrees(input);
      }
    });

    test('exact boundary counts', () {
      expectGateAgrees('x' * 9);
      expectGateAgrees('x' * 10);
      expectGateAgrees('x' * 11);
      expectGateAgrees('${'x' * 9}${' ' * 40}');
      expectGateAgrees('${'x' * 9}\u0085\u0085');
      expectGateAgrees('${'x' * 8}\u0085\u0085b');
      expectGateAgrees('${' ' * 40}${'x' * 9}');
      expectGateAgrees('${'x y ' * 4}z');
      expectGateAgrees('${'x' * 9} x');
      expectGateAgrees('x ${'y' * 9}');
    });

    test('exhaustive BMP sweep, interior position', () {
      for (var unit = 0; unit <= 0xFFFF; unit++) {
        if (unit >= 0xD800 && unit <= 0xDFFF) continue;
        expectGateAgrees('a${String.fromCharCode(unit)}b');
      }
    });

    test('exhaustive BMP sweep, leading and trailing positions', () {
      for (var unit = 0; unit <= 0xFFFF; unit++) {
        if (unit >= 0xD800 && unit <= 0xDFFF) continue;
        final c = String.fromCharCode(unit);
        expectGateAgrees('$c ab');
        expectGateAgrees('ab $c');
        expectGateAgrees(c);
      }
    });

    test('astral and unpaired-surrogate samples', () {
      final samples = [
        '\u{10000}',
        '\u{1F600}',
        '\u{10FFFF}',
        '\uD800',
        '\uDC00',
        'a\uD800b',
        'a\uDC00b',
        '\uD800ab',
        'ab\uDC00',
        '\u{1F600}\u{1F600}\u{1F600}',
      ];
      for (final sample in samples) {
        expectGateAgrees(sample);
        expectGateAgrees('$sample${'x' * 9}');
        expectGateAgrees('${'x' * 9}$sample');
      }
    });

    test('fuzz corpus, gate and collapsed length', () {
      for (final input in fuzzCorpus(count: 1000)) {
        expectGateAgrees(input);
      }
    });

    test('fuzz corpus, dirty getter', () {
      final corpus = fuzzCorpus(count: 500);
      for (var i = 0; i < corpus.length; i++) {
        expectDirtyAgrees(corpus[i], corpus[(i * 7 + 3) % corpus.length]);
        expectDirtyAgrees(corpus[i], corpus[i]);
        expectDirtyAgrees(corpus[i], '${corpus[i]}  \t\n\u0085   ');
        expectDirtyAgrees('  ${corpus[i]} \n', corpus[i]);
      }
    });

    test('dirty getter pins', () {
      const clean = CraftJobState(
        rawTranscript: 'hello world',
        rewrittenFromTranscript: 'hello world',
      );
      expect(clean.isRawTranscriptDirty, isFalse);
      const whitespaceOnly = CraftJobState(
        rawTranscript: '  hello \t world \u0085\n',
        rewrittenFromTranscript: 'hello world',
      );
      expect(whitespaceOnly.isRawTranscriptDirty, isFalse);
      const sameLengthDifferent = CraftJobState(
        rawTranscript: 'aaaaab',
        rewrittenFromTranscript: 'aaaaba',
      );
      expect(sameLengthDifferent.isRawTranscriptDirty, isTrue);
      const lengthDifference = CraftJobState(
        rawTranscript: 'edited text now longer',
        rewrittenFromTranscript: 'short',
      );
      expect(lengthDifference.isRawTranscriptDirty, isTrue);
      const emptyPair = CraftJobState();
      expect(emptyPair.isRawTranscriptDirty, isFalse);
    });
  });

  String typingToken(int i) {
    const words = ['hello', 'the', 'world', 'foo', 'bar'];
    final word = words[i % words.length];
    return switch (i % 5) {
      0 => word,
      1 => '$word ',
      2 => ' $word',
      3 => '$word\t',
      _ => '$word  ',
    };
  }

  List<String> typingStates(int targetLength) {
    final buffer = StringBuffer();
    var i = 0;
    while (buffer.length < targetLength) {
      buffer.write(typingToken(i++));
    }
    final text = buffer.toString();
    return [
      for (var cut = 1; cut <= 50; cut++)
        text.substring(
          0,
          (text.length * cut / 50).floor().clamp(1, text.length),
        ),
    ];
  }

  String longText(int length, {bool whitespaceHeavy = false}) {
    final random = Random(42);
    return [
      for (var i = 0; i < length; i++)
        whitespaceHeavy
            ? switch (random.nextInt(3)) {
                0 => ' ',
                1 => '\t',
                _ => fuzzAlphabet[random.nextInt(6)],
              }
            : fuzzAlphabet[random.nextInt(fuzzAlphabet.length)],
    ].join();
  }

  List<(String, String)> editedPairs() {
    final corpus = fuzzCorpus(count: 50, offset: 900);
    return [
      for (var i = 0; i < 50; i++)
        (
          '${corpus[i]} ${'x' * (i % 9)}',
          '${corpus[i]} ${'y' * ((i + 1) % 7)}',
        ),
    ];
  }

  int runGatePass(List<String> inputs, bool Function(String) gate) {
    var sink = 0;
    for (final input in inputs) {
      if (gate(input)) sink++;
    }
    return sink;
  }

  int runDirtyPass(
    List<CraftJobState> states,
    bool Function(CraftJobState) dirty,
  ) {
    var sink = 0;
    for (final state in states) {
      if (dirty(state)) sink++;
    }
    return sink;
  }

  const int benchPasses = 200;

  test(
    'bench (local only): legacy gate, $benchPasses passes over 50 typing '
    'states',
    skip: true,
    () {
      final inputs = typingStates(60);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runGatePass(inputs, legacyMeetsMin);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runGatePass(inputs, legacyMeetsMin);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy typing gate: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      );
    },
  );

  test(
    'bench (local only): scan gate, $benchPasses passes over 50 typing states',
    skip: true,
    () {
      final inputs = typingStates(60);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runGatePass(inputs, scanMeetsMin);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runGatePass(inputs, scanMeetsMin);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'scan typing gate: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      );
    },
  );

  test(
    'bench (local only): legacy gate, $benchPasses passes over 50 mid-texts',
    skip: true,
    () {
      final inputs = [
        for (var i = 0; i < 50; i++)
          longText(400 + i * 4, whitespaceHeavy: i.isOdd),
      ];
      var sink = 0;
      for (var warm = 0; warm < 20; warm++) {
        sink += runGatePass(inputs, legacyMeetsMin);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runGatePass(inputs, legacyMeetsMin);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy mid gate: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      );
    },
  );

  test(
    'bench (local only): scan gate, $benchPasses passes over 50 mid-texts',
    skip: true,
    () {
      final inputs = [
        for (var i = 0; i < 50; i++)
          longText(400 + i * 4, whitespaceHeavy: i.isOdd),
      ];
      var sink = 0;
      for (var warm = 0; warm < 20; warm++) {
        sink += runGatePass(inputs, scanMeetsMin);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runGatePass(inputs, scanMeetsMin);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'scan mid gate: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      );
    },
  );

  test(
    'bench (local only): legacy gate, $benchPasses passes over the 5000-char '
    'maximum',
    skip: true,
    () {
      final inputs = [
        for (var i = 0; i < 50; i++)
          longText(4800 + i * 4, whitespaceHeavy: i.isOdd),
      ];
      var sink = 0;
      for (var warm = 0; warm < 20; warm++) {
        sink += runGatePass(inputs, legacyMeetsMin);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runGatePass(inputs, legacyMeetsMin);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy 5000-char gate: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      );
    },
  );

  test(
    'bench (local only): scan gate, $benchPasses passes over the 5000-char '
    'maximum',
    skip: true,
    () {
      final inputs = [
        for (var i = 0; i < 50; i++)
          longText(4800 + i * 4, whitespaceHeavy: i.isOdd),
      ];
      var sink = 0;
      for (var warm = 0; warm < 20; warm++) {
        sink += runGatePass(inputs, scanMeetsMin);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runGatePass(inputs, scanMeetsMin);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'scan 5000-char gate: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      );
    },
  );

  test(
    'bench (local only): legacy dirty getter, $benchPasses passes over 50 '
    'edited pairs',
    skip: true,
    () {
      final pairs = editedPairs();
      bool legacyArm(CraftJobState state) => legacyIsDirty(
        state.rawTranscript ?? '',
        state.rewrittenFromTranscript ?? '',
      );
      final states = dirtyStates(pairs);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runDirtyPass(states, legacyArm);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runDirtyPass(states, legacyArm);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'legacy dirty getter: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      );
    },
  );

  test(
    'bench (local only): scan dirty getter, $benchPasses passes over 50 '
    'edited pairs',
    skip: true,
    () {
      final pairs = editedPairs();
      final states = dirtyStates(pairs);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += runDirtyPass(states, stateIsDirty);
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchPasses; i++) {
        sink += runDirtyPass(states, stateIsDirty);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'scan dirty getter: ${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      );
    },
  );
}
