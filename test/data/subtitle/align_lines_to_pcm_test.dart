import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forced_alignment/forced_alignment.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/audio/pcm16k_mono.dart';
import 'package:enjoy_player/data/subtitle/align_lines_to_pcm.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';

const _lines = [
  TranscriptLine(text: 'Hello world', startMs: 0, durationMs: 700),
  TranscriptLine(text: 'Good night', startMs: 1200, durationMs: 800),
];

AlignmentSuccess _successFor(List<AlignmentSegment> segments) {
  return AlignmentSuccess(
    AlignmentResult(
      timeline: [
        for (final s in segments)
          TimelineEntry(
            type: TimelineEntryType.segment,
            text: s.text,
            startTime: s.startTime,
            endTime: s.endTime,
            id: s.id,
            timeline: [
              TimelineEntry(
                type: TimelineEntryType.word,
                text: s.text.split(' ').first,
                startTime: s.startTime,
                endTime: s.endTime,
              ),
            ],
          ),
      ],
      wordTimeline: const [],
      transcript: segments.map((s) => s.text).join(' '),
      language: 'en-US',
      durationSeconds: 2,
    ),
  );
}

Future<Float32List> _pcm() async => Float32List(kAlignmentSampleRate);

void main() {
  group('alignLinesToPcm', () {
    test('attaches the word spans onto the lines', () async {
      final outcome = await alignLinesToPcm(
        decodePcm: _pcm,
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async => _successFor(segments),
        log: logNamed('test.align'),
      );

      expect(outcome, isA<AlignLinesAttached>());
      final attached = (outcome as AlignLinesAttached).lines;
      expect(attached, hasLength(2));
      expect(attached.first.timeline, isNotEmpty);
      expect(attached.first.timeline!.first.text, 'Hello');
      expect(attached.last.timeline, isNotEmpty);
      expect(attached.last.timeline!.first.text, 'Good');
    });

    test('builds one segment per line, keyed by the line index', () async {
      List<AlignmentSegment>? seen;
      await alignLinesToPcm(
        decodePcm: _pcm,
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async {
              seen = segments;
              return _successFor(segments);
            },
        log: logNamed('test.align'),
      );

      expect(seen, hasLength(2));
      expect(seen!.map((s) => s.id), [0, 1]);
      expect(seen!.first.text, 'Hello world');
      expect(seen!.first.startTime, 0);
      expect(seen!.first.endTime, 0.7);
      expect(seen!.last.startTime, 1.2);
      expect(seen!.last.endTime, 2.0);
    });

    test('maps a decode failure onto AlignLinesUnavailable', () async {
      var aligned = false;
      final outcome = await alignLinesToPcm(
        decodePcm: () async => throw const Pcm16kDecodeException('boom'),
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async {
              aligned = true;
              return _successFor(segments);
            },
        log: logNamed('test.align'),
      );

      expect(outcome, isA<AlignLinesUnavailable>());
      expect(aligned, isFalse);
    });

    test('maps an empty PCM onto AlignLinesUnavailable', () async {
      final outcome = await alignLinesToPcm(
        decodePcm: () async => Float32List(0),
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async => _successFor(segments),
        log: logNamed('test.align'),
      );

      expect(outcome, isA<AlignLinesUnavailable>());
    });

    test('maps an alignment throw onto AlignLinesErrored', () async {
      final outcome = await alignLinesToPcm(
        decodePcm: _pcm,
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async => throw StateError('engine died'),
        log: logNamed('test.align'),
      );

      expect(outcome, isA<AlignLinesErrored>());
    });

    test(
      'maps an engine failure onto AlignLinesRejected with the reason name',
      () async {
        final outcome = await alignLinesToPcm(
          decodePcm: _pcm,
          language: 'en-US',
          lines: _lines,
          align:
              ({
                required sourcePcm16k,
                required language,
                required segments,
              }) async => const AlignmentFailed(
                AlignmentFailure(reason: AlignmentFailureReason.timedOut),
              ),
          log: logNamed('test.align'),
        );

        expect(outcome, isA<AlignLinesRejected>());
        expect(
          (outcome as AlignLinesRejected).reason,
          AlignmentFailureReason.timedOut.name,
        );
      },
    );

    test('a run cancelled before the alignment skips the align call', () async {
      var aligned = false;
      final token = AlignmentCancelToken()..cancel();
      final outcome = await alignLinesToPcm(
        decodePcm: _pcm,
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async {
              aligned = true;
              return _successFor(segments);
            },
        log: logNamed('test.align'),
        cancel: token,
      );

      expect(outcome, isA<AlignLinesCancelled>());
      expect(aligned, isFalse);
    });

    test('a run cancelled after the alignment discards the spans', () async {
      final token = AlignmentCancelToken();
      final outcome = await alignLinesToPcm(
        decodePcm: _pcm,
        language: 'en-US',
        lines: _lines,
        align:
            ({
              required sourcePcm16k,
              required language,
              required segments,
            }) async {
              token.cancel();
              return _successFor(segments);
            },
        log: logNamed('test.align'),
        cancel: token,
      );

      expect(outcome, isA<AlignLinesCancelled>());
    });
  });
}
