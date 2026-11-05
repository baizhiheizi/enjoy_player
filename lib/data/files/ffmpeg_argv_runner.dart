/// One FFmpeg invocation shared by every feature that shells out to FFmpeg.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart';

final _log = logNamed('data.ffmpeg_argv_runner');

/// The wall-clock budget a run gets when the caller does not pick one.
const Duration kFfmpegDefaultTimeout = Duration(seconds: 30);

/// Why an FFmpeg invocation ended the way it did.
enum FfmpegOutcome {
  /// The encode finished with exit code 0 / `ReturnCode.isSuccess`.
  success,

  /// The encode ran but reported a non-zero exit code.
  failed,

  /// No backend was available: no CLI binary, or FFmpegKit not registered.
  unavailable,

  /// The run was cancelled before the encode finished.
  cancelled,

  /// The encode exceeded its wall-clock budget.
  timedOut,
}

/// How the CLI backend spawns the FFmpeg binary.
enum FfmpegCliBackend {
  /// `Process.run` on the calling isolate.
  processRun,

  /// `Process.run` inside a worker isolate, off the UI isolate.
  isolateRun,

  /// `Process.start`, so a cancel or a timeout can kill the process.
  processStart,
}

/// How the FFmpegKit backend runs the encode.
enum FfmpegKitBackend {
  /// `FFmpegKit.executeWithArguments` + `getReturnCode`.
  sync,

  /// `FFmpegKit.executeWithArgumentsAsync`, whose session id allows a real
  /// cancel of the running encode.
  async,
}

/// Cooperative cancellation for a running FFmpeg invocation.
abstract interface class FfmpegCancellation {
  /// Whether the run has been cancelled.
  bool get isCancelled;

  /// Registers [handler] to run when the run is cancelled.
  void onCancel(void Function() handler);
}

/// Work to run inside the worker isolate before the CLI spawn; its result
/// rides back with the run.
typedef FfmpegIsolatePrelude = Future<Object?> Function();

/// The outcome of one FFmpeg invocation.
final class FfmpegRunResult {
  const FfmpegRunResult({
    required this.outcome,
    this.exitCode,
    this.stderr,
    this.extra,
  });

  const FfmpegRunResult.success({this.exitCode = 0, this.stderr, this.extra})
    : outcome = FfmpegOutcome.success;

  final FfmpegOutcome outcome;

  /// The process exit code, when the backend reports one.
  final int? exitCode;

  /// The backend's error output, when it reports any.
  final String? stderr;

  /// Whatever the caller's isolate prelude returned.
  final Object? extra;

  /// Whether the encode succeeded.
  bool get succeeded => outcome == FfmpegOutcome.success;
}

/// Runs [args] through the platform-appropriate FFmpeg backend.
///
/// Windows and Linux run the CLI binary resolved by
/// [FfmpegMediaProbe.resolveFfmpegExecutable]; Android, iOS and macOS run
/// FFmpegKit. Every caller shares this dispatch, so FFmpeg availability is
/// decided in exactly one place.
///
/// [isolatePrelude] runs before the encode, in a worker isolate. On the
/// [FfmpegCliBackend.isolateRun] backend it shares the encode's worker
/// isolate instead, so a caller that scans an input file pays for one isolate
/// spawn rather than two.
///
/// [outputPath], when given, is deleted after a run that did not succeed, so
/// a failed encode never leaves a half-written file behind.
Future<FfmpegRunResult> runFfmpegArgv({
  required List<String> args,
  required String failLabel,
  FfmpegCliBackend cliBackend = FfmpegCliBackend.processRun,
  FfmpegKitBackend kitBackend = FfmpegKitBackend.sync,
  FfmpegIsolatePrelude? isolatePrelude,
  Duration? timeout,
  FfmpegCancellation? cancellation,
  String? outputPath,
}) async {
  if (cancellation?.isCancelled ?? false) {
    return const FfmpegRunResult(outcome: FfmpegOutcome.cancelled);
  }

  final bool usesCli = FfmpegMediaProbe.usesFfmpegCli;
  final String? executable = usesCli
      ? await FfmpegMediaProbe.resolveFfmpegExecutable()
      : null;
  if (usesCli && executable == null) {
    _log.fine('ffmpeg $failLabel: no ffmpeg CLI found');
    return _finish(
      const FfmpegRunResult(outcome: FfmpegOutcome.unavailable),
      outputPath: outputPath,
    );
  }

  final bool sharesEncodeIsolate =
      usesCli && cliBackend == FfmpegCliBackend.isolateRun;
  Object? extra;
  if (isolatePrelude != null && !sharesEncodeIsolate) {
    try {
      extra = await Isolate.run(isolatePrelude, debugName: 'ffmpeg-prelude');
    } on Object catch (e, st) {
      _log.fine('ffmpeg $failLabel prelude failed', e, st);
    }
  }

  final FfmpegRunResult raw;
  if (usesCli) {
    raw = await _runCli(
      executable: executable!,
      args: args,
      failLabel: failLabel,
      backend: cliBackend,
      isolatePrelude: sharesEncodeIsolate ? isolatePrelude : null,
      timeout: timeout,
      cancellation: cancellation,
    );
  } else {
    raw = await _runKit(
      args: args,
      failLabel: failLabel,
      backend: kitBackend,
      timeout: timeout,
      cancellation: cancellation,
    );
  }

  final result = raw.extra != null
      ? raw
      : FfmpegRunResult(
          outcome: raw.outcome,
          exitCode: raw.exitCode,
          stderr: raw.stderr,
          extra: extra,
        );
  return _finish(result, outputPath: outputPath);
}

Future<FfmpegRunResult> _finish(
  FfmpegRunResult result, {
  required String? outputPath,
}) async {
  if (!result.succeeded &&
      result.outcome != FfmpegOutcome.unavailable &&
      outputPath != null) {
    await _deleteIfExists(outputPath);
  }
  return result;
}

Future<FfmpegRunResult> _runCli({
  required String executable,
  required List<String> args,
  required String failLabel,
  required FfmpegCliBackend backend,
  FfmpegIsolatePrelude? isolatePrelude,
  Duration? timeout,
  FfmpegCancellation? cancellation,
}) {
  switch (backend) {
    case FfmpegCliBackend.processRun:
      return _runCliProcessRun(executable, args, failLabel);
    case FfmpegCliBackend.isolateRun:
      return _runCliIsolate(executable, args, failLabel, isolatePrelude);
    case FfmpegCliBackend.processStart:
      return _runCliProcessStart(
        executable: executable,
        args: args,
        failLabel: failLabel,
        timeout: timeout,
        cancellation: cancellation,
      );
  }
}

Future<FfmpegRunResult> _runCliProcessRun(
  String executable,
  List<String> args,
  String failLabel,
) async {
  try {
    final result = await Process.run(executable, args);
    final stderr = result.stderr is String ? result.stderr as String : '';
    if (result.exitCode == 0) {
      return FfmpegRunResult.success(exitCode: 0, stderr: stderr);
    }
    _log.fine('ffmpeg $failLabel failed (exit ${result.exitCode}): $stderr');
    return FfmpegRunResult(
      outcome: FfmpegOutcome.failed,
      exitCode: result.exitCode,
      stderr: stderr,
    );
  } on Object catch (e, st) {
    _log.fine('ffmpeg $failLabel spawn failed', e, st);
    return const FfmpegRunResult(outcome: FfmpegOutcome.failed);
  }
}

Future<FfmpegRunResult> _runCliIsolate(
  String executable,
  List<String> args,
  String failLabel,
  FfmpegIsolatePrelude? isolatePrelude,
) async {
  try {
    final run = await Isolate.run(
      () => _cliIsolateBody(
        _CliIsolateRequest(
          executable: executable,
          args: args,
          prelude: isolatePrelude,
        ),
      ),
      debugName: 'ffmpeg-argv',
    );
    if (run.exitCode == 0) {
      return FfmpegRunResult.success(
        exitCode: 0,
        stderr: run.stderr,
        extra: run.extra,
      );
    }
    _log.fine('ffmpeg $failLabel failed (exit ${run.exitCode}): ${run.stderr}');
    return FfmpegRunResult(
      outcome: FfmpegOutcome.failed,
      exitCode: run.exitCode,
      stderr: run.stderr,
      extra: run.extra,
    );
  } on Object catch (e, st) {
    _log.fine('ffmpeg $failLabel isolate run failed', e, st);
    return const FfmpegRunResult(outcome: FfmpegOutcome.failed);
  }
}

Future<FfmpegRunResult> _runCliProcessStart({
  required String executable,
  required List<String> args,
  required String failLabel,
  Duration? timeout,
  FfmpegCancellation? cancellation,
}) async {
  if (cancellation?.isCancelled ?? false) {
    return const FfmpegRunResult(outcome: FfmpegOutcome.cancelled);
  }
  final Process process;
  try {
    process = await Process.start(executable, args);
  } on Object catch (e, st) {
    _log.fine('ffmpeg $failLabel spawn failed', e, st);
    return const FfmpegRunResult(outcome: FfmpegOutcome.failed);
  }

  final stderrBuffer = <List<int>>[];
  process.stderr.listen(
    stderrBuffer.add,
    onError: (Object e) => _log.fine('ffmpeg $failLabel stderr read: $e'),
  );
  unawaited(process.stdout.drain<void>());

  cancellation?.onCancel(() {
    try {
      process.kill(ProcessSignal.sigterm);
    } on Object catch (e) {
      _log.fine('ffmpeg $failLabel kill failed', e);
    }
  });

  var didTimeout = false;
  final exitCode = await process.exitCode.timeout(
    timeout ?? kFfmpegDefaultTimeout,
    onTimeout: () {
      didTimeout = true;
      try {
        process.kill(ProcessSignal.sigkill);
      } on Object catch (_) {}
      return -1;
    },
  );
  if (didTimeout) {
    _log.fine('ffmpeg $failLabel timed out');
    return const FfmpegRunResult(outcome: FfmpegOutcome.timedOut);
  }
  if (cancellation?.isCancelled ?? false) {
    return const FfmpegRunResult(outcome: FfmpegOutcome.cancelled);
  }

  final stderr = systemEncoding.decode(stderrBuffer.expand((l) => l).toList());
  if (exitCode != 0) {
    _log.fine('ffmpeg $failLabel failed (exit $exitCode): $stderr');
    return FfmpegRunResult(
      outcome: FfmpegOutcome.failed,
      exitCode: exitCode,
      stderr: stderr,
    );
  }
  return FfmpegRunResult.success(exitCode: exitCode, stderr: stderr);
}

Future<FfmpegRunResult> _runKit({
  required List<String> args,
  required String failLabel,
  required FfmpegKitBackend backend,
  Duration? timeout,
  FfmpegCancellation? cancellation,
}) {
  switch (backend) {
    case FfmpegKitBackend.sync:
      return _runKitSync(args, failLabel);
    case FfmpegKitBackend.async:
      return _runKitAsync(
        args: args,
        failLabel: failLabel,
        timeout: timeout,
        cancellation: cancellation,
      );
  }
}

Future<FfmpegRunResult> _runKitSync(List<String> args, String failLabel) async {
  try {
    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code)) {
      return FfmpegRunResult.success(exitCode: code?.getValue());
    }
    final output = await session.getOutput();
    _log.fine('ffmpeg $failLabel failed: $output');
    return FfmpegRunResult(
      outcome: FfmpegOutcome.failed,
      exitCode: code?.getValue(),
      stderr: output,
    );
  } on MissingPluginException catch (e, st) {
    _log.fine('ffmpeg $failLabel: FFmpegKit not registered', e, st);
    return const FfmpegRunResult(outcome: FfmpegOutcome.unavailable);
  }
}

Future<FfmpegRunResult> _runKitAsync({
  required List<String> args,
  required String failLabel,
  Duration? timeout,
  FfmpegCancellation? cancellation,
}) async {
  if (cancellation?.isCancelled ?? false) {
    return const FfmpegRunResult(outcome: FfmpegOutcome.cancelled);
  }

  final completer = Completer<FfmpegRunResult>();
  final FFmpegSession session;
  try {
    session = await FFmpegKit.executeWithArgumentsAsync(args, (s) async {
      if (completer.isCompleted) return;
      final code = await s.getReturnCode();
      if (ReturnCode.isSuccess(code)) {
        completer.complete(FfmpegRunResult.success(exitCode: code?.getValue()));
        return;
      }
      String? detail;
      try {
        detail = await s.getOutput();
      } on Object catch (_) {}
      completer.complete(
        FfmpegRunResult(
          outcome: FfmpegOutcome.failed,
          exitCode: code?.getValue(),
          stderr: detail,
        ),
      );
    });
  } on MissingPluginException catch (e, st) {
    _log.fine('ffmpeg $failLabel: FFmpegKit not registered', e, st);
    return const FfmpegRunResult(outcome: FfmpegOutcome.unavailable);
  }

  final sessionId = session.getSessionId();
  if (sessionId != null) {
    cancellation?.onCancel(() {
      if (completer.isCompleted) return;
      unawaited(_cancelKitSession(sessionId));
      completer.complete(
        const FfmpegRunResult(outcome: FfmpegOutcome.cancelled),
      );
    });
  }

  try {
    return await completer.future.timeout(
      timeout ?? kFfmpegDefaultTimeout,
      onTimeout: () {
        if (sessionId != null) {
          unawaited(_cancelKitSession(sessionId));
        }
        _log.fine('ffmpeg $failLabel timed out');
        return const FfmpegRunResult(outcome: FfmpegOutcome.timedOut);
      },
    );
  } on Object catch (e, st) {
    _log.fine('ffmpeg $failLabel failed', e, st);
    return const FfmpegRunResult(outcome: FfmpegOutcome.failed);
  }
}

Future<void> _cancelKitSession(int sessionId) async {
  try {
    await FFmpegKit.cancel(sessionId);
  } on Object catch (e, st) {
    _log.fine('ffmpeg kit cancel failed', e, st);
  }
}

Future<void> _deleteIfExists(String path) async {
  try {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  } on Object catch (_) {}
}

final class _CliIsolateRequest {
  const _CliIsolateRequest({
    required this.executable,
    required this.args,
    this.prelude,
  });

  final String executable;
  final List<String> args;
  final FfmpegIsolatePrelude? prelude;
}

final class _CliIsolateOutcome {
  const _CliIsolateOutcome({
    required this.exitCode,
    required this.stderr,
    this.extra,
  });

  final int exitCode;
  final String stderr;
  final Object? extra;
}

Future<_CliIsolateOutcome> _cliIsolateBody(_CliIsolateRequest request) async {
  final extra = await request.prelude?.call();
  final result = await Process.run(request.executable, request.args);
  return _CliIsolateOutcome(
    exitCode: result.exitCode,
    stderr: result.stderr is String ? result.stderr as String : '',
    extra: extra,
  );
}
