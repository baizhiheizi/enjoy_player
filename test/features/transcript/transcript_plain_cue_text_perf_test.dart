import 'dart:io';
import 'dart:math';

import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_line_tile.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_markup.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/transcript_settings_overrides.dart';

class _BlurMode extends TranscriptBlurMode {
  _BlurMode(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;
}

void main() {
  Widget harness(Widget child) {
    return ProviderScope(
      overrides: [
        transcriptBlurModeProvider.overrideWith(() => _BlurMode(true)),
        ...transcriptWordPracticeOffOverrides(),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('derives the plain cue text once per tile build', (tester) async {
    const line = TranscriptLine(
      text: 'A plain cue without markup',
      startMs: 0,
      durationMs: 2000,
    );
    TranscriptLineTile tile() => TranscriptLineTile(
      line: line,
      mediaId: 'm1',
      secondaryText: null,
      isActive: false,
      inEcho: false,
      groupedInEcho: false,
      selectable: false,
      onTap: () {},
    );

    await tester.pumpWidget(harness(tile()));
    await tester.pumpAndSettle();

    final before = transcriptPlainDerivationCount;
    await tester.pumpWidget(harness(tile()));
    await tester.pumpAndSettle();
    expect(transcriptPlainDerivationCount, before + 1);

    await tester.pumpWidget(harness(tile()));
    await tester.pumpAndSettle();
    expect(transcriptPlainDerivationCount, before + 2);
  });

  test('matches the pre-fast-path parser over the markup corpus', () {
    for (final input in _kMarkupCorpus) {
      _expectSegmentsEqual(
        parseSubtitleMarkup(input),
        _legacyParseSubtitleMarkup(input),
        input,
      );
      expect(
        transcriptPlainForSelection(input),
        _legacyPlainForSelection(input),
        reason: 'plain selection text differs for ${_describe(input)}',
      );
    }
  });

  test('matches the pre-fast-path parser over a markup-heavy fuzz corpus', () {
    final rng = Random(20261031);
    const alphabet = '<>&;"\'=abcde AB012/\n#';
    for (var i = 0; i < 2000; i++) {
      final length = rng.nextInt(40);
      final input = String.fromCharCodes([
        for (var j = 0; j < length; j++)
          alphabet.codeUnitAt(rng.nextInt(alphabet.length)),
      ]);
      _expectSegmentsEqual(
        parseSubtitleMarkup(input),
        _legacyParseSubtitleMarkup(input),
        input,
      );
      expect(
        transcriptPlainForSelection(input),
        _legacyPlainForSelection(input),
        reason: 'plain selection text differs for ${_describe(input)}',
      );
    }
  });

  test('deriving plain cue text across a visible window and a scroll stays '
      'under the loose ceiling (local only)', () {
    final mode = Platform.environment['PLAIN_BENCH_MODE'] ?? 'fast';
    final String Function(String) derive = mode == 'legacy'
        ? _legacyPlainForSelection
        : transcriptPlainForSelection;

    final windowTexts = _plainCorpus(40, 1);
    final sweepTexts = _plainCorpus(512, 2);

    for (final text in windowTexts) {
      derive(text);
    }
    for (final text in sweepTexts) {
      derive(text);
    }

    const windowRuns = 200;
    var windowSink = 0;
    var windowWatch = Stopwatch()..start();
    for (var i = 0; i < windowRuns; i++) {
      for (final text in windowTexts) {
        windowSink += derive(text).length;
      }
    }
    windowWatch.stop();

    const sweepWarmup = 20;
    const sweepRuns = 100;
    for (var i = 0; i < sweepWarmup; i++) {
      for (final text in sweepTexts) {
        derive(text);
      }
    }
    var sweepSink = 0;
    var sweepWatch = Stopwatch()..start();
    for (var i = 0; i < sweepRuns; i++) {
      for (final text in sweepTexts) {
        sweepSink += derive(text).length;
      }
    }
    sweepWatch.stop();

    final windowMs = windowWatch.elapsedMicroseconds / windowRuns / 1000;
    final sweepMs = sweepWatch.elapsedMicroseconds / sweepRuns / 1000;
    // ignore: avoid_print
    print(
      'plain cue text ($mode): window ${windowMs.toStringAsFixed(4)} '
      'ms/pass (40 rows), sweep ${sweepMs.toStringAsFixed(4)} '
      'ms/sweep (512 rows), sink=$windowSink/$sweepSink',
    );
    expect(windowMs, lessThan(100));
    expect(sweepMs, lessThan(100));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}

const List<String> _kMarkupCorpus = <String>[
  'Plain cue text without any markup',
  'two  spaces   and a tab',
  '<b>bold</b> tail',
  '<i>italic</i>',
  '<u>under</u>',
  '<strong>strong</strong>',
  '<em>em</em>',
  '<br>after break',
  'line one<br/>line two',
  '<font color="#FF0000">red</font>',
  '<font color="red">named</font>',
  '<font color=#00FF00>unquoted attr</font>',
  '&amp;&lt;&gt;&quot;&apos;',
  '&#65;&#x42;',
  '&unknown;',
  'bare & ampersand',
  'stray < bracket',
  'lone <b',
  'a<b>c',
  '<b>a<i>b</i>c</b>',
  '<font color="#FF0000">red <b>bold red</b></font>',
  '',
  '   ',
  'emoji 🎬 cue',
  '中文台词 without markup',
];

const List<String> _kWords = <String>[
  'the',
  'quick',
  'brown',
  'fox',
  'jumps',
  'over',
  'lazy',
  'dog',
  'morning',
  'light',
  'river',
  'flows',
  'through',
  'quiet',
  'valley',
  'shadow',
  'reading',
  'practice',
  'listening',
  'speaking',
  'cue',
  'text',
  'plain',
  'markup',
  'transcript',
  'line',
  'window',
  'scroll',
  'rebuild',
  'cache',
  'parse',
  'segment',
  'style',
  'bold',
  'italic',
  'color',
  'entity',
  'escape',
  'unicode',
];

List<String> _plainCorpus(int count, int seed) {
  final rng = Random(seed);
  return [
    for (var i = 0; i < count; i++)
      [
        for (var w = 0; w < 14; w++) _kWords[rng.nextInt(_kWords.length)],
      ].join(' '),
  ];
}

String _describe(String input) {
  final buffered = StringBuffer();
  for (final codeUnit in input.codeUnits) {
    if (codeUnit >= 0x20 && codeUnit < 0x7f) {
      buffered.writeCharCode(codeUnit);
    } else {
      buffered.write('\\u${codeUnit.toRadixString(16).padLeft(4, '0')}');
    }
  }
  return buffered.toString();
}

void _expectSegmentsEqual(
  List<SubtitleTextSegment> actual,
  List<SubtitleTextSegment> expected,
  String input,
) {
  expect(
    actual.map((s) => (s.text, s.colorArgb, s.bold, s.italic, s.underline)),
    equals(
      expected.map((s) => (s.text, s.colorArgb, s.bold, s.italic, s.underline)),
    ),
    reason: 'segments differ for ${_describe(input)}',
  );
}

class _LegacyStyleFrame {
  const _LegacyStyleFrame({
    required this.colorArgb,
    required this.bold,
    required this.italic,
    required this.underline,
  });

  final int? colorArgb;
  final bool bold;
  final bool italic;
  final bool underline;

  _LegacyStyleFrame mergeWith({
    int? colorArgb,
    bool? bold,
    bool? italic,
    bool? underline,
  }) {
    return _LegacyStyleFrame(
      colorArgb: colorArgb ?? this.colorArgb,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
    );
  }
}

final Map<String, List<SubtitleTextSegment>> _legacyParseCache =
    <String, List<SubtitleTextSegment>>{};
const _maxLegacyParseCacheSize = 256;

String _legacyPlainForSelection(String raw) {
  final segments = _legacyParseSubtitleMarkup(raw);
  if (segments.isEmpty) {
    final plain = raw.replaceAll(tagStripRegExp, '').trim();
    return plain.isEmpty ? raw : plain;
  }
  return segments.map((s) => s.text).join();
}

List<SubtitleTextSegment> _legacyParseSubtitleMarkup(String input) {
  if (input.isEmpty) return const [];

  final cached = _legacyParseCache[input];
  if (cached != null) return cached;

  final out = <SubtitleTextSegment>[];
  final stack = <_LegacyStyleFrame>[
    const _LegacyStyleFrame(
      colorArgb: null,
      bold: false,
      italic: false,
      underline: false,
    ),
  ];

  final buf = StringBuffer();

  void flush() {
    if (buf.isEmpty) return;
    final raw = buf.toString();
    buf.clear();
    final top = stack.last;
    if (raw.isEmpty) return;
    out.add(
      SubtitleTextSegment(
        raw,
        colorArgb: top.colorArgb,
        bold: top.bold,
        italic: top.italic,
        underline: top.underline,
      ),
    );
  }

  var i = 0;
  while (i < input.length) {
    if (input[i] == '&') {
      final semi = input.indexOf(';', i);
      if (semi > i) {
        buf.write(_legacyDecodeEntityAt(input, i, semi));
        i = semi + 1;
        continue;
      }
      buf.write('&');
      i++;
      continue;
    }
    if (input[i] != '<') {
      buf.write(input[i]);
      i++;
      continue;
    }

    final close = input.indexOf('>', i);
    if (close == -1) {
      buf.write('<');
      i++;
      continue;
    }

    final tagRaw = input.substring(i + 1, close).trim();
    flush();
    i = close + 1;

    if (tagRaw.isEmpty) continue;

    final isClosing = tagRaw.startsWith('/');
    final tagInner = isClosing ? tagRaw.substring(1).trim() : tagRaw;
    final tagLower = tagInner.toLowerCase();
    final firstToken = tagLower.split(whitespaceSplitRegExp).first;

    if (!isClosing) {
      if (firstToken == 'br') {
        buf.write('\n');
        continue;
      }
      if (firstToken == 'font') {
        final color = _legacyExtractColorAttribute(tagInner);
        final p = stack.last;
        stack.add(
          _LegacyStyleFrame(
            colorArgb: color ?? p.colorArgb,
            bold: p.bold,
            italic: p.italic,
            underline: p.underline,
          ),
        );
        continue;
      }
      if (firstToken == 'b' || firstToken == 'strong') {
        final p = stack.last;
        stack.add(p.mergeWith(bold: true));
        continue;
      }
      if (firstToken == 'i' || firstToken == 'em') {
        final p = stack.last;
        stack.add(p.mergeWith(italic: true));
        continue;
      }
      if (firstToken == 'u') {
        final p = stack.last;
        stack.add(p.mergeWith(underline: true));
        continue;
      }
      continue;
    }

    if (firstToken == 'font' ||
        firstToken == 'b' ||
        firstToken == 'strong' ||
        firstToken == 'i' ||
        firstToken == 'em' ||
        firstToken == 'u') {
      if (stack.length > 1) stack.removeLast();
    }
  }

  flush();

  final result = _legacyMergeAdjacentSameStyle(out);
  if (_legacyParseCache.length >= _maxLegacyParseCacheSize) {
    _legacyParseCache.remove(_legacyParseCache.keys.first);
  }
  _legacyParseCache[input] = result;
  return result;
}

String _legacyDecodeEntityAt(String input, int start, int semi) {
  final entity = input.substring(start, semi + 1);
  switch (entity) {
    case '&amp;':
      return '&';
    case '&lt;':
      return '<';
    case '&gt;':
      return '>';
    case '&quot;':
      return '"';
    case '&apos;':
      return "'";
    default:
      if (entity.startsWith('&#x')) {
        final hex = entity.substring(3, entity.length - 1);
        final code = int.tryParse(hex, radix: 16);
        if (code != null) return String.fromCharCode(code);
      } else if (entity.startsWith('&#')) {
        final dec = entity.substring(2, entity.length - 1);
        final code = int.tryParse(dec);
        if (code != null) return String.fromCharCode(code);
      }
      return entity;
  }
}

final _legacyColorAttrRegExp = RegExp(
  r'''color\s*=\s*["']([^"']+)["']''',
  caseSensitive: false,
);

int? _legacyExtractColorAttribute(String tagInner) {
  final m = _legacyColorAttrRegExp.firstMatch(tagInner);
  if (m == null) return null;
  return parseSubtitleColorToArgb(m.group(1)!);
}

List<SubtitleTextSegment> _legacyMergeAdjacentSameStyle(
  List<SubtitleTextSegment> segments,
) {
  if (segments.isEmpty) return segments;
  final merged = <SubtitleTextSegment>[segments.first];
  for (var i = 1; i < segments.length; i++) {
    final prev = merged.last;
    final cur = segments[i];
    if (prev.colorArgb == cur.colorArgb &&
        prev.bold == cur.bold &&
        prev.italic == cur.italic &&
        prev.underline == cur.underline) {
      merged[merged.length - 1] = SubtitleTextSegment(
        prev.text + cur.text,
        colorArgb: prev.colorArgb,
        bold: prev.bold,
        italic: prev.italic,
        underline: prev.underline,
      );
    } else {
      merged.add(cur);
    }
  }
  return merged;
}
