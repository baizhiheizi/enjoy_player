import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/files/ffmpeg_argv_runner.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';

const String _stubScript = r'''#!/bin/sh
case "$1" in
  -fail) echo "stub failure" >&2; exit 3 ;;
  -sleep) sleep 30 ;;
esac
exit 0
''';

void main() {
  group('runFfmpegArgv', () {
    late Directory temp;
    late File stub;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('ffmpeg_runner_test_');
      stub = File('${temp.path}/ffmpeg-stub')..writeAsStringSync(_stubScript);
      Process.runSync('chmod', <String>['+x', stub.path]);
      FfmpegMediaProbe.debugExecutableOverride = stub.path;
    });

    tearDown(() {
      FfmpegMediaProbe.debugExecutableOverride = null;
      FfmpegMediaProbe.debugForceUnavailable = false;
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('reports success for a zero exit code', () async {
      final result = await runFfmpegArgv(
        args: <String>['-version'],
        failLabel: 'probe',
      );
      expect(result.outcome, FfmpegOutcome.success);
      expect(result.succeeded, isTrue);
      expect(result.exitCode, 0);
    });

    test('reports failure for a non-zero exit code', () async {
      final result = await runFfmpegArgv(
        args: <String>['-fail'],
        failLabel: 'probe',
      );
      expect(result.outcome, FfmpegOutcome.failed);
      expect(result.succeeded, isFalse);
      expect(result.exitCode, 3);
      expect(result.stderr, contains('stub failure'));
    });

    test('runs the isolate prelude inside the encode isolate', () async {
      final result = await runFfmpegArgv(
        args: <String>['-version'],
        failLabel: 'probe',
        cliBackend: FfmpegCliBackend.isolateRun,
        isolatePrelude: () async => 'prelude-value',
      );
      expect(result.outcome, FfmpegOutcome.success);
      expect(result.extra, 'prelude-value');
    });

    test('runs the isolate prelude on the non-isolate backends too', () async {
      final result = await runFfmpegArgv(
        args: <String>['-version'],
        failLabel: 'probe',
        isolatePrelude: () async => 'prelude-value',
      );
      expect(result.outcome, FfmpegOutcome.success);
      expect(result.extra, 'prelude-value');
    });

    test('deletes the output file after a failed run', () async {
      final output = File('${temp.path}/out.wav')..writeAsStringSync('partial');
      final result = await runFfmpegArgv(
        args: <String>['-fail', output.path],
        failLabel: 'probe',
        outputPath: output.path,
      );
      expect(result.outcome, FfmpegOutcome.failed);
      expect(output.existsSync(), isFalse);
    });

    test('keeps the output file after a successful run', () async {
      final output = File('${temp.path}/out.txt')..writeAsStringSync('kept');
      final result = await runFfmpegArgv(
        args: <String>['-version'],
        failLabel: 'probe',
        outputPath: output.path,
      );
      expect(result.outcome, FfmpegOutcome.success);
      expect(output.existsSync(), isTrue);
    });

    test(
      'keeps a pre-existing output file when ffmpeg is unavailable',
      () async {
        FfmpegMediaProbe.debugForceUnavailable = true;
        final output = File('${temp.path}/cached.jpg')
          ..writeAsStringSync('cached');
        final result = await runFfmpegArgv(
          args: <String>['-version'],
          failLabel: 'probe',
          outputPath: output.path,
        );
        expect(result.outcome, FfmpegOutcome.unavailable);
        expect(output.existsSync(), isTrue);
      },
    );

    test(
      'cancels before spawning when the token is already cancelled',
      () async {
        final token = _Token();
        token.cancel();
        final result = await runFfmpegArgv(
          args: <String>['-version'],
          failLabel: 'probe',
          cancellation: token,
        );
        expect(result.outcome, FfmpegOutcome.cancelled);
      },
    );

    test('cancels a running process', () async {
      final token = _Token();
      final future = runFfmpegArgv(
        args: <String>['-sleep'],
        failLabel: 'probe',
        cliBackend: FfmpegCliBackend.processStart,
        timeout: const Duration(seconds: 30),
        cancellation: token,
      );
      token.cancel();
      final result = await future;
      expect(result.outcome, FfmpegOutcome.cancelled);
    });

    test('times a run out', () async {
      final result = await runFfmpegArgv(
        args: <String>['-sleep'],
        failLabel: 'probe',
        cliBackend: FfmpegCliBackend.processStart,
        timeout: const Duration(milliseconds: 300),
      );
      expect(result.outcome, FfmpegOutcome.timedOut);
    });
  }, skip: !FfmpegMediaProbe.usesFfmpegCli ? 'FFmpegKit platform' : false);
}

final class _Token implements FfmpegCancellation {
  bool _cancelled = false;
  final List<void Function()> _hooks = [];

  @override
  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final hook in List<void Function()>.of(_hooks)) {
      hook();
    }
  }

  @override
  void onCancel(void Function() hook) {
    if (_cancelled) {
      hook();
      return;
    }
    _hooks.add(hook);
  }
}
