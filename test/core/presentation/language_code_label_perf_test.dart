import 'dart:math';

import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:flutter_test/flutter_test.dart';

String legacyLanguageCodeLabel(String tag) {
  final primary = tag.split(RegExp('[-_]')).first.trim();
  return primary.isEmpty ? tag.toUpperCase() : primary.toUpperCase();
}

const List<String> fuzzAlphabet = [
  'a',
  'z',
  'A',
  'Z',
  '0',
  '9',
  '-',
  '_',
  ' ',
  '\t',
  '\n',
  '\u0085',
  ' ',
  '中',
  '\u{1F600}',
  'é',
];

String fuzzString(Random random, {int? length}) {
  final n = length ?? random.nextInt(17);
  return [
    for (var i = 0; i < n; i++)
      fuzzAlphabet[random.nextInt(fuzzAlphabet.length)],
  ].join();
}

List<String> fuzzCorpus({required int count, int offset = 0}) {
  final random = Random(20261127 + offset);
  return [for (var i = 0; i < count; i++) fuzzString(random)];
}

void expectLabelAgrees(String input) {
  expect(
    languageCodeLabel(input),
    legacyLanguageCodeLabel(input),
    reason: 'label: ${String.fromCharCodes(input.codeUnits)}',
  );
}

void main() {
  group('differential: scan equals the split+trim composition', () {
    test('curated edge inputs', () {
      final edges = <String>[
        '',
        ' ',
        '\t',
        '\n',
        '-',
        '_',
        '-_',
        '--',
        '__',
        'en',
        'EN',
        'en-US',
        'en_US',
        '-US',
        '_us',
        'en-US-',
        'zh-Hant-TW',
        'zh_Hant_TW',
        'es-419',
        'es_419',
        'i-klingon',
        'x-custom',
        'nb-NO',
        'nn',
        'und',
        'EN-us',
        '  en-US  ',
        '\ten-US\t',
        ' en ',
        '\u0085en\u0085',
        ' en _US ',
        'é',
        'é-US',
        '\u{1F600}',
        '\u{1F600}-\u{1F601}',
        '\u{1F600} en',
        '中',
        '中-US',
      ];
      for (final input in edges) {
        expectLabelAgrees(input);
      }
    });

    test('exhaustive BMP sweep, interior and edge positions', () {
      for (var unit = 0; unit <= 0xFFFF; unit++) {
        if (unit >= 0xD800 && unit <= 0xDFFF) continue;
        final c = String.fromCharCode(unit);
        expectLabelAgrees('a${c}US');
        expectLabelAgrees('$c-US');
        expectLabelAgrees('en-$c');
        expectLabelAgrees('en-$c-US');
        expectLabelAgrees(c);
      }
    });

    test('astral and unpaired-surrogate samples', () {
      final samples = [
        '\u{10000}',
        '\u{1F600}',
        '\u{10FFFF}',
        '\uD800',
        '\uDC00',
        'a\uD800-US',
        'a\uDC00_US',
        '\uD800ab',
        'ab\uDC00',
        '\u{1F600}\u{1F600}-\u{1F600}',
      ];
      for (final sample in samples) {
        expectLabelAgrees(sample);
        expectLabelAgrees('$sample-US');
        expectLabelAgrees('en-$sample');
      }
    });

    test('fuzz corpus', () {
      for (final input in fuzzCorpus(count: 2000)) {
        expectLabelAgrees(input);
      }
    });
  });

  test('label pins', () {
    expect(languageCodeLabel('en-US'), 'EN');
    expect(languageCodeLabel('zh-Hant-TW'), 'ZH');
    expect(languageCodeLabel('ja'), 'JA');
    expect(languageCodeLabel('es-419'), 'ES');
    expect(languageCodeLabel('nb-NO'), 'NB');
    expect(languageCodeLabel('nn'), 'NN');
    expect(languageCodeLabel(''), '');
    expect(languageCodeLabel('-US'), '-US');
    expect(languageCodeLabel('_us'), '_US');
    expect(languageCodeLabel('  en-US  '), 'EN');
    expect(languageCodeLabel('  '), '  ');
    expect(languageCodeLabel('und'), 'UND');
  });

  const int benchPasses = 200;
  const int benchSamples = 30;
  const int benchRounds = 3;

  final benchTags = [
    for (var i = 0; i < 502; i++)
      const [
        'en-US',
        'en',
        'zh-CN',
        'zh-TW',
        'ja',
        'ko',
        'de',
        'fr',
        'es-419',
        'pt-BR',
        'it',
        'ru',
        'nb-NO',
        'nn',
        'no',
        'und',
        'en_GB',
        'zh_Hant',
        'fr-CA',
        'de-AT',
        'es-MX',
        'ja-JP',
        'ko-KR',
        'th',
        'vi',
        'ar',
        'hi',
      ][i % 27],
  ];

  int runLabelPass(List<String> tags, String Function(String) label) {
    var sink = 0;
    for (final tag in tags) {
      sink += label(tag).length;
    }
    return sink;
  }

  List<double> benchRoundsMs(
    int Function(List<String>, String Function(String)) run,
    List<String> tags,
    String Function(String) label,
  ) {
    for (var warm = 0; warm < benchPasses; warm++) {
      run(tags, label);
    }
    return [
      for (var round = 0; round < benchRounds; round++)
        () {
          final samples = <double>[];
          for (var s = 0; s < benchSamples; s++) {
            final sw = Stopwatch()..start();
            run(tags, label);
            sw.stop();
            samples.add(sw.elapsedMicroseconds / 1000);
          }
          samples.sort();
          return samples[samples.length ~/ 2];
        }(),
    ];
  }

  test(
    'bench (local only): legacy split+trim label, 502-tag corpus',
    skip: true,
    () {
      final rounds = benchRoundsMs(
        runLabelPass,
        benchTags,
        legacyLanguageCodeLabel,
      );
      var sink = 0;
      for (var i = 0; i < benchPasses; i++) {
        sink += runLabelPass(benchTags, legacyLanguageCodeLabel);
      }
      // ignore: avoid_print
      print(
        'legacy rounds ms ${rounds.map((m) => m.toStringAsFixed(4))} sink $sink',
      );
    },
  );

  test('bench (local only): scan label, 502-tag corpus', skip: true, () {
    final rounds = benchRoundsMs(runLabelPass, benchTags, languageCodeLabel);
    var sink = 0;
    for (var i = 0; i < benchPasses; i++) {
      sink += runLabelPass(benchTags, languageCodeLabel);
    }
    // ignore: avoid_print
    print(
      'scan rounds ms ${rounds.map((m) => m.toStringAsFixed(4))} sink $sink',
    );
  });
}
