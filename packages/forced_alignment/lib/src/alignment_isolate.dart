import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'alignment_pipeline.dart';
import 'cue_window.dart';
import 'failures.dart';
import 'request.dart';
import 'synth/spoken_reference.dart';
import 'types.dart';

final _log = Logger('forced_alignment');

final class IsolateTimeout implements Exception {
  const IsolateTimeout();
}

final class IsolateCancelled implements Exception {
  const IsolateCancelled();
}

final class AlignIsolateJob {
  const AlignIsolateJob({
    required this.sourcePcm,
    required this.transcript,
    required this.language,
    this.timeOffset = 0,
    this.reference,
  });

  final Float32List sourcePcm;
  final String transcript;
  final String language;
  final double timeOffset;

  /// Prebuilt spoken reference. Production synth runs on [EspeakSynthHost]
  /// before this job; DTW isolates must not call eSpeak-NG.
  final ReferenceAudio? reference;
}

final class AlignCueSpec {
  const AlignCueSpec({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.startSample,
    required this.endSample,
    required this.transcript,
    required this.reference,
  });

  final Object? id;
  final double startTime;
  final double endTime;
  final int startSample;
  final int endSample;
  final String transcript;
  final ReferenceAudio? reference;
}

final class AlignSegmentsIsolateJob {
  const AlignSegmentsIsolateJob({
    required this.sourcePcm,
    required this.language,
    required this.cues,
  });

  final Float32List sourcePcm;
  final String language;
  final List<AlignCueSpec> cues;
}

final class AlignSegmentsIsolateResult {
  const AlignSegmentsIsolateResult({
    required this.timeline,
    this.lastCueFailure,
    this.criticalFailure,
  });

  final List<TimelineEntry> timeline;
  final AlignmentFailureReason? lastCueFailure;
  final AlignmentFailure? criticalFailure;
}

bool _isCriticalCueFailure(AlignmentFailureReason reason) =>
    reason == AlignmentFailureReason.cancelled ||
    reason == AlignmentFailureReason.timedOut ||
    reason == AlignmentFailureReason.unsupportedLanguage ||
    reason == AlignmentFailureReason.audioUnavailable ||
    reason == AlignmentFailureReason.spokenReferenceUnavailable;

/// DSP entry used by [Isolate.spawn]. Top-level so it is sendable.
void _alignIsolateMain(_AlignIsolateBox box) {
  final cancelIn = ReceivePort();
  cancelIn.listen((_) {});
  box.reply.send(cancelIn.sendPort);
  try {
    final job = box.job;
    final result = runAlignPipeline(
      sourcePcm: job.sourcePcm,
      transcript: job.transcript,
      language: job.language,
      timeOffset: job.timeOffset,
      reference: job.reference,
    );
    box.reply.send(result);
  } catch (e, st) {
    _log.warning('alignment isolate failed', e, st);
    box.reply.send(
      AlignmentFailure(
        reason: AlignmentFailureReason.internal,
        message: e.toString(),
      ),
    );
  } finally {
    cancelIn.close();
  }
}

void _alignSegmentsIsolateMain(_AlignSegmentsIsolateBox box) {
  final cancelIn = ReceivePort();
  var cancelled = false;
  cancelIn.listen((_) {
    cancelled = true;
  });
  box.reply.send(cancelIn.sendPort);
  try {
    final job = box.job;
    final successes = <TimelineEntry>[];
    AlignmentFailureReason? lastCueFailure;
    for (final cue in job.cues) {
      if (cancelled) {
        box.reply.send(
          const AlignSegmentsIsolateResult(
            timeline: [],
            criticalFailure: AlignmentFailure(
              reason: AlignmentFailureReason.cancelled,
            ),
          ),
        );
        return;
      }
      final slice = Float32List.sublistView(
        job.sourcePcm,
        cue.startSample,
        cue.endSample,
      );
      final outcome = runAlignPipeline(
        sourcePcm: slice,
        transcript: cue.transcript,
        language: job.language,
        timeOffset: cue.startTime,
        reference: cue.reference,
      );
      if (outcome is AlignmentResult) {
        for (final entry in outcome.timeline) {
          successes.add(
            withSegmentId(
              clampTimelineToCueWindow(
                entry,
                startTime: cue.startTime,
                endTime: cue.endTime,
              ),
              cue.id,
            ),
          );
        }
      } else if (outcome is AlignmentFailure) {
        if (_isCriticalCueFailure(outcome.reason)) {
          box.reply.send(
            AlignSegmentsIsolateResult(
              timeline: const [],
              criticalFailure: outcome,
            ),
          );
          return;
        }
        lastCueFailure = outcome.reason;
      }
    }
    box.reply.send(
      AlignSegmentsIsolateResult(
        timeline: successes,
        lastCueFailure: lastCueFailure,
      ),
    );
  } catch (e, st) {
    _log.warning('alignment segments isolate failed', e, st);
    box.reply.send(
      AlignSegmentsIsolateResult(
        timeline: const [],
        criticalFailure: AlignmentFailure(
          reason: AlignmentFailureReason.internal,
          message: e.toString(),
        ),
      ),
    );
  } finally {
    cancelIn.close();
  }
}

final class _AlignIsolateBox {
  const _AlignIsolateBox(this.reply, this.job);

  final SendPort reply;
  final AlignIsolateJob job;
}

final class _AlignSegmentsIsolateBox {
  const _AlignSegmentsIsolateBox(this.reply, this.job);

  final SendPort reply;
  final AlignSegmentsIsolateJob job;
}

Future<Object> _spawnWithCancel<T>({
  required void Function(T) entry,
  required T Function(SendPort reply) buildMessage,
  required String debugName,
  AlignmentCancelToken? cancel,
  required Duration timeout,
}) async {
  if (cancel?.isCancelled ?? false) {
    throw const IsolateCancelled();
  }
  final receive = ReceivePort();
  late Isolate isolate;
  try {
    isolate = await Isolate.spawn(
      entry,
      buildMessage(receive.sendPort),
      debugName: debugName,
    );
  } catch (e, st) {
    receive.close();
    _log.warning('failed to spawn alignment isolate', e, st);
    rethrow;
  }

  var killed = false;
  void kill() {
    if (killed) return;
    killed = true;
    isolate.kill(priority: Isolate.immediate);
  }

  final done = Completer<Object>();
  SendPort? cancelToChild;
  receive.listen((message) {
    if (message is SendPort) {
      cancelToChild = message;
      return;
    }
    if (!done.isCompleted) done.complete(message as Object);
  });

  cancel?.onCancel(() {
    cancelToChild?.send(true);
    kill();
    if (!done.isCompleted) {
      done.completeError(const IsolateCancelled());
    }
  });

  try {
    return await done.future.timeout(timeout);
  } on TimeoutException {
    cancelToChild?.send(true);
    kill();
    if (cancel?.isCancelled ?? false) {
      throw const IsolateCancelled();
    }
    throw const IsolateTimeout();
  } finally {
    receive.close();
  }
}

/// Runs [runAlignPipeline] off the calling isolate. Kills the worker on
/// cancel or timeout. Does not initialize eSpeak-NG.
Future<Object> runAlignJobInIsolate({
  required AlignIsolateJob job,
  AlignmentCancelToken? cancel,
  required Duration timeout,
}) => _spawnWithCancel(
  entry: _alignIsolateMain,
  buildMessage: (reply) => _AlignIsolateBox(reply, job),
  debugName: 'forced_alignment',
  cancel: cancel,
  timeout: timeout,
);

/// Runs all cue DTW alignments for a multi-cue transcript inside one worker
/// isolate so `sourcePcm` crosses the isolate boundary only once.
Future<Object> runAlignSegmentsJobInIsolate({
  required AlignSegmentsIsolateJob job,
  AlignmentCancelToken? cancel,
  required Duration timeout,
}) => _spawnWithCancel(
  entry: _alignSegmentsIsolateMain,
  buildMessage: (reply) => _AlignSegmentsIsolateBox(reply, job),
  debugName: 'forced_alignment_segments',
  cancel: cancel,
  timeout: timeout,
);
