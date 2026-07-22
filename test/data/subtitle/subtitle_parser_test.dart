import 'package:enjoy_player/data/subtitle/subtitle_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SrtParser', () {
    test('parses simple cue', () {
      const srt = '''
1
00:00:01,000 --> 00:00:03,500
Hello world

''';
      final lines = const SrtParser().parse(srt);
      expect(lines, hasLength(1));
      expect(lines.first.text, 'Hello world');
      expect(lines.first.startMs, 1000);
      expect(lines.first.durationMs, 2500);
    });

    test('skips zero-duration cues', () {
      const srt = '''
1
00:00:00,000 --> 00:00:00,000
Zero length

2
00:00:01,000 --> 00:00:02,000
Valid

''';
      final lines = const SrtParser().parse(srt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Valid');
    });

    test('ignores malformed timestamp lines', () {
      const srt = '''
1
not-a-timestamp
Still here

2
00:00:01,000 --> 00:00:02,000
Valid

''';
      final lines = const SrtParser().parse(srt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Valid');
    });

    test('returns empty list for garbage input', () {
      expect(const SrtParser().parse('@@@\n###\n'), isEmpty);
    });
  });

  group('VttParser', () {
    test('parses WEBVTT with cue', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:02.000
Hello

''';
      final lines = const VttParser().parse(vtt);
      expect(lines, hasLength(1));
      expect(lines.first.text, 'Hello');
      expect(lines.first.startMs, 1000);
      expect(lines.first.durationMs, 1000);
    });

    test('parses cue identifier before the timestamp', () {
      const vtt = '''
WEBVTT

intro
00:00:01.000 --> 00:00:02.000
Hello

''';
      final lines = const VttParser().parse(vtt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Hello');
    });

    test('skips NOTE blocks', () {
      const vtt = '''
WEBVTT

NOTE
This is a comment
 spanning lines

00:00:01.000 --> 00:00:02.000
After note

''';
      final lines = const VttParser().parse(vtt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'After note');
    });

    test('skips zero-duration cues', () {
      const vtt = '''
WEBVTT

00:00:00.000 --> 00:00:00.000
Zero

00:00:01.000 --> 00:00:02.000
Valid

''';
      final lines = const VttParser().parse(vtt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'Valid');
    });

    test('strips inline HTML-like tags', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:02.000
<c.bold>Bold</c> plain

''';
      final lines = const VttParser().parse(vtt);
      expect(lines.single.text, 'Bold plain');
    });
  });

  group('SubtitleParserFacade', () {
    test('routes by filename extension', () {
      const facade = SubtitleParserFacade();
      const srt = '''
1
00:00:01,000 --> 00:00:02,000
From SRT

''';
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:02.000
From VTT

''';
      expect(
        facade.parseWithHint(srt, fileName: 'clip.srt').single.text,
        'From SRT',
      );
      expect(
        facade.parseWithHint(vtt, fileName: 'clip.vtt').single.text,
        'From VTT',
      );
    });
  });

  test('BOM and CRLF in SRT', () {
    const srt = '\uFEFF1\r\n00:00:00,000 --> 00:00:01,000\r\nA\r\n\r\n';
    final lines = const SrtParser().parse(srt);
    expect(lines.single.text, 'A');
  });

  test('BOM in WebVTT', () {
    const vtt =
        '\uFEFFWEBVTT\r\n\r\n00:00:00.000 --> 00:00:01.000\r\nB\r\n\r\n';
    final lines = const VttParser().parse(vtt);
    expect(lines.single.text, 'B');
  });

  group('SrtParser multi-line cues', () {
    test('joins multiple text lines with newline', () {
      const srt = '''
1
00:00:01,000 --> 00:00:03,000
First line
Second line

''';
      final lines = const SrtParser().parse(srt);
      expect(lines.single.text, 'First line\nSecond line');
    });

    test('sorts cues by start time', () {
      const srt = '''
1
00:00:05,000 --> 00:00:06,000
Later

2
00:00:01,000 --> 00:00:02,000
Earlier

''';
      final lines = const SrtParser().parse(srt);
      expect(lines[0].text, 'Earlier');
      expect(lines[1].text, 'Later');
    });

    test('handles CRLF line endings', () {
      const srt = '1\r\n00:00:01,000 --> 00:00:02,000\r\nHello\r\n\r\n';
      final lines = const SrtParser().parse(srt);
      expect(lines.single.text, 'Hello');
    });
  });

  group('VttParser additional cases', () {
    test('skips STYLE blocks', () {
      const vtt = '''
WEBVTT

STYLE
::cue { color: white; }

00:00:01.000 --> 00:00:02.000
After style

''';
      final lines = const VttParser().parse(vtt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'After style');
    });

    test('skips REGION blocks', () {
      const vtt = '''
WEBVTT

REGION
id:fred
width:40%

00:00:01.000 --> 00:00:02.000
After region

''';
      final lines = const VttParser().parse(vtt);
      expect(lines, hasLength(1));
      expect(lines.single.text, 'After region');
    });

    test('parses timestamps without hours', () {
      const vtt = '''
WEBVTT

01:30.000 --> 02:00.000
No hours

''';
      final lines = const VttParser().parse(vtt);
      expect(lines.single.startMs, 90000);
      expect(lines.single.durationMs, 30000);
    });

    test('sorts cues by start time', () {
      const vtt = '''
WEBVTT

00:00:05.000 --> 00:00:06.000
Later

00:00:01.000 --> 00:00:02.000
Earlier

''';
      final lines = const VttParser().parse(vtt);
      expect(lines[0].text, 'Earlier');
      expect(lines[1].text, 'Later');
    });

    test('handles multi-line cue text', () {
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:03.000
Line one
Line two

''';
      final lines = const VttParser().parse(vtt);
      expect(lines.single.text, 'Line one\nLine two');
    });
  });

  group('SubtitleParserFacade content sniffing', () {
    test('detects VTT by content when no filename', () {
      const facade = SubtitleParserFacade();
      const vtt = '''
WEBVTT

00:00:01.000 --> 00:00:02.000
Sniffed VTT

''';
      final lines = facade.parse(vtt);
      expect(lines.single.text, 'Sniffed VTT');
    });

    test('defaults to SRT for unknown content', () {
      const facade = SubtitleParserFacade();
      const srt = '''
1
00:00:01,000 --> 00:00:02,000
Default SRT

''';
      final lines = facade.parseWithHint(srt, fileName: 'sub.txt');
      expect(lines.single.text, 'Default SRT');
    });
  });

  group('stripAssTags', () {
    test('removes ASS override tags', () {
      expect(
        SubtitleParserFacade.stripAssTags(r'{\an8}Hello {\c&H00FFFF&}world'),
        'Hello world',
      );
    });

    test('returns plain text unchanged', () {
      expect(SubtitleParserFacade.stripAssTags('No tags here'), 'No tags here');
    });

    test('handles empty string', () {
      expect(SubtitleParserFacade.stripAssTags(''), '');
    });
  });
}
