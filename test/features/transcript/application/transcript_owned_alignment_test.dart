import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forced_alignment/forced_alignment.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/application/transcript_enrichment_state.dart';
import 'package:enjoy_player/features/transcript/application/transcript_owned_alignment.dart';

import 'fake_enrichment_backend.dart';

const _shortClip = [
  TranscriptLine(text: 'Hello world', startMs: 0, durationMs: 700),
];

const _longClip = [
  TranscriptLine(text: 'Later', startMs: 91000, durationMs: 1000),
];

Float32List _pcm(String _) => Float32List(kAlignmentSampleRate);

AlignmentSuccess _segmentSuccess(List<AlignmentSegment> segments) {
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

void main() {
  test(
    'a clip within the whole-clip limit aligns in one whole-file pass',
    () async {
      final backend = FakeEnrichmentBackend()
        ..decodeFileFn = (path) async {
          return _pcm(path);
        }
        ..alignSegmentsFn =
            ({
              required sourcePcm16k,
              required language,
              required segments,
              cancel,
            }) async => _segmentSuccess(segments);

      final result = await alignOwnedMedia(
        backend: backend,
        lines: _shortClip,
        language: 'en-US',
        localPath: '/tmp/short.wav',
      );

      expect(result, isA<EnrichAttached>());
      expect(backend.decodeFileCalls, 1);
      expect(backend.decodeWindowCalls, 0);
      final attached = (result as EnrichAttached).lines;
      expect(attached.single.text, 'Hello world');
      expect(attached.single.timeline, isNotNull);
      expect(attached.single.timeline!.single.text, 'Hello');
    },
  );

  test('a clip past the whole-clip limit aligns per cue', () async {
    final backend = FakeEnrichmentBackend()
      ..decodeWindowFn =
          ({
            required pathOrUri,
            required startSeconds,
            required durationSeconds,
          }) async {
            return Float32List(kAlignmentSampleRate);
          }
      ..alignFn =
          ({
            required sourcePcm16k,
            required transcript,
            required language,
            cancel,
            required timeOffset,
          }) async => AlignmentSuccess(
            AlignmentResult(
              timeline: [
                TimelineEntry(
                  type: TimelineEntryType.segment,
                  text: transcript,
                  startTime: timeOffset,
                  endTime: timeOffset + 0.7,
                ),
              ],
              wordTimeline: const [],
              transcript: transcript,
              language: 'en-US',
              durationSeconds: 92,
            ),
          );

    final result = await alignOwnedMedia(
      backend: backend,
      lines: _longClip,
      language: 'en-US',
      localPath: '/tmp/long.wav',
    );

    expect(result, isA<EnrichAttached>());
    expect(backend.decodeFileCalls, 0);
    expect(backend.decodeWindowCalls, 1);
    expect(backend.alignCalls, 1);
    expect((result as EnrichAttached).lines.single.text, 'Later');
  });

  test(
    'the windowed path keeps a cue the engine returned no segment for',
    () async {
      final backend = FakeEnrichmentBackend()
        ..decodeWindowFn =
            ({
              required pathOrUri,
              required startSeconds,
              required durationSeconds,
            }) async {
              return Float32List(kAlignmentSampleRate);
            }
        ..alignFn =
            ({
              required sourcePcm16k,
              required transcript,
              required language,
              cancel,
              required timeOffset,
            }) async => AlignmentSuccess(
              AlignmentResult(
                timeline: const [],
                wordTimeline: [
                  TimelineEntry(
                    type: TimelineEntryType.word,
                    text: 'Later',
                    startTime: timeOffset,
                    endTime: timeOffset + 0.5,
                  ),
                ],
                transcript: 'Later',
                language: 'en-US',
                durationSeconds: 92,
              ),
            );

      final result = await alignOwnedMedia(
        backend: backend,
        lines: _longClip,
        language: 'en-US',
        localPath: '/tmp/long.wav',
      );

      expect(result, isA<EnrichAttached>());
      final line = (result as EnrichAttached).lines.single;
      expect(line.text, 'Later');
      expect(line.startMs, 91000);
      expect(line.durationMs, 1000);
      expect(line.timeline, isNotNull);
      expect(line.timeline!.single.text, 'Later');
    },
  );

  test('the windowed path rejects when no cue produced a segment', () async {
    final backend = FakeEnrichmentBackend()
      ..decodeWindowFn =
          ({
            required pathOrUri,
            required startSeconds,
            required durationSeconds,
          }) async {
            return Float32List(kAlignmentSampleRate);
          }
      ..alignFn =
          ({
            required sourcePcm16k,
            required transcript,
            required language,
            cancel,
            required timeOffset,
          }) async => const AlignmentFailed(
            AlignmentFailure(
              reason: AlignmentFailureReason.internal,
              message: 'no alignment',
            ),
          );

    final result = await alignOwnedMedia(
      backend: backend,
      lines: _longClip,
      language: 'en-US',
      localPath: '/tmp/long.wav',
    );

    expect(result, isA<EnrichRejected>());
    expect((result as EnrichRejected).reason, 'internal');
  });
}
