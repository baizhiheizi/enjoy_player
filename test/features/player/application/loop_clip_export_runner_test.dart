import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/player/application/loop_clip_export_plan.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_runner.dart';

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
}
