import 'package:enjoy_player/data/subtitle/subtitle_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic SRT fixture: [cueCount] cues, 2 s apart, 1.5 s long.
String _buildSrt(int cueCount) {
  final buffer = StringBuffer();
  for (var i = 1; i <= cueCount; i++) {
    final start = i * 2000;
    buffer
      ..writeln(i)
      ..writeln('${_timestamp(start)} --> ${_timestamp(start + 1500)}')
      ..writeln('cue $i first line')
      ..writeln('cue $i second line')
      ..writeln();
  }
  return buffer.toString();
}

String _timestamp(int totalMs) {
  final hours = totalMs ~/ 3600000;
  final minutes = (totalMs % 3600000) ~/ 60000;
  final seconds = (totalMs % 60000) ~/ 1000;
  final millis = totalMs % 1000;
  return '${_pad(hours, 2)}:${_pad(minutes, 2)}:${_pad(seconds, 2)},'
      '${_pad(millis, 3)}';
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');

const String _twoCueSrt =
    '1\n00:00:01,000 --> 00:00:02,000\nHello\n\n'
    '2\n00:00:03,500 --> 00:00:04,500\nSecond line\n\n';

void main() {
  group('SrtParser at scale', () {
    test('parses 5000 cues into strictly ordered entries', () {
      final cues = const SrtParser().parse(_buildSrt(5000));

      expect(cues, hasLength(5000));
      expect(cues.first.text, 'cue 1 first line\ncue 1 second line');
      expect(cues.first.startMs, 2000);
      expect(cues.first.durationMs, 1500);
      expect(cues.last.startMs, 10000000);
      expect(cues.last.durationMs, 1500);
      expect(cues[2499].text, 'cue 2500 first line\ncue 2500 second line');
      expect(cues[2499].startMs, 5000000);

      var ordered = true;
      for (var i = 1; i < cues.length; i++) {
        if (cues[i].startMs <= cues[i - 1].startMs) {
          ordered = false;
          break;
        }
      }
      expect(ordered, isTrue);
    });

    test('keeps every cue of a 5000-cue fixture when text has two lines', () {
      final cues = const SrtParser().parse(_buildSrt(5000));
      var twoLineCues = 0;
      for (final cue in cues) {
        if (cue.text.contains('\n')) twoLineCues++;
      }
      expect(twoLineCues, 5000);
    });
  });

  group('SrtParser line-ending normalization', () {
    test('CRLF and lone-CR inputs match the LF result', () {
      final expected = const SrtParser().parse(_twoCueSrt);

      expect(
        const SrtParser().parse(_twoCueSrt.replaceAll('\n', '\r\n')),
        equals(expected),
      );
      expect(
        const SrtParser().parse(_twoCueSrt.replaceAll('\n', '\r')),
        equals(expected),
      );
    });

    test('mixed line endings match the LF result', () {
      const mixed =
          '1\r\n00:00:01,000 --> 00:00:02,000\rHello\n\n'
          '2\n00:00:03,500 --> 00:00:04,500\nSecond line\n\n';

      expect(
        const SrtParser().parse(mixed),
        equals(const SrtParser().parse(_twoCueSrt)),
      );
    });

    test('a trailing carriage return does not drop the last cue', () {
      const trailing = '1\n00:00:01,000 --> 00:00:02,000\nHello\r';

      expect(const SrtParser().parse(trailing), hasLength(1));
      expect(const SrtParser().parse(trailing).single.text, 'Hello');
    });
  });

  group('SrtParser timestamp forms', () {
    test('accepts a single-digit hour field', () {
      final cues = const SrtParser().parse(
        '1\n1:00:01,000 --> 1:00:02,000\nX\n',
      );

      expect(cues, hasLength(1));
      expect(cues.single.startMs, 3601000);
      expect(cues.single.durationMs, 1000);
    });

    test('accepts a dot sub-second separator', () {
      final cues = const SrtParser().parse(
        '1\n00:00:01.500 --> 00:00:02.500\nY\n',
      );

      expect(cues, hasLength(1));
      expect(cues.single.startMs, 1500);
      expect(cues.single.durationMs, 1000);
    });

    test('drops a cue whose minute field is out of range', () {
      final cues = const SrtParser().parse(
        '1\n00:60:01,000 --> 00:61:02,000\nZ\n',
      );

      expect(cues, isEmpty);
    });
  });

  test('parses a 5000-cue SRT under the loose ceiling (local only)', () {
    const parser = SrtParser();
    final input = _buildSrt(5000);

    parser.parse(input);

    final sw = Stopwatch()..start();
    const runs = 20;
    for (var i = 0; i < runs; i++) {
      parser.parse(input);
    }
    sw.stop();

    final medianMs = sw.elapsedMilliseconds / runs;
    // ignore: avoid_print
    print('subtitle parse: ${medianMs.toStringAsFixed(2)} ms/run (5000 cues)');
    expect(medianMs, lessThan(500));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
