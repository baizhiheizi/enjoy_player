/// Runs the FFmpeg invocation for a loop clip export (`loop_clip_export_plan`)
/// through `runFfmpegArgv` — the one dispatch every FFmpeg call site shares
/// (see `data/files/ffmpeg_argv_runner.dart`).
library;

import 'dart:io';

import 'package:enjoy_player/data/files/ffmpeg_argv_runner.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_plan.dart';

/// Why a loop clip export failed. `ffmpegMissing` is the actionable one —
/// the user can install / restore FFmpeg — so it maps to its own notice.
enum LoopClipExportFailureReason {
  invalidRange,
  fileMissing,
  ffmpegMissing,
  ffmpegFailed,
  timeout,
  emptyOutput,
}

class LoopClipExportException implements Exception {
  const LoopClipExportException(this.reason, [this.message = '']);

  final LoopClipExportFailureReason reason;
  final String message;

  @override
  String toString() =>
      'LoopClipExportException($reason'
      '${message.isEmpty ? '' : ': $message'})';
}

/// Default per-export wall-clock budget. A loop re-encode is seconds of
/// media; a hung FFmpeg surfaces as a timeout instead of blocking the flow.
const Duration kLoopClipExportTimeout = Duration(seconds: 120);

/// The FFmpeg boundary, injectable so tests fake the process / plugin.
typedef LoopClipFfmpegRun =
    Future<void> Function(LoopClipExportRequest request);

/// Writes the trimmed clip for [request] to [request.outputPath].
///
/// Throws [LoopClipExportException] for every failure mode; returns the
/// output path only after FFmpeg exited successfully and the file exists
/// non-empty.
class LoopClipExportRunner {
  const LoopClipExportRunner({this.runFfmpeg = runLoopClipFfmpeg});

  final LoopClipFfmpegRun runFfmpeg;

  Future<String> export(LoopClipExportRequest request) async {
    if (request.durationSeconds <= 0 ||
        request.startSeconds < 0 ||
        request.inputPath.trim().isEmpty ||
        request.outputPath.trim().isEmpty) {
      throw const LoopClipExportException(
        LoopClipExportFailureReason.invalidRange,
      );
    }
    if (!loopClipInputIsNetwork(request.inputPath) &&
        !File(request.inputPath).existsSync()) {
      throw const LoopClipExportException(
        LoopClipExportFailureReason.fileMissing,
      );
    }
    await runFfmpeg(request);
    final output = File(request.outputPath);
    if (!output.existsSync() || output.lengthSync() == 0) {
      throw const LoopClipExportException(
        LoopClipExportFailureReason.emptyOutput,
      );
    }
    return request.outputPath;
  }
}

/// Real [LoopClipFfmpegRun]: the shared dispatch on its cancellable backends
/// (`processStart` CLI, async FFmpegKit), bounded by [timeout] (default
/// [kLoopClipExportTimeout]). A run that did not succeed deletes the partial
/// output.
Future<void> runLoopClipFfmpeg(
  LoopClipExportRequest request, {
  Duration? timeout,
}) async {
  final result = await runFfmpegArgv(
    args: buildLoopClipFfmpegArgs(request),
    failLabel: 'loop clip export',
    cliBackend: FfmpegCliBackend.processStart,
    kitBackend: FfmpegKitBackend.async,
    timeout: timeout ?? kLoopClipExportTimeout,
    outputPath: request.outputPath,
  );
  switch (result.outcome) {
    case FfmpegOutcome.success:
      return;
    case FfmpegOutcome.unavailable:
      throw const LoopClipExportException(
        LoopClipExportFailureReason.ffmpegMissing,
      );
    case FfmpegOutcome.timedOut:
      throw const LoopClipExportException(LoopClipExportFailureReason.timeout);
    case FfmpegOutcome.failed:
    case FfmpegOutcome.cancelled:
      throw LoopClipExportException(
        LoopClipExportFailureReason.ffmpegFailed,
        result.exitCode == null ? '' : 'exit ${result.exitCode}',
      );
  }
}
