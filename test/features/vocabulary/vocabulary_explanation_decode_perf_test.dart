import 'dart:convert';
import 'dart:math';

import 'package:enjoy_player/features/ai/domain/models/contextual_translation_result.dart';
import 'package:enjoy_player/features/ai/domain/models/dictionary_result.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_text_style.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _oracleAtx = RegExp(r'^(#{1,3})\s+(.+)$');

ContextualTranslationResult? freshDecodeContextual(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return ContextualTranslationResult.fromJson(json);
  } catch (_) {
    return null;
  }
}

DictionaryResult? freshDecodeDictionary(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return null;
    return DictionaryResult.fromJson(json);
  } catch (_) {
    return null;
  }
}

String freshStripHeading(String markdown) {
  final trimmed = markdown.trimLeft();
  if (trimmed.isEmpty) return markdown;
  final lines = trimmed.split('\n');
  final first = lines.first.trim();
  final match = _oracleAtx.firstMatch(first);
  if (match == null) return markdown;
  final title = match.group(2)!.trim().toLowerCase();
  const redundant = {
    '翻译',
    'translation',
    '译文',
    '语境翻译',
    'contextual translation',
  };
  if (!redundant.contains(title)) return markdown;
  return lines.skip(1).join('\n').trimLeft();
}

ContextualMarkdownDocument freshParseMarkdown(String markdown) {
  final prepared = freshStripHeading(markdown);
  if (prepared.trim().isEmpty) {
    return const ContextualMarkdownDocument(preamble: '', sections: []);
  }
  final lines = prepared.split('\n');
  final preamble = <String>[];
  final sections = <ContextualMarkdownSection>[];
  var i = 0;
  while (i < lines.length && !_oracleAtx.hasMatch(lines[i].trim())) {
    preamble.add(lines[i]);
    i++;
  }
  while (i < lines.length) {
    final match = _oracleAtx.firstMatch(lines[i].trim());
    i++;
    final body = <String>[];
    while (i < lines.length && !_oracleAtx.hasMatch(lines[i].trim())) {
      body.add(lines[i]);
      i++;
    }
    final bodyText = body.join('\n').trim();
    if (match == null || bodyText.isEmpty) continue;
    sections.add(
      ContextualMarkdownSection(title: match.group(2)!.trim(), body: bodyText),
    );
  }
  return ContextualMarkdownDocument(
    preamble: preamble.join('\n').trim(),
    sections: sections,
  );
}

String? canonicalJson(Object? result) {
  if (result == null) return null;
  if (result is DictionaryResult) return jsonEncode(result.toJson());
  if (result is ContextualTranslationResult) {
    return jsonEncode(result.toJson());
  }
  if (result is ContextualMarkdownDocument) {
    return jsonEncode({
      'preamble': result.preamble,
      'sections': [
        for (final s in result.sections) {'title': s.title, 'body': s.body},
      ],
    });
  }
  throw ArgumentError(result);
}

DictionaryResult dictionaryFixture({
  required int senseCount,
  required int exampleCount,
  int fill = 0,
}) {
  return DictionaryResult(
    word: 'accumulation',
    sourceLanguage: 'en',
    targetLanguage: 'zh-Hans$fill',
    lemma: 'accumulate',
    ipa: 'əˌkjuːmjəˈleɪʃn',
    senses: [
      for (var s = 0; s < senseCount; s++)
        DictionarySense(
          definition:
              'the ${s}_th gradual increase of something, such as money, '
              'knowledge, or snow, especially to a level that becomes '
              'noticeable or problematic over a long stretch of time $fill',
          translation: '积累；聚集；堆积物（第$s个义项）',
          partOfSpeech: s.isEven ? 'noun' : 'verb',
          notes: s % 3 == 0 ? 'often used with "of"' : null,
          examples: [
            for (var e = 0; e < exampleCount; e++)
              DictionaryExample(
                source:
                    'Heavy rain caused the $e-th accumulation of water in the '
                    'basement, and the residents had to call a plumber before '
                    'the situation got worse than it already was.',
                target: '大雨导致地下室积水的累积（$e），居民不得不叫水管工。',
              ),
          ],
        ),
    ],
  );
}

String contextualMarkdownFixture({int sections = 4, int linesPerSection = 6}) {
  final buffer = StringBuffer('## 翻译\n\nHere is the contextual rendering.\n');
  for (var s = 0; s < sections; s++) {
    buffer.write('\n### 第${s + 1}段\n\n');
    for (var l = 0; l < linesPerSection; l++) {
      buffer.write(
        'The highlighted phrase uses the word in its ${l + 1}-th sense; the '
        'surrounding clause supplies the temporal anchor for the reading.\n',
      );
    }
  }
  return buffer.toString();
}

final Random fuzzRandom = Random(20261115);

List<String> fuzzBlobs({required int count}) {
  final blobs = <String>[];
  for (var i = 0; i < count; i++) {
    switch (i % 7) {
      case 0:
        blobs.add(
          encodeDictionaryExplanation(
            dictionaryFixture(
              senseCount: 1 + fuzzRandom.nextInt(4),
              exampleCount: fuzzRandom.nextInt(3),
              fill: i,
            ),
          ),
        );
      case 1:
        blobs.add(
          encodeContextualExplanation(
            ContextualTranslationResult(
              translatedText: contextualMarkdownFixture(
                sections: 1 + fuzzRandom.nextInt(3),
              ),
            ),
          ),
        );
      case 2:
        blobs.add('[${fuzzRandom.nextInt(1000)}, "array"]');
      case 3:
        blobs.add('"just a string ${fuzzRandom.nextInt(1000)}"');
      case 4:
        blobs.add('{"word":"${fuzzRandom.nextInt(9999)}","truncat');
      case 5:
        blobs.add(
          '{"word":"w$i","sourceLanguage":"en","targetLanguage":"zh",'
          '"senses":[{"definition":"d"}]}',
        );
      default:
        blobs.add('   ');
    }
  }
  return blobs;
}

void main() {
  group('differential: lib decode equals fresh decode', () {
    test('dictionary blobs across fuzz corpus', () {
      for (final raw in fuzzBlobs(count: 700)) {
        final oracle = freshDecodeDictionary(raw);
        final actual = decodeDictionaryExplanation(raw);
        expect(canonicalJson(actual), canonicalJson(oracle));
      }
      expect(canonicalJson(decodeDictionaryExplanation(null)), isNull);
      expect(canonicalJson(decodeDictionaryExplanation('')), isNull);
    });

    test('contextual blobs across fuzz corpus', () {
      for (final raw in fuzzBlobs(count: 700)) {
        final oracle = freshDecodeContextual(raw);
        final actual = decodeContextualExplanation(raw);
        expect(canonicalJson(actual), canonicalJson(oracle));
      }
      expect(canonicalJson(decodeContextualExplanation(null)), isNull);
      expect(canonicalJson(decodeContextualExplanation('')), isNull);
    });

    test('contextual markdown documents across fuzz corpus', () {
      for (final raw in fuzzBlobs(count: 700)) {
        final oracleResult = freshDecodeContextual(raw);
        if (oracleResult == null) continue;
        expect(
          canonicalJson(
            parseContextualMarkdownDocument(oracleResult.translatedText),
          ),
          canonicalJson(freshParseMarkdown(oracleResult.translatedText)),
        );
      }
      expect(
        canonicalJson(parseContextualMarkdownDocument('')),
        canonicalJson(freshParseMarkdown('')),
      );
      expect(
        canonicalJson(parseContextualMarkdownDocument('   ')),
        canonicalJson(freshParseMarkdown('   ')),
      );
    });

    test('repeat calls stay stable', () {
      final blob = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 3, exampleCount: 2),
      );
      final first = canonicalJson(decodeDictionaryExplanation(blob));
      for (var i = 0; i < 5; i++) {
        expect(canonicalJson(decodeDictionaryExplanation(blob)), first);
      }
      final md = contextualMarkdownFixture();
      final mdFirst = canonicalJson(parseContextualMarkdownDocument(md));
      for (var i = 0; i < 5; i++) {
        expect(canonicalJson(parseContextualMarkdownDocument(md)), mdFirst);
      }
    });
  });
  group('structural: decode derivations', () {
    test('dictionary blob decodes once; repeat calls share the instance', () {
      final blob = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 2, exampleCount: 1),
      );
      dictionaryDecodeDerivationCount = 0;
      final first = decodeDictionaryExplanation(blob);
      expect(first, isNotNull);
      expect(dictionaryDecodeDerivationCount, 1);
      for (var i = 0; i < 10; i++) {
        expect(decodeDictionaryExplanation(blob), same(first));
      }
      expect(dictionaryDecodeDerivationCount, 1);
    });

    test('equal-content blob decodes once', () {
      final blob = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 2, exampleCount: 1, fill: 10002),
      );
      dictionaryDecodeDerivationCount = 0;
      decodeDictionaryExplanation(blob);
      decodeDictionaryExplanation(String.fromCharCodes(blob.codeUnits));
      expect(dictionaryDecodeDerivationCount, 1);
    });

    test('ninth distinct blob evicts the LRU entry', () {
      final blobs = [
        for (var i = 0; i < 8; i++)
          encodeDictionaryExplanation(
            dictionaryFixture(senseCount: 1, exampleCount: 0, fill: 10010 + i),
          ),
      ];
      dictionaryDecodeDerivationCount = 0;
      for (final b in blobs) {
        decodeDictionaryExplanation(b);
      }
      final ninth = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 1, exampleCount: 0, fill: 10099),
      );
      decodeDictionaryExplanation(ninth);
      decodeDictionaryExplanation(blobs[7]);
      expect(dictionaryDecodeDerivationCount, 9);
      decodeDictionaryExplanation(blobs[0]);
      expect(dictionaryDecodeDerivationCount, 10);
    });

    test('failed decodes are not cached', () {
      dictionaryDecodeDerivationCount = 0;
      expect(decodeDictionaryExplanation('{"word": "truncat'), isNull);
      expect(decodeDictionaryExplanation('{"word": "truncat'), isNull);
      expect(decodeDictionaryExplanation('[1, 2, 3]'), isNull);
      expect(decodeDictionaryExplanation('[1, 2, 3]'), isNull);
      expect(dictionaryDecodeDerivationCount, 4);
    });

    test('contextual blob decodes once; repeat calls share the instance', () {
      final blob = encodeContextualExplanation(
        const ContextualTranslationResult(
          translatedText: 'pin-only contextual body 10003',
        ),
      );
      contextualDecodeDerivationCount = 0;
      final first = decodeContextualExplanation(blob);
      expect(first, isNotNull);
      expect(contextualDecodeDerivationCount, 1);
      for (var i = 0; i < 5; i++) {
        expect(decodeContextualExplanation(blob), same(first));
      }
      expect(contextualDecodeDerivationCount, 1);
    });

    test('contextual markdown parses once; distinct text parses again', () {
      final md = contextualMarkdownFixture(sections: 2, linesPerSection: 3);
      contextualMarkdownParseCount = 0;
      final first = parseContextualMarkdownDocument(md);
      expect(first.sections, isNotEmpty);
      expect(contextualMarkdownParseCount, 1);
      for (var i = 0; i < 5; i++) {
        expect(parseContextualMarkdownDocument(md), same(first));
      }
      final other = contextualMarkdownFixture(sections: 2, linesPerSection: 4);
      parseContextualMarkdownDocument(other);
      expect(contextualMarkdownParseCount, 2);
    });
  });

  const int benchCalls = 200;

  test(
    'bench (local only): fresh dictionary decode, $benchCalls calls',
    skip: true,
    () {
      final blob = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 6, exampleCount: 2),
      );
      expect(blob.length, greaterThan(3000));
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += freshDecodeDictionary(blob)!.senses.length;
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchCalls; i++) {
        sink += freshDecodeDictionary(blob)!.senses.length;
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'fresh dictionary decode: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): cached dictionary decode, identical key, '
    '$benchCalls calls',
    skip: true,
    () {
      final blob = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 6, exampleCount: 2),
      );
      expect(decodeDictionaryExplanation(blob), isNotNull);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += decodeDictionaryExplanation(blob)!.senses.length;
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchCalls; i++) {
        sink += decodeDictionaryExplanation(blob)!.senses.length;
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'cached dictionary decode: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): cached dictionary decode, fresh equal-content key, '
    '$benchCalls calls',
    skip: true,
    () {
      final blob = encodeDictionaryExplanation(
        dictionaryFixture(senseCount: 6, exampleCount: 2),
      );
      expect(decodeDictionaryExplanation(blob), isNotNull);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += decodeDictionaryExplanation(
          String.fromCharCodes(blob.codeUnits),
        )!.senses.length;
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchCalls; i++) {
        sink += decodeDictionaryExplanation(
          String.fromCharCodes(blob.codeUnits),
        )!.senses.length;
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'cached dictionary decode (copy key): '
        '${sw.elapsedMicroseconds / 1000.0} ms (sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): fresh contextual markdown parse, $benchCalls calls',
    skip: true,
    () {
      final md = contextualMarkdownFixture(sections: 5, linesPerSection: 8);
      expect(md.length, greaterThan(2000));
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += freshParseMarkdown(md).sections.length;
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchCalls; i++) {
        sink += freshParseMarkdown(md).sections.length;
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'fresh markdown parse: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );

  test(
    'bench (local only): cached contextual markdown parse, $benchCalls calls',
    skip: true,
    () {
      final md = contextualMarkdownFixture(sections: 5, linesPerSection: 8);
      expect(parseContextualMarkdownDocument(md).sections, isNotEmpty);
      var sink = 0;
      for (var warm = 0; warm < 100; warm++) {
        sink += parseContextualMarkdownDocument(md).sections.length;
      }
      final sw = Stopwatch()..start();
      for (var i = 0; i < benchCalls; i++) {
        sink += parseContextualMarkdownDocument(md).sections.length;
      }
      sw.stop();
      // ignore: avoid_print
      print(
        'cached markdown parse: ${sw.elapsedMicroseconds / 1000.0} ms '
        '(sink $sink)',
      ); // ignore: avoid_print
    },
  );
}
