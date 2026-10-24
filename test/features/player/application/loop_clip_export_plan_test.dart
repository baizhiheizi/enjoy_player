import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_plan.dart';
import 'package:enjoy_player/features/player/domain/echo_window.dart';

LoopClipExportRequest _request({
  String input = '/media/in.mp4',
  String output = '/out/clip.mp4',
  double start = 12,
  double duration = 6,
  bool video = true,
}) => LoopClipExportRequest(
  inputPath: input,
  outputPath: output,
  startSeconds: start,
  durationSeconds: duration,
  video: video,
);

EchoState _echo({
  bool active = true,
  int startLine = -1,
  int endLine = -1,
  double start = 10,
  double end = 14,
}) => EchoState(
  active: active,
  startLineIndex: startLine,
  endLineIndex: endLine,
  startTimeSeconds: start,
  endTimeSeconds: end,
);

void main() {
  group('resolveLoopClipRange', () {
    test('inactive echo → null', () {
      expect(resolveLoopClipRange(_echo(active: false)), isNull);
    });

    test('cached seconds win when no transcript is loaded', () {
      expect(resolveLoopClipRange(_echo()), (start: 10, end: 14));
    });

    test('line bounds win over cached seconds', () {
      const lines = [
        TranscriptLine(text: 'a', startMs: 0, durationMs: 2000),
        TranscriptLine(text: 'b', startMs: 2000, durationMs: 3000),
        TranscriptLine(text: 'c', startMs: 5000, durationMs: 2500),
      ];
      expect(
        resolveLoopClipRange(_echo(startLine: 0, endLine: 1), lines: lines),
        (start: 0, end: 5),
      );
    });

    test('stale line indices fall back to cached seconds per index', () {
      const lines = [TranscriptLine(text: 'a', startMs: 0, durationMs: 100)];
      expect(
        resolveLoopClipRange(_echo(startLine: 0, endLine: 9), lines: lines),
        (start: 0, end: 14),
      );
    });

    test('window is clamped to the media duration', () {
      expect(resolveLoopClipRange(_echo(end: 30), durationSeconds: 20), (
        start: 10,
        end: 20,
      ));
    });

    test('inverted window → null', () {
      expect(resolveLoopClipRange(_echo(start: 14, end: 10)), isNull);
    });

    test('sub-minimum window is widened to the playable floor', () {
      expect(resolveLoopClipRange(_echo(end: 10.01)), (
        start: 10,
        end: 10 + defaultEchoEndGuardSeconds + 0.02,
      ));
    });
  });

  group('loopClipFileName', () {
    test('video clips are mp4, audio clips m4a', () {
      const window = (start: 12.0, end: 18.0);
      expect(
        loopClipFileName(title: 'Ferry', video: true, window: window),
        'Ferry-clip-12-18s.mp4',
      );
      expect(
        loopClipFileName(title: 'Ferry', video: false, window: window),
        'Ferry-clip-12-18s.m4a',
      );
    });

    test('fractional seconds render with one decimal', () {
      expect(
        loopClipFileName(
          title: 'Ferry',
          video: true,
          window: (start: 12.25, end: 18.04),
        ),
        'Ferry-clip-12.3-18s.mp4',
      );
    });

    test('unsafe title characters are replaced and whitespace collapsed', () {
      expect(
        loopClipFileName(
          title: r'a/b\c:d*e?f"g<h>i|j',
          video: true,
          window: (start: 1, end: 2),
        ),
        'a b c d e f g h i j-clip-1-2s.mp4',
      );
    });

    test('empty title falls back to loop-clip', () {
      expect(
        loopClipFileName(title: '  ', video: false, window: (start: 0, end: 3)),
        'loop-clip-clip-0-3s.m4a',
      );
    });

    test('overlong titles are truncated to 80 characters', () {
      final name = loopClipFileName(
        title: 'x' * 200,
        video: true,
        window: (start: 0, end: 1),
      );
      final base = name.split('-clip-').first;
      expect(base.length, 80);
    });
  });

  group('buildLoopClipFfmpegArgs', () {
    test('local audio export trims, drops video, muxes m4a', () {
      expect(
        buildLoopClipFfmpegArgs(
          _request(
            input: '/media/in.mp3',
            output: '/out/y.m4a',
            start: 12.5,
            duration: 5.5,
            video: false,
          ),
        ),
        [
          '-nostdin',
          '-hide_banner',
          '-loglevel',
          'error',
          '-y',
          '-ss',
          '12.5000',
          '-i',
          '/media/in.mp3',
          '-t',
          '5.5000',
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          '-f',
          'ipod',
          '/out/y.m4a',
        ],
      );
    });

    test('local video export maps optional streams and muxes mp4', () {
      final args = buildLoopClipFfmpegArgs(_request());
      expect(args, isNot(contains('-vn')));
      expect(args.skip(args.indexOf('-map')).toList(), [
        '-map',
        '0:v:0?',
        '-map',
        '0:a:0?',
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '20',
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-movflags',
        '+faststart',
        '-f',
        'mp4',
        '/out/clip.mp4',
      ]);
    });

    test('network inputs carry the protocol whitelist before -i', () {
      final args = buildLoopClipFfmpegArgs(
        _request(input: 'https://cdn.example.com/a.mp4'),
      );
      final i = args.indexOf('-i');
      expect(args[i - 2], '-protocol_whitelist');
      expect(args[i - 1], 'file,http,https,tcp,tls,crypto');
    });

    test('local inputs carry no protocol whitelist', () {
      expect(
        buildLoopClipFfmpegArgs(_request()),
        isNot(contains('-protocol_whitelist')),
      );
    });
  });

  group('loopClipInputIsNetwork', () {
    test('http(s) URLs are network, paths and file URIs are not', () {
      expect(loopClipInputIsNetwork('https://example.com/a.mp4'), isTrue);
      expect(loopClipInputIsNetwork('HTTP://example.com/a.mp4'), isTrue);
      expect(loopClipInputIsNetwork('/media/a.mp4'), isFalse);
      expect(loopClipInputIsNetwork('file:///media/a.mp4'), isFalse);
    });
  });
}
