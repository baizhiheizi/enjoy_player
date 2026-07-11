import 'dart:async';

import 'package:enjoy_player/features/shadow_reading/application/echo_pitch_analysis_service.dart';
import 'package:enjoy_player/features/shadow_reading/data/echo_segment_pcm_extractor.dart';
import 'package:enjoy_player/features/shadow_reading/domain/echo_region_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

EchoRegionAnalysisResult _result() => const EchoRegionAnalysisResult(
  points: [
    EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100, pitchUserHz: 90),
  ],
  durationSeconds: 1,
  sampleRate: 44100,
);

/// Fake [EchoPitchPipeline] that records every [EchoPcmCancelToken] it sees and
/// only completes a segment/file call when the test drives it (or when the
/// token is cancelled). This makes cancellation observable: a cancelled token
/// proves the in-flight FFmpeg process *would* have been killed.
class _RecordingPipeline implements EchoPitchPipeline {
  final List<EchoPcmCancelToken> segmentTokens = [];
  final List<EchoPcmCancelToken> fileTokens = [];
  final List<Completer<EchoRegionAnalysisResult>> segmentCompleters = [];
  final List<Completer<EchoRegionAnalysisResult>> fileCompleters = [];

  @override
  Future<EchoRegionAnalysisResult> analyzeSegment({
    required String mediaPath,
    required double startSec,
    required double endSec,
    EchoPcmCancelToken? token,
  }) {
    final c = Completer<EchoRegionAnalysisResult>();
    segmentCompleters.add(c);
    if (token != null) {
      segmentTokens.add(token);
      token.onCancel(() {
        if (!c.isCompleted) {
          c.completeError(
            const EchoPcmExtractionException(EchoPcmFailureReason.cancelled),
          );
        }
      });
    }
    return c.future;
  }

  @override
  Future<EchoRegionAnalysisResult> analyzeFile({
    required String mediaPath,
    EchoPcmCancelToken? token,
  }) {
    final c = Completer<EchoRegionAnalysisResult>();
    fileCompleters.add(c);
    if (token != null) {
      fileTokens.add(token);
      token.onCancel(() {
        if (!c.isCompleted) {
          c.completeError(
            const EchoPcmExtractionException(EchoPcmFailureReason.cancelled),
          );
        }
      });
    }
    return c.future;
  }
}

void main() {
  group('EchoPitchAnalysisService — cancellation', () {
    test('cancels (not just discards) the in-flight reference extraction when '
        'the region changes', () async {
      final pipeline = _RecordingPipeline();
      final svc = EchoPitchAnalysisService(pipeline: pipeline);

      final first = svc.analyzeReference(
        mediaPath: 'a.mp3',
        startSec: 0,
        endSec: 1,
      );
      // Let the pipeline register the first token.
      await Future<void>.delayed(Duration.zero);
      expect(pipeline.segmentTokens, hasLength(1));
      expect(pipeline.segmentTokens.first.isCancelled, isFalse);

      final second = svc.analyzeReference(
        mediaPath: 'a.mp3',
        startSec: 0,
        endSec: 2,
      );

      // The first request resolves to null (superseded) and its token was
      // genuinely cancelled — i.e. the FFmpeg process would be killed, not
      // merely have its result ignored.
      expect(await first, isNull);
      expect(pipeline.segmentTokens.first.isCancelled, isTrue);

      // Allow the second request to finish cleanly.
      pipeline.segmentCompleters.last.complete(_result());
      final secondResult = await second;
      expect(secondResult, isNotNull);
    });

    test(
      'cancels the in-flight user extraction when the recording changes',
      () async {
        final pipeline = _RecordingPipeline();
        final svc = EchoPitchAnalysisService(pipeline: pipeline);

        final first = svc.analyzeUser(mediaPath: 'rec1.wav');
        await Future<void>.delayed(Duration.zero);
        expect(pipeline.fileTokens, hasLength(1));

        final second = svc.analyzeUser(mediaPath: 'rec2.wav');

        expect(await first, isNull);
        expect(pipeline.fileTokens.first.isCancelled, isTrue);

        pipeline.fileCompleters.last.complete(_result());
        expect(await second, isNotNull);
      },
    );
  });

  group('EchoPitchAnalysisService — caching', () {
    test(
      'returns the cached reference result without re-running the pipeline',
      () async {
        final pipeline = _RecordingPipeline();
        final svc = EchoPitchAnalysisService(pipeline: pipeline);

        // First call runs the pipeline.
        final first = svc.analyzeReference(
          mediaPath: 'a.mp3',
          startSec: 1,
          endSec: 4,
        );
        await Future<void>.delayed(Duration.zero);
        pipeline.segmentCompleters.last.complete(_result());
        await first;

        // Second call with the same key must hit the cache (no new token).
        final second = await svc.analyzeReference(
          mediaPath: 'a.mp3',
          startSec: 1,
          endSec: 4,
        );
        expect(second, isNotNull);
        expect(pipeline.segmentTokens, hasLength(1));
      },
    );

    test('clearCache forces the next call to re-run', () async {
      final pipeline = _RecordingPipeline();
      final svc = EchoPitchAnalysisService(pipeline: pipeline);

      final first = svc.analyzeUser(mediaPath: 'rec.wav');
      await Future<void>.delayed(Duration.zero);
      pipeline.fileCompleters.last.complete(_result());
      await first;
      expect(pipeline.fileTokens, hasLength(1));

      svc.clearCache();

      final second = svc.analyzeUser(mediaPath: 'rec.wav');
      await Future<void>.delayed(Duration.zero);
      pipeline.fileCompleters.last.complete(_result());
      await second;
      expect(pipeline.fileTokens, hasLength(2));
    });
  });
}
