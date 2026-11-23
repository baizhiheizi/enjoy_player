import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_plan.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_runner.dart';

const String _stubScript = r'''#!/bin/sh
exit 0
''';

const String _stubFailScript = r'''#!/bin/sh
echo stub failure >&2
exit 3
''';

const String _stubBatchScript =
    '@echo off\r\n'
    'exit /b 0\r\n';

const String _stubFailBatchScript =
    '@echo off\r\n'
    'echo stub failure 1>&2\r\n'
    'exit /b 3\r\n';

void main() {
  late Directory tmp;
  late List<LoopClipExportRequest> seen;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('loop_clip_runner_');
    File('${tmp.path}/in.mp4').writeAsBytesSync([1, 2, 3]);
    seen = [];
  });
  tearDown(() => tmp.delete(recursive: true));

  LoopClipExportRequest request({
    String? input,
    String output = 'clip.mp4',
    double start = 10,
    double duration = 4,
    bool video = true,
  }) => LoopClipExportRequest(
    inputPath: input ?? '${tmp.path}/in.mp4',
    outputPath: '${tmp.path}/$output',
    startSeconds: start,
    durationSeconds: duration,
    video: video,
  );

  test('successful run returns the output path', () async {
    final req = request();
    final runner = LoopClipExportRunner(
      runFfmpeg: (r) async {
        seen.add(r);
        File(r.outputPath).writeAsBytesSync([1, 2, 3]);
      },
    );

    final out = await runner.export(req);

    expect(out, req.outputPath);
    expect(seen, [req]);
  });

  test('non-positive duration → invalidRange without running FFmpeg', () async {
    var ran = false;
    final runner = LoopClipExportRunner(
      runFfmpeg: (r) async {
        ran = true;
        File(r.outputPath).writeAsBytesSync([1]);
      },
    );

    await expectLater(
      runner.export(request(duration: 0)),
      throwsA(
        isA<LoopClipExportException>().having(
          (e) => e.reason,
          'reason',
          LoopClipExportFailureReason.invalidRange,
        ),
      ),
    );
    expect(ran, isFalse);
  });

  test('negative start → invalidRange without running FFmpeg', () async {
    final runner = LoopClipExportRunner(runFfmpeg: (r) async {});

    await expectLater(
      runner.export(request(start: -1)),
      throwsA(
        isA<LoopClipExportException>().having(
          (e) => e.reason,
          'reason',
          LoopClipExportFailureReason.invalidRange,
        ),
      ),
    );
  });

  test('missing local input → fileMissing without running FFmpeg', () async {
    var ran = false;
    final runner = LoopClipExportRunner(
      runFfmpeg: (r) async {
        ran = true;
      },
    );

    await expectLater(
      runner.export(request(input: '${tmp.path}/nope.mp4')),
      throwsA(
        isA<LoopClipExportException>().having(
          (e) => e.reason,
          'reason',
          LoopClipExportFailureReason.fileMissing,
        ),
      ),
    );
    expect(ran, isFalse);
  });

  test('network input skips the local existence probe', () async {
    final runner = LoopClipExportRunner(
      runFfmpeg: (r) async {
        seen.add(r);
        File(r.outputPath).writeAsBytesSync([1]);
      },
    );

    final out = await runner.export(
      request(input: 'https://cdn.example.com/a.mp4'),
    );

    expect(out, '${tmp.path}/clip.mp4');
    expect(seen.single.inputPath, 'https://cdn.example.com/a.mp4');
  });

  test('FFmpeg ran but wrote nothing → emptyOutput', () async {
    final runner = LoopClipExportRunner(runFfmpeg: (r) async {});

    await expectLater(
      runner.export(request()),
      throwsA(
        isA<LoopClipExportException>().having(
          (e) => e.reason,
          'reason',
          LoopClipExportFailureReason.emptyOutput,
        ),
      ),
    );
  });

  test('runner failures propagate typed reasons (ffmpegMissing)', () async {
    final runner = LoopClipExportRunner(
      runFfmpeg: (r) async => throw const LoopClipExportException(
        LoopClipExportFailureReason.ffmpegMissing,
      ),
    );

    await expectLater(
      runner.export(request()),
      throwsA(
        isA<LoopClipExportException>().having(
          (e) => e.reason,
          'reason',
          LoopClipExportFailureReason.ffmpegMissing,
        ),
      ),
    );
  });

  group('runLoopClipFfmpeg (stub CLI)', () {
    late Directory stubTemp;

    setUp(() {
      stubTemp = Directory.systemTemp.createTempSync('loop_clip_ffmpeg_');
    });

    tearDown(() {
      FfmpegMediaProbe.debugExecutableOverride = null;
      FfmpegMediaProbe.debugForceUnavailable = false;
      if (stubTemp.existsSync()) stubTemp.deleteSync(recursive: true);
    });

    LoopClipExportRequest stubRequest() => LoopClipExportRequest(
      inputPath: '${stubTemp.path}/in.mp4',
      outputPath: '${stubTemp.path}/clip.mp4',
      startSeconds: 0,
      durationSeconds: 2,
      video: true,
    );

    File writeStub(String shellBody, String batchBody) {
      if (Platform.isWindows) {
        return File('${stubTemp.path}/ffmpeg-stub.cmd')
          ..writeAsStringSync(batchBody);
      }
      final stub = File('${stubTemp.path}/ffmpeg-stub')
        ..writeAsStringSync(shellBody);
      Process.runSync('chmod', <String>['+x', stub.path]);
      return stub;
    }

    test('a zero exit completes and keeps the output', () async {
      FfmpegMediaProbe.debugExecutableOverride = writeStub(
        _stubScript,
        _stubBatchScript,
      ).path;
      final output = File(stubRequest().outputPath)..writeAsBytesSync([1]);

      await runLoopClipFfmpeg(stubRequest());

      expect(output.existsSync(), isTrue);
    });

    test(
      'a non-zero exit → ffmpegFailed and the partial output is deleted',
      () async {
        FfmpegMediaProbe.debugExecutableOverride = writeStub(
          _stubFailScript,
          _stubFailBatchScript,
        ).path;
        final output = File(stubRequest().outputPath)..writeAsBytesSync([1]);

        await expectLater(
          runLoopClipFfmpeg(stubRequest()),
          throwsA(
            isA<LoopClipExportException>().having(
              (e) => e.reason,
              'reason',
              LoopClipExportFailureReason.ffmpegFailed,
            ),
          ),
        );
        expect(output.existsSync(), isFalse);
      },
    );

    test('no ffmpeg binary → ffmpegMissing', () async {
      FfmpegMediaProbe.debugForceUnavailable = true;

      await expectLater(
        runLoopClipFfmpeg(stubRequest()),
        throwsA(
          isA<LoopClipExportException>().having(
            (e) => e.reason,
            'reason',
            LoopClipExportFailureReason.ffmpegMissing,
          ),
        ),
      );
    });
  }, skip: !FfmpegMediaProbe.usesFfmpegCli ? 'FFmpegKit platform' : false);
}
