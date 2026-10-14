import 'package:enjoy_player/data/subtitle/subtitle_parser.dart';
import 'package:enjoy_player/data/subtitle/subtitle_serializer.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptLine _line(String text, int startMs, int durationMs) =>
    TranscriptLine(text: text, startMs: startMs, durationMs: durationMs);

void main() {
  group('serializeSrt', () {
    test('writes 1-based indexed cues with comma milliseconds', () {
      final srt = serializeSrt([
        _line('Hello world', 1000, 2500),
        _line('Second cue', 4000, 1500),
      ]);
      expect(
        srt,
        '1\n'
        '00:00:01,000 --> 00:00:03,500\n'
        'Hello world\n'
        '\n'
        '2\n'
        '00:00:04,000 --> 00:00:05,500\n'
        'Second cue\n'
        '\n',
      );
    });

    test('pads hours beyond one', () {
      final srt = serializeSrt([_line('Late', 3602003, 1000)]);
      expect(srt, contains('01:00:02,003 --> 01:00:03,003'));
    });

    test('keeps multi-line cue text', () {
      final srt = serializeSrt([_line('Hello\nworld', 0, 1000)]);
      expect(srt, contains('Hello\nworld\n'));
    });

    test('skips blank-text and non-positive-duration cues', () {
      final srt = serializeSrt([
        _line('   ', 0, 1000),
        _line('Zero', 0, 0),
        _line('Negative', 2000, -5),
        _line('Kept', 0, 1000),
      ]);
      expect(srt, '1\n00:00:00,000 --> 00:00:01,000\nKept\n\n');
      expect(srt, isNot(contains('2')));
    });

    test('serializes an empty list to an empty string', () {
      expect(serializeSrt(const []), '');
    });
  });

  group('serializeVtt', () {
    test('writes the WEBVTT header and dot milliseconds', () {
      final vtt = serializeVtt([_line('Hello', 1000, 2500)]);
      expect(
        vtt,
        'WEBVTT\n\n'
        '00:00:01.000 --> 00:00:03.500\n'
        'Hello\n\n',
      );
    });

    test('pads hours beyond one', () {
      final vtt = serializeVtt([_line('Late', 3602003, 1000)]);
      expect(vtt, contains('01:00:02.003 --> 01:00:03.003'));
    });

    test('serializes an empty list to the bare header', () {
      expect(serializeVtt(const []), 'WEBVTT\n\n');
    });
  });

  group('round trip through the parsers', () {
    final lines = [
      _line('First line', 0, 1500),
      _line('Second line', 1500, 85000),
      _line('Multi\nline cue', 860000, 2000),
      _line('Hour cue', 3600000, 60000),
    ];

    test('SRT serialization parses back to the same cues', () {
      final serialized = serializeSrt(lines);
      expect(const SrtParser().parse(serialized), lines);
    });

    test('VTT serialization parses back to the same cues', () {
      final serialized = serializeVtt(lines);
      expect(const VttParser().parse(serialized), lines);
    });

    test('cue text is trimmed and blank interior lines are dropped', () {
      final serialized = serializeVtt([
        _line('  Padded  \n\n\nafter blank  ', 0, 1000),
      ]);
      expect(serialized, contains('Padded\nafter blank'));
    });

    test('format serialize dispatches to the matching serializer', () {
      final lines = [_line('Hello', 1000, 1000)];
      expect(SubtitleExportFormat.srt.serialize(lines), serializeSrt(lines));
      expect(SubtitleExportFormat.vtt.serialize(lines), serializeVtt(lines));
    });
  });

  group('SubtitleExportFormat metadata', () {
    test('file extensions', () {
      expect(SubtitleExportFormat.srt.fileExtension, 'srt');
      expect(SubtitleExportFormat.vtt.fileExtension, 'vtt');
    });

    test('mime types', () {
      expect(SubtitleExportFormat.srt.mimeType, 'application/x-subrip');
      expect(SubtitleExportFormat.vtt.mimeType, 'text/vtt');
    });
  });
}
