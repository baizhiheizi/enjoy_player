/// Runs the FFmpeg invocation for a loop clip export (`loop_clip_export_plan`):
/// the FFmpeg CLI on Windows / Linux, FFmpegKit on Android / iOS / macOS —
/// the same split every other FFmpeg call site uses (see
/// `FfmpegMediaProbe.usesFfmpegCli`).
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_plan.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart';

final _log = logNamed('LoopClipExportRunner');

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

/// Real [LoopClipFfmpegRun]: spawns the CLI or submits an FFmpegKit session,
/// bounded by [kLoopClipExportTimeout].
Future<void> runLoopClipFfmpeg(LoopClipExportRequest request) async {
  if (FfmpegMediaProbe.usesFfmpegCli) {
    final exe = await FfmpegMediaProbe.resolveFfmpegExecutable();
    if (exe == null) {
      throw const LoopClipExportException(
        LoopClipExportFailureReason.ffmpegMissing,
      );
    }
    await _runCli(exe, buildLoopClipFfmpegArgs(request));
    return;
  }
  await _runKit(buildLoopClipFfmpegArgs(request));
}

Future<void> _runCli(String exe, List<String> args) async {
  final Process proc;
  try {
    proc = await Process.start(exe, args);
  } on Object catch (e) {
    throw LoopClipExportException(
      LoopClipExportFailureReason.ffmpegFailed,
      'cli spawn failed: $e',
    );
  }
  final stderrBuf = BytesBuilder(copy: false);
  final stderrDone = Completer<void>();
  proc.stderr.listen(
    stderrBuf.add,
    onDone: stderrDone.complete,
    onError: (Object e) {
      _log.fine('loop clip ffmpeg stderr read error: $e');
      if (!stderrDone.isCompleted) stderrDone.complete();
    },
  );
  unawaited(proc.stdout.drain<void>());

  final int exitCode = await proc.exitCode.timeout(
    kLoopClipExportTimeout,
    onTimeout: () {
      try {
        proc.kill();
      } on Object catch (e) {
        _log.fine('loop clip ffmpeg kill failed: $e');
      }
      throw const LoopClipExportException(LoopClipExportFailureReason.timeout);
    },
  );
  await stderrDone.future;
  if (exitCode != 0) {
    final stderr = systemEncoding.decode(stderrBuf.takeBytes());
    _log.fine('loop clip ffmpeg failed (exit $exitCode): $stderr');
    throw LoopClipExportException(
      LoopClipExportFailureReason.ffmpegFailed,
      'cli exit $exitCode',
    );
  }
}

Future<void> _runKit(List<String> args) async {
  final completer = Completer<void>();
  FFmpegSession? session;
  try {
    session = await FFmpegKit.executeWithArgumentsAsync(args, (s) async {
      if (completer.isCompleted) return;
      final code = await s.getReturnCode();
      if (ReturnCode.isSuccess(code)) {
        completer.complete();
        return;
      }
      completer.completeError(
        const LoopClipExportException(LoopClipExportFailureReason.ffmpegFailed),
      );
    });
  } on MissingPluginException {
    throw const LoopClipExportException(
      LoopClipExportFailureReason.ffmpegMissing,
    );
  }

  final sessionId = session.getSessionId();
  try {
    await completer.future.timeout(
      kLoopClipExportTimeout,
      onTimeout: () {
        if (sessionId != null) unawaited(FFmpegKit.cancel(sessionId));
        throw const LoopClipExportException(
          LoopClipExportFailureReason.timeout,
        );
      },
    );
  } on LoopClipExportException {
    rethrow;
  } on Object catch (e, st) {
    _log.fine('loop clip FFmpegKit failed', e, st);
    throw LoopClipExportException(
      LoopClipExportFailureReason.ffmpegFailed,
      '$e',
    );
  }
}
