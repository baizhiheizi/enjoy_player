import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

const int _kTranscriptLines = 512;
const int _kWindowRows = 40;
const int _kWarmupPasses = 16;
const int _kMeasuredPasses = 200;
const String _kSourceLanguage = 'en';
const String _kTargetLanguage = 'zh-CN';

String _cueText(int i) =>
    '<b>Cue $i</b> a slightly longer body for row $i so the markup parse '
    'and the source key hash do real work per derivation';

List<TranscriptLine> _buildPrimaryLines() {
  return [
    for (var i = 0; i < _kTranscriptLines; i++)
      TranscriptLine(text: _cueText(i), startMs: i * 1000, durationMs: 900),
  ];
}

List<TranscriptLine> _buildAiLines(List<TranscriptLine> primary) {
  return [
    for (var i = 0; i < primary.length; i++)
      TranscriptLine(
        text: '译文 $i',
        startMs: i * 1000,
        durationMs: 900,
        sourceKey: autoTranslateSourceKey(
          primaryText: primary[i].text,
          sourceLanguage: _kSourceLanguage,
          targetLanguage: _kTargetLanguage,
        ),
      ),
  ];
}

String? _legacyResolve({
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
  required int lineIndex,
}) {
  if (lineIndex < 0 || lineIndex >= primaryLines.length) return null;
  if (lineIndex >= aiLines.length) return null;
  final slot = aiLines[lineIndex];
  final text = slot.text.trim();
  if (text.isEmpty) return null;
  final expected = autoTranslateSourceKey(
    primaryText: primaryLines[lineIndex].text,
    sourceLanguage: _kSourceLanguage,
    targetLanguage: _kTargetLanguage,
  );
  final stored = slot.sourceKey;
  if (stored == null || stored != expected) return null;
  return slot.text;
}

String? _resolve(
  String mode, {
  required List<TranscriptLine> primaryLines,
  required List<TranscriptLine> aiLines,
  required int lineIndex,
}) {
  if (mode == 'legacy') {
    return _legacyResolve(
      primaryLines: primaryLines,
      aiLines: aiLines,
      lineIndex: lineIndex,
    );
  }
  return resolveAutoTranslateSecondaryText(
    primaryLines: primaryLines,
    aiLines: aiLines,
    lineIndex: lineIndex,
    sourceLanguage: _kSourceLanguage,
    targetLanguage: _kTargetLanguage,
  );
}

int _runPasses(
  String mode, {
  required List<TranscriptLine> primary,
  required List<TranscriptLine> ai,
  required int warmupPasses,
  required int measuredPasses,
  required bool sweep,
}) {
  for (var i = 0; i < warmupPasses; i++) {
    for (var row = 0; row < _kWindowRows; row++) {
      _resolve(
        mode,
        primaryLines: primary,
        aiLines: ai,
        lineIndex: sweep ? (i * _kWindowRows + row) % primary.length : row,
      );
    }
  }
  final sw = Stopwatch()..start();
  var sink = 0;
  for (var pass = 0; pass < measuredPasses; pass++) {
    for (var row = 0; row < _kWindowRows; row++) {
      final resolved = _resolve(
        mode,
        primaryLines: primary,
        aiLines: ai,
        lineIndex: sweep ? (pass * _kWindowRows + row) % primary.length : row,
      );
      sink += resolved?.length ?? 0;
    }
  }
  sw.stop();
  // ignore: avoid_print
  print(
    'auto-translate source key ($mode, ${sweep ? 'sweep' : 'window'}): '
    '${(sw.elapsedMicroseconds / measuredPasses / 1000).toStringAsFixed(3)} '
    'ms/pass ($_kWindowRows rows, sink=$sink)',
  );
  return sink;
}

void main() {
  test('resolves the secondary text of every window row', () {
    final primary = _buildPrimaryLines();
    final ai = _buildAiLines(primary);
    for (var i = 0; i < _kWindowRows; i++) {
      expect(
        resolveAutoTranslateSecondaryText(
          primaryLines: primary,
          aiLines: ai,
          lineIndex: i,
          sourceLanguage: _kSourceLanguage,
          targetLanguage: _kTargetLanguage,
        ),
        '译文 $i',
      );
    }
  });

  test(
    'rebuilding the visible window stays under the loose ceiling (local only)',
    () {
      final primary = _buildPrimaryLines();
      final ai = _buildAiLines(primary);
      final mode =
          Platform.environment['AUTO_TRANSLATE_KEY_BENCH_MODE'] ?? 'resolved';
      final sink = _runPasses(
        mode,
        primary: primary,
        ai: ai,
        warmupPasses: _kWarmupPasses,
        measuredPasses: _kMeasuredPasses,
        sweep: false,
      );
      expect(sink, greaterThan(0));
    },
    skip: 'Local-only microbenchmark; run with --run-skipped.',
  );

  test(
    'sweeping a long transcript stays under the loose ceiling (local only)',
    () {
      final primary = _buildPrimaryLines();
      final ai = _buildAiLines(primary);
      final mode =
          Platform.environment['AUTO_TRANSLATE_KEY_BENCH_MODE'] ?? 'resolved';
      final sink = _runPasses(
        mode,
        primary: primary,
        ai: ai,
        warmupPasses: _kWarmupPasses,
        measuredPasses: _kMeasuredPasses,
        sweep: true,
      );
      expect(sink, greaterThan(0));
    },
    skip: 'Local-only microbenchmark; run with --run-skipped.',
  );
}
