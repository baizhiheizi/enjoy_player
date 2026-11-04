import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart' hide collapseWhitespace;

import 'package:enjoy_player/core/utils/text_normalization.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/domain/asr_timeline_builder.dart';

const int _kFuzzCases = 300;
const int _kWordCount = 18000;
const int _kSegmentCount = 3000;
const int _kPlainTextChars = 120000;
const int _kWarmupPasses = 5;
const int _kSamplesPerRound = 10;
const int _kRounds = 3;

const _legacySentenceTerminators = <String>{'.', '?', '!', '。', '？', '！'};

bool _legacyEndsWithTerminator(String s) {
  if (s.isEmpty) return false;
  final last = s.substring(s.length - 1);
  return _legacySentenceTerminators.contains(last);
}

String _legacyWordText(String s) {
  return s.startsWith(' ') ? s.substring(1) : s;
}

class _LegacyWord {
  _LegacyWord({required this.text, required this.startMs, required this.endMs});
  final String text;
  final int startMs;
  final int endMs;
}

class _LegacyLine {
  _LegacyLine({required this.words});
  final List<_LegacyWord> words;
  String get text => words.map((w) => w.text).join(' ');
}

TranscriptLine _legacyLineToTranscriptLine(_LegacyLine line) {
  final startMs = line.words.first.startMs;
  final endMs = line.words.last.endMs;
  final durationMs = (endMs - startMs).clamp(0, 1 << 31);
  final text = line.text.trimRight();
  return TranscriptLine(text: text, startMs: startMs, durationMs: durationMs);
}

List<TranscriptLine> _legacyBuildAsrTranscriptLines({
  required AsrResult result,
  required int mediaDurationMs,
  int maxLineDurationMs = 6000,
  int maxLineChars = 140,
  int pauseThresholdMs = 350,
}) {
  if (result.text.trim().isEmpty &&
      (result.segments == null || result.segments!.isEmpty)) {
    return const <TranscriptLine>[];
  }

  final segments = result.segments;
  if (segments != null && segments.isNotEmpty) {
    final firstWithWords = segments
        .where((s) => s.words != null && s.words!.isNotEmpty)
        .firstOrNull;
    if (firstWithWords != null) {
      return _legacyGroupFromWords(
        segments: segments,
        maxLineDurationMs: maxLineDurationMs,
        maxLineChars: maxLineChars,
        pauseThresholdMs: pauseThresholdMs,
      );
    }
    return _legacyGroupFromSegments(
      segments: segments,
      maxLineDurationMs: maxLineDurationMs,
      maxLineChars: maxLineChars,
    );
  }

  return _legacyDistributePlainText(
    text: result.text,
    mediaDurationMs: mediaDurationMs,
    maxLineChars: maxLineChars,
  );
}

List<TranscriptLine> _legacyGroupFromWords({
  required List<AsrSegment> segments,
  required int maxLineDurationMs,
  required int maxLineChars,
  required int pauseThresholdMs,
}) {
  final words = <_LegacyWord>[];
  for (final seg in segments) {
    final ws = seg.words;
    if (ws == null) continue;
    for (final w in ws) {
      if (w.word.trim().isEmpty) continue;
      words.add(
        _LegacyWord(
          text: _legacyWordText(w.word),
          startMs: (w.start * 1000).round(),
          endMs: (w.end * 1000).round(),
        ),
      );
    }
  }
  if (words.isEmpty) return const <TranscriptLine>[];

  final lines = <_LegacyLine>[];
  var current = _LegacyLine(words: <_LegacyWord>[words.first]);
  for (var i = 1; i < words.length; i++) {
    final next = words[i];
    final gap = next.startMs - current.words.last.endMs;
    final wouldText = '${current.text} ${next.text}';
    final wouldDuration = next.endMs - current.words.first.startMs;

    final shouldBreak =
        _legacyEndsWithTerminator(current.text) ||
        gap > pauseThresholdMs ||
        wouldDuration > maxLineDurationMs ||
        wouldText.length > maxLineChars;

    if (shouldBreak && current.words.isNotEmpty) {
      lines.add(current);
      current = _LegacyLine(words: <_LegacyWord>[next]);
    } else {
      current.words.add(next);
    }
  }
  if (current.words.isNotEmpty) lines.add(current);

  return lines.map(_legacyLineToTranscriptLine).toList(growable: false);
}

List<TranscriptLine> _legacyGroupFromSegments({
  required List<AsrSegment> segments,
  required int maxLineDurationMs,
  required int maxLineChars,
}) {
  final lines = <_LegacyLine>[];
  _LegacyLine? current;
  for (final seg in segments) {
    final startMs = (seg.start * 1000).round();
    final endMs = (seg.end * 1000).round();
    final segText = seg.text.trim();
    if (segText.isEmpty) continue;

    if (current == null) {
      current = _LegacyLine(
        words: <_LegacyWord>[
          _LegacyWord(text: segText, startMs: startMs, endMs: endMs),
        ],
      );
      continue;
    }

    final candidate = _LegacyLine(
      words: <_LegacyWord>[
        ...current.words,
        _LegacyWord(text: segText, startMs: startMs, endMs: endMs),
      ],
    );
    final candidateDuration =
        candidate.words.last.endMs - candidate.words.first.startMs;
    final candidateText = candidate.text;

    final shouldBreak =
        _legacyEndsWithTerminator(current.text) ||
        candidateDuration >= maxLineDurationMs ||
        candidateText.length > maxLineChars;

    if (shouldBreak) {
      lines.add(current);
      current = _LegacyLine(
        words: <_LegacyWord>[
          _LegacyWord(text: segText, startMs: startMs, endMs: endMs),
        ],
      );
    } else {
      current = candidate;
    }
  }
  if (current != null) lines.add(current);

  return lines.map(_legacyLineToTranscriptLine).toList(growable: false);
}

List<TranscriptLine> _legacyDistributePlainText({
  required String text,
  required int mediaDurationMs,
  required int maxLineChars,
}) {
  final raw = collapseWhitespace(text);
  if (raw.isEmpty) return const <TranscriptLine>[];
  if (mediaDurationMs <= 0) {
    return <TranscriptLine>[
      TranscriptLine(text: raw, startMs: 0, durationMs: 0),
    ];
  }

  final chunks = <String>[];
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    buf.write(ch);
    if (_legacySentenceTerminators.contains(ch) || buf.length >= maxLineChars) {
      chunks.add(buf.toString().trim());
      buf.clear();
    }
  }
  if (buf.isNotEmpty) chunks.add(buf.toString().trim());
  if (chunks.isEmpty) return const <TranscriptLine>[];

  final perChunk = mediaDurationMs ~/ chunks.length;
  final out = <TranscriptLine>[];
  for (var i = 0; i < chunks.length; i++) {
    final t = chunks[i];
    if (t.isEmpty) continue;
    final startMs = perChunk * i;
    final isLast = i == chunks.length - 1;
    final durationMs = isLast
        ? (mediaDurationMs - startMs).clamp(0, mediaDurationMs)
        : perChunk;
    out.add(TranscriptLine(text: t, startMs: startMs, durationMs: durationMs));
  }
  return out;
}

AsrResult _wordResult({
  required int count,
  int seed = 7,
  double pauseRate = 0.05,
  double terminatorRate = 0.08,
}) {
  final rnd = math.Random(seed);
  const pieces = [
    'Hello',
    ' world',
    'this',
    ' is',
    'a',
    ' longer',
    'sequence',
    'of',
    ' spoken',
    'words',
  ];
  const terminators = ['.', '?', '!', '。', '？'];
  final words = <AsrWord>[];
  var t = 0.0;
  for (var i = 0; i < count; i++) {
    var w = pieces[rnd.nextInt(pieces.length)];
    if (rnd.nextDouble() < terminatorRate) {
      w = w + terminators[rnd.nextInt(terminators.length)];
    }
    final duration = 0.2 + rnd.nextDouble() * 0.4;
    words.add(AsrWord(word: w, start: t, end: t + duration));
    t += duration + (rnd.nextDouble() < pauseRate ? 0.5 : 0.05);
  }
  return AsrResult(
    text: words.map((w) => w.word).join(),
    segments: [
      AsrSegment(
        start: 0,
        end: t,
        text: words.map((w) => w.word).join(),
        words: words,
      ),
    ],
  );
}

AsrResult _segmentResult({required int count, int seed = 11}) {
  final rnd = math.Random(seed);
  const pieces = [
    'First part of a sentence',
    'second fragment continues',
    'and here it ends.',
    'A short one',
    '另一段中文片段。',
    'mixed 语言 content',
  ];
  final segments = <AsrSegment>[];
  var t = 0.0;
  for (var i = 0; i < count; i++) {
    final text = pieces[rnd.nextInt(pieces.length)];
    final duration = 0.3 + rnd.nextDouble() * 2.0;
    segments.add(
      AsrSegment(start: t, end: t + duration, text: text, words: null),
    );
    t += duration + 0.1;
  }
  return AsrResult(
    text: segments.map((s) => s.text).join(' '),
    segments: segments,
  );
}

AsrResult _plainTextResult({required int chars, int seed = 13}) {
  final rnd = math.Random(seed);
  const units = [
    'Some words here. ',
    '中文句子。还有更多。',
    'A question? Yes! ',
    'line\nbreak and\ttabs ',
    'no terminator runs on ',
  ];
  final buf = StringBuffer();
  while (buf.length < chars) {
    buf.write(units[rnd.nextInt(units.length)]);
  }
  return AsrResult(text: buf.toString(), segments: null);
}

void _expectSameLines({
  required AsrResult result,
  required int mediaDurationMs,
  required int maxLineChars,
  required int maxLineDurationMs,
  required int pauseThresholdMs,
  required String reason,
}) {
  final got = buildAsrTranscriptLines(
    result: result,
    mediaDurationMs: mediaDurationMs,
    maxLineDurationMs: maxLineDurationMs,
    maxLineChars: maxLineChars,
    pauseThresholdMs: pauseThresholdMs,
  );
  final legacy = _legacyBuildAsrTranscriptLines(
    result: result,
    mediaDurationMs: mediaDurationMs,
    maxLineDurationMs: maxLineDurationMs,
    maxLineChars: maxLineChars,
    pauseThresholdMs: pauseThresholdMs,
  );
  expect(got.length, legacy.length, reason: 'line count mismatch: $reason');
  for (var i = 0; i < got.length; i++) {
    expect(got[i], legacy[i], reason: 'line $i mismatch: $reason');
  }
}

AsrResult _fuzzResult(math.Random rnd) {
  final shape = rnd.nextInt(3);
  const alphabet = ['a', 'b word', '中', '文', 'x', ' 𝄞', 'e', ' tail ', '！'];
  const terminators = ['.', '。', '?', '！'];
  String textToken() {
    var t = alphabet[rnd.nextInt(alphabet.length)];
    if (rnd.nextDouble() < 0.2) {
      t += terminators[rnd.nextInt(terminators.length)];
    }
    return t;
  }

  switch (shape) {
    case 0:
      final n = rnd.nextInt(60);
      final words = <AsrWord>[];
      var t = rnd.nextDouble() * 10;
      for (var i = 0; i < n; i++) {
        final duration = rnd.nextDouble() * 1.2;
        words.add(AsrWord(word: textToken(), start: t, end: t + duration));
        t += duration + (rnd.nextDouble() < 0.25 ? 0.4 : 0.01);
      }
      return AsrResult(
        text: '',
        segments: [AsrSegment(start: 0, end: t, text: 'ignored', words: words)],
      );
    case 1:
      final n = rnd.nextInt(40);
      final segments = <AsrSegment>[];
      var t = rnd.nextDouble() * 5;
      for (var i = 0; i < n; i++) {
        final duration = rnd.nextDouble() * 7;
        segments.add(
          AsrSegment(
            start: t,
            end: t + duration,
            text: textToken() + (rnd.nextBool() ? '  ' : ''),
            words: rnd.nextDouble() < 0.05
                ? [AsrWord(word: '', start: t, end: t)]
                : null,
          ),
        );
        t += duration;
      }
      return AsrResult(text: '', segments: segments);
    default:
      final n = 1 + rnd.nextInt(40);
      final buf = StringBuffer();
      for (var i = 0; i < n; i++) {
        buf
          ..write(textToken())
          ..write(rnd.nextBool() ? ' ' : '\n');
      }
      return AsrResult(text: buf.toString(), segments: null);
  }
}

void main() {
  test(
    'incremental grouping matches the legacy derivation over curated cases',
    () {
      final cases = <AsrResult>[
        const AsrResult(text: '', segments: null),
        const AsrResult(text: '   \n ', segments: null),
        const AsrResult(text: '', segments: []),
        _wordResult(count: 1),
        _wordResult(count: 2),
        _wordResult(count: 2, pauseRate: 1),
        _wordResult(count: 40, terminatorRate: 1),
        _wordResult(count: 200, seed: 91),
        _segmentResult(count: 1),
        _segmentResult(count: 30, seed: 92),
        _plainTextResult(chars: 500),
        _plainTextResult(chars: 1000, seed: 93),
        const AsrResult(
          text: '',
          segments: [
            AsrSegment(
              start: 0,
              end: 1,
              text: 'only whitespace words',
              words: [
                AsrWord(word: '  ', start: 0, end: 0.5),
                AsrWord(word: ' ', start: 0.5, end: 1),
              ],
            ),
          ],
        ),
        const AsrResult(
          text: '',
          segments: [
            AsrSegment(
              start: 0,
              end: 1,
              text: 'separator arithmetic',
              words: [
                AsrWord(word: 'ab', start: 0.0, end: 0.1),
                AsrWord(word: 'c', start: 0.1, end: 0.2),
                AsrWord(word: 'de', start: 0.2, end: 0.3),
              ],
            ),
          ],
        ),
        const AsrResult(
          text: '',
          segments: [
            AsrSegment(
              start: 0,
              end: 1,
              text: 'astral',
              words: [
                AsrWord(word: '𝄞𝄫', start: 0.0, end: 0.3),
                AsrWord(word: 'next', start: 0.3, end: 0.6),
              ],
            ),
          ],
        ),
        const AsrResult(
          text: '',
          segments: [
            AsrSegment(
              start: 0,
              end: 1,
              text: 'gap boundary',
              words: [
                AsrWord(word: 'a', start: 0.0, end: 0.1),
                AsrWord(word: 'b', start: 0.45, end: 0.55),
                AsrWord(word: 'c', start: 0.901, end: 1.0),
              ],
            ),
          ],
        ),
        const AsrResult(
          text: '',
          segments: [
            AsrSegment(
              start: 0,
              end: 2,
              text: 'duration boundary',
              words: [
                AsrWord(word: 'a', start: 0.0, end: 0.1),
                AsrWord(word: 'b', start: 0.1, end: 6.0),
                AsrWord(word: 'c', start: 6.0, end: 12.0),
              ],
            ),
          ],
        ),
        const AsrResult(
          text: '',
          segments: [
            AsrSegment(
              start: 0,
              end: 2,
              text: 'empty segment interleaved',
              words: [
                AsrWord(word: 'a.', start: 0.0, end: 0.1),
                AsrWord(word: 'b', start: 0.1, end: 0.2),
              ],
            ),
            AsrSegment(start: 2, end: 3, text: '   ', words: null),
            AsrSegment(start: 3, end: 4, text: 'c', words: null),
          ],
        ),
      ];

      const paramVariants = [
        (140, 6000, 350),
        (1, 6000, 350),
        (7, 6000, 350),
        (140, 100, 350),
        (140, 6000, 0),
        (5, 400, 400),
      ];
      for (final result in cases) {
        for (final (maxChars, maxDur, pause) in paramVariants) {
          _expectSameLines(
            result: result,
            mediaDurationMs: 10000,
            maxLineChars: maxChars,
            maxLineDurationMs: maxDur,
            pauseThresholdMs: pause,
            reason:
                'params(maxChars=$maxChars,maxDur=$maxDur,pause=$pause), '
                'segments=${result.segments?.length ?? 0}',
          );
        }
      }
    },
  );

  test(
    'incremental grouping matches the legacy derivation over fuzz cases',
    () {
      for (var seed = 0; seed < _kFuzzCases; seed++) {
        final rnd = math.Random(seed * 17 + 3);
        final result = _fuzzResult(rnd);
        final maxChars = 1 + rnd.nextInt(200);
        final maxDur = 100 + rnd.nextInt(9000);
        final pause = rnd.nextInt(1000);
        final got = buildAsrTranscriptLines(
          result: result,
          mediaDurationMs: 9000,
          maxLineDurationMs: maxDur,
          maxLineChars: maxChars,
          pauseThresholdMs: pause,
        );
        final legacy = _legacyBuildAsrTranscriptLines(
          result: result,
          mediaDurationMs: 9000,
          maxLineDurationMs: maxDur,
          maxLineChars: maxChars,
          pauseThresholdMs: pause,
        );
        expect(got, legacy, reason: 'fuzz mismatch (seed $seed)');
      }
    },
  );

  test('word-path build stays under the loose ceiling (local only)', () {
    final legacy =
        (Platform.environment['ASR_TIMELINE_BENCH_MODE'] ?? '') == 'legacy';
    final result = _wordResult(count: _kWordCount);

    int runPass() {
      final lines = legacy
          ? _legacyBuildAsrTranscriptLines(
              result: result,
              mediaDurationMs: 7200000,
            )
          : buildAsrTranscriptLines(result: result, mediaDurationMs: 7200000);
      var sink = 0;
      for (final l in lines) {
        sink += l.text.length;
      }
      return sink;
    }

    final warm = runPass();
    for (var pass = 0; pass < _kWarmupPasses; pass++) {
      runPass();
    }
    final rounds = <double>[];
    for (var round = 0; round < _kRounds; round++) {
      final samples = <double>[];
      for (var sample = 0; sample < _kSamplesPerRound; sample++) {
        final sw = Stopwatch()..start();
        final sink = runPass();
        sw.stop();
        expect(sink, warm);
        samples.add(sw.elapsedMicroseconds / 1000);
      }
      samples.sort();
      rounds.add(samples[samples.length ~/ 2]);
    }
    // ignore: avoid_print
    print(
      'asr-timeline word-path (${legacy ? 'legacy' : 'incremental'}): '
      '${rounds.map((m) => m.toStringAsFixed(2)).join(' / ')} ms per build '
      '($_kWordCount words, sink=$warm)',
    );
    expect(rounds[rounds.length ~/ 2], lessThan(2000));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('segment-path build stays under the loose ceiling (local only)', () {
    final legacy =
        (Platform.environment['ASR_TIMELINE_BENCH_MODE'] ?? '') == 'legacy';
    final result = _segmentResult(count: _kSegmentCount);

    int runPass() {
      final lines = legacy
          ? _legacyBuildAsrTranscriptLines(
              result: result,
              mediaDurationMs: 7200000,
            )
          : buildAsrTranscriptLines(result: result, mediaDurationMs: 7200000);
      var sink = 0;
      for (final l in lines) {
        sink += l.text.length;
      }
      return sink;
    }

    final warm = runPass();
    for (var pass = 0; pass < _kWarmupPasses; pass++) {
      runPass();
    }
    final rounds = <double>[];
    for (var round = 0; round < _kRounds; round++) {
      final samples = <double>[];
      for (var sample = 0; sample < _kSamplesPerRound; sample++) {
        final sw = Stopwatch()..start();
        final sink = runPass();
        sw.stop();
        expect(sink, warm);
        samples.add(sw.elapsedMicroseconds / 1000);
      }
      samples.sort();
      rounds.add(samples[samples.length ~/ 2]);
    }
    // ignore: avoid_print
    print(
      'asr-timeline segment-path (${legacy ? 'legacy' : 'incremental'}): '
      '${rounds.map((m) => m.toStringAsFixed(2)).join(' / ')} ms per build '
      '($_kSegmentCount segments, sink=$warm)',
    );
    expect(rounds[rounds.length ~/ 2], lessThan(2000));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('plain-text build stays under the loose ceiling (local only)', () {
    final legacy =
        (Platform.environment['ASR_TIMELINE_BENCH_MODE'] ?? '') == 'legacy';
    final result = _plainTextResult(chars: _kPlainTextChars);

    int runPass() {
      final lines = legacy
          ? _legacyBuildAsrTranscriptLines(
              result: result,
              mediaDurationMs: 7200000,
            )
          : buildAsrTranscriptLines(result: result, mediaDurationMs: 7200000);
      var sink = 0;
      for (final l in lines) {
        sink += l.text.length;
      }
      return sink;
    }

    final warm = runPass();
    for (var pass = 0; pass < _kWarmupPasses; pass++) {
      runPass();
    }
    final rounds = <double>[];
    for (var round = 0; round < _kRounds; round++) {
      final samples = <double>[];
      for (var sample = 0; sample < _kSamplesPerRound; sample++) {
        final sw = Stopwatch()..start();
        final sink = runPass();
        sw.stop();
        expect(sink, warm);
        samples.add(sw.elapsedMicroseconds / 1000);
      }
      samples.sort();
      rounds.add(samples[samples.length ~/ 2]);
    }
    // ignore: avoid_print
    print(
      'asr-timeline plain-text (${legacy ? 'legacy' : 'incremental'}): '
      '${rounds.map((m) => m.toStringAsFixed(2)).join(' / ')} ms per build '
      '($_kPlainTextChars chars, sink=$warm)',
    );
    expect(rounds[rounds.length ~/ 2], lessThan(2000));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
