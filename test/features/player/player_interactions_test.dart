import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lines = <TranscriptLine>[
    const TranscriptLine(text: 'line 1', startMs: 0, durationMs: 2000),
    const TranscriptLine(text: 'line 2', startMs: 2000, durationMs: 2000),
    const TranscriptLine(text: 'line 3', startMs: 4000, durationMs: 2000),
    const TranscriptLine(text: 'line 4', startMs: 6000, durationMs: 2000),
  ];

  const echoOnLine2 = EchoState(
    active: true,
    startLineIndex: 1,
    endLineIndex: 1,
    startTimeSeconds: 2,
    endTimeSeconds: 4,
  );

  group('nextLineNavigationIndex', () {
    test('uses playback position when echo is off', () {
      expect(
        nextLineNavigationIndex(
          echo: EchoState.inactive,
          lines: lines,
          currentTimeSeconds: 2.5,
        ),
        2,
      );
    });

    test('follows echo region when playback is on the next cue boundary', () {
      expect(
        nextLineNavigationIndex(
          echo: echoOnLine2,
          lines: lines,
          currentTimeSeconds: 4,
        ),
        2,
      );
    });

    test('follows echo end when playback is still inside the segment', () {
      expect(
        nextLineNavigationIndex(
          echo: echoOnLine2,
          lines: lines,
          currentTimeSeconds: 3,
        ),
        2,
      );
    });

    test('jumps past multi-line echo region', () {
      const multiLineEcho = EchoState(
        active: true,
        startLineIndex: 1,
        endLineIndex: 2,
        startTimeSeconds: 2,
        endTimeSeconds: 6,
      );
      expect(
        nextLineNavigationIndex(
          echo: multiLineEcho,
          lines: lines,
          currentTimeSeconds: 5,
        ),
        3,
      );
    });
  });

  group('prevLineNavigationIndex', () {
    test('uses playback position when echo is off', () {
      expect(
        prevLineNavigationIndex(
          echo: EchoState.inactive,
          lines: lines,
          currentTimeSeconds: 4.5,
        ),
        1,
      );
    });

    test('follows echo region when playback is on the next cue boundary', () {
      expect(
        prevLineNavigationIndex(
          echo: echoOnLine2,
          lines: lines,
          currentTimeSeconds: 4,
        ),
        0,
      );
    });

    test('steps before multi-line echo region', () {
      const multiLineEcho = EchoState(
        active: true,
        startLineIndex: 1,
        endLineIndex: 2,
        startTimeSeconds: 2,
        endTimeSeconds: 6,
      );
      expect(
        prevLineNavigationIndex(
          echo: multiLineEcho,
          lines: lines,
          currentTimeSeconds: 5,
        ),
        0,
      );
    });

    test('clamps to zero when already at first line', () {
      expect(
        prevLineNavigationIndex(
          echo: EchoState.inactive,
          lines: lines,
          currentTimeSeconds: 0.5,
        ),
        0,
      );
    });

    test('clamps to zero when echo starts at first line', () {
      const echoOnFirst = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 0,
        startTimeSeconds: 0,
        endTimeSeconds: 2,
      );
      expect(
        prevLineNavigationIndex(
          echo: echoOnFirst,
          lines: lines,
          currentTimeSeconds: 1,
        ),
        0,
      );
    });
  });

  group('nextLineNavigationIndex edge cases', () {
    test('clamps to last index when already at last line', () {
      expect(
        nextLineNavigationIndex(
          echo: EchoState.inactive,
          lines: lines,
          currentTimeSeconds: 7.0,
        ),
        3,
      );
    });

    test('clamps to last index when echo ends at last line', () {
      const echoOnLast = EchoState(
        active: true,
        startLineIndex: 3,
        endLineIndex: 3,
        startTimeSeconds: 6,
        endTimeSeconds: 8,
      );
      expect(
        nextLineNavigationIndex(
          echo: echoOnLast,
          lines: lines,
          currentTimeSeconds: 7,
        ),
        3,
      );
    });
  });

  group('indexOfActiveLine', () {
    test('returns index of line containing time', () {
      expect(indexOfActiveLine(lines, 0.5), 0);
      expect(indexOfActiveLine(lines, 2.5), 1);
      expect(indexOfActiveLine(lines, 4.5), 2);
      expect(indexOfActiveLine(lines, 6.5), 3);
    });

    test('returns index at exact start boundary', () {
      expect(indexOfActiveLine(lines, 0.0), 0);
      expect(indexOfActiveLine(lines, 2.0), 1);
      expect(indexOfActiveLine(lines, 4.0), 2);
      expect(indexOfActiveLine(lines, 6.0), 3);
    });

    test('returns last line index when time is past all lines', () {
      expect(indexOfActiveLine(lines, 100.0), 3);
    });

    test('returns -1 when time is before all lines', () {
      final futureLines = <TranscriptLine>[
        const TranscriptLine(text: 'a', startMs: 5000, durationMs: 2000),
        const TranscriptLine(text: 'b', startMs: 7000, durationMs: 2000),
      ];
      expect(indexOfActiveLine(futureLines, 1.0), -1);
    });

    test('returns -1 for empty lines', () {
      expect(indexOfActiveLine([], 5.0), -1);
    });

    test(
      'falls back to last line whose start is before time (gap between cues)',
      () {
        final gapped = <TranscriptLine>[
          const TranscriptLine(text: 'a', startMs: 0, durationMs: 1000),
          const TranscriptLine(text: 'b', startMs: 5000, durationMs: 1000),
        ];
        expect(indexOfActiveLine(gapped, 3.0), 0);
      },
    );

    test('returns last line when time equals end of last line', () {
      expect(indexOfActiveLine(lines, 8.0), 3);
    });
  });
}
