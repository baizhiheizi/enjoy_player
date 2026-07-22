import 'package:enjoy_player/data/subtitle/subtitle_markup_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSubtitleMarkup - empty and trivial input', () {
    test('returns empty list for empty string', () {
      expect(parseSubtitleMarkup(''), isEmpty);
    });

    test('returns single segment for plain text without markup', () {
      final segs = parseSubtitleMarkup('Hello world');
      expect(segs.length, 1);
      expect(segs[0].text, 'Hello world');
      expect(segs[0].colorArgb, isNull);
      expect(segs[0].bold, isFalse);
      expect(segs[0].italic, isFalse);
      expect(segs[0].underline, isFalse);
    });
  });

  group('parseSubtitleMarkup - br tag', () {
    test('converts <br> to newline', () {
      final segs = parseSubtitleMarkup('Line1<br>Line2');
      expect(segs.length, 1);
      expect(segs[0].text, 'Line1\nLine2');
    });

    test('treats <br/> as unknown tag (br/ token) and strips it', () {
      // The parser splits on whitespace; "br/" != "br", so it's unknown.
      final segs = parseSubtitleMarkup('A<br/>B');
      expect(segs.length, 1);
      expect(segs[0].text, 'AB');
    });

    test('converts <BR> case-insensitively', () {
      final segs = parseSubtitleMarkup('X<BR>Y');
      expect(segs.length, 1);
      expect(segs[0].text, 'X\nY');
    });
  });

  group('parseSubtitleMarkup - bold tags', () {
    test('handles <b> tag', () {
      final segs = parseSubtitleMarkup('<b>Bold</b>');
      expect(segs.length, 1);
      expect(segs[0].text, 'Bold');
      expect(segs[0].bold, isTrue);
    });

    test('handles <strong> tag', () {
      final segs = parseSubtitleMarkup('<strong>Strong</strong>');
      expect(segs.length, 1);
      expect(segs[0].text, 'Strong');
      expect(segs[0].bold, isTrue);
    });

    test('bold does not leak after closing tag', () {
      final segs = parseSubtitleMarkup('<b>Bold</b> Normal');
      expect(segs.length, 2);
      expect(segs[0].text, 'Bold');
      expect(segs[0].bold, isTrue);
      expect(segs[1].text, ' Normal');
      expect(segs[1].bold, isFalse);
    });
  });

  group('parseSubtitleMarkup - italic tags', () {
    test('handles <i> tag', () {
      final segs = parseSubtitleMarkup('<i>Italic</i>');
      expect(segs.length, 1);
      expect(segs[0].text, 'Italic');
      expect(segs[0].italic, isTrue);
    });

    test('handles <em> tag', () {
      final segs = parseSubtitleMarkup('<em>Emphasis</em>');
      expect(segs.length, 1);
      expect(segs[0].text, 'Emphasis');
      expect(segs[0].italic, isTrue);
    });

    test('italic does not leak after closing tag', () {
      final segs = parseSubtitleMarkup('<i>Italic</i> Plain');
      expect(segs.length, 2);
      expect(segs[0].italic, isTrue);
      expect(segs[1].text, ' Plain');
      expect(segs[1].italic, isFalse);
    });
  });

  group('parseSubtitleMarkup - underline tag', () {
    test('handles <u> tag', () {
      final segs = parseSubtitleMarkup('<u>Underlined</u>');
      expect(segs.length, 1);
      expect(segs[0].text, 'Underlined');
      expect(segs[0].underline, isTrue);
    });

    test('underline does not leak after closing tag', () {
      final segs = parseSubtitleMarkup('<u>Under</u> Normal');
      expect(segs.length, 2);
      expect(segs[0].underline, isTrue);
      expect(segs[1].text, ' Normal');
      expect(segs[1].underline, isFalse);
    });
  });

  group('parseSubtitleMarkup - nested styles', () {
    test('nested bold + italic + underline', () {
      final segs = parseSubtitleMarkup('<b><i><u>All</u></i></b>');
      expect(segs.length, 1);
      expect(segs[0].text, 'All');
      expect(segs[0].bold, isTrue);
      expect(segs[0].italic, isTrue);
      expect(segs[0].underline, isTrue);
    });

    test('font color inherited by nested bold', () {
      final segs = parseSubtitleMarkup(
        '<font color="red"><b>Red Bold</b></font>',
      );
      expect(segs.length, 1);
      expect(segs[0].text, 'Red Bold');
      expect(segs[0].colorArgb, 0xFFFF0000);
      expect(segs[0].bold, isTrue);
    });
  });

  group('parseSubtitleMarkup - unknown tags stripped', () {
    test('unknown opening tag is stripped, inner text kept', () {
      final segs = parseSubtitleMarkup('<span>Text</span>');
      expect(segs.length, 1);
      expect(segs[0].text, 'Text');
      expect(segs[0].bold, isFalse);
    });

    test('unknown self-closing tag is stripped', () {
      final segs = parseSubtitleMarkup('Before<hr/>After');
      expect(segs.length, 1);
      expect(segs[0].text, 'BeforeAfter');
    });
  });

  group('parseSubtitleMarkup - malformed input', () {
    test('unclosed < without > is treated as literal', () {
      final segs = parseSubtitleMarkup('Hello < world');
      expect(segs.length, 1);
      expect(segs[0].text, 'Hello < world');
    });

    test('empty tag <> is ignored', () {
      final segs = parseSubtitleMarkup('A<>B');
      expect(segs.length, 1);
      expect(segs[0].text, 'AB');
    });

    test('closing tag with empty stack does not crash', () {
      // Stack starts with 1 element; extra closing tags should not pop below 1.
      final segs = parseSubtitleMarkup('</b></i></u></font>Text');
      expect(segs.length, 1);
      expect(segs[0].text, 'Text');
      expect(segs[0].bold, isFalse);
    });

    test('closing unknown tag does not pop stack', () {
      final segs = parseSubtitleMarkup('<b>Bold</span>Still</b>');
      // </span> is unknown so it should not pop the bold frame
      expect(segs.length, 1);
      expect(segs[0].text, 'BoldStill');
      expect(segs[0].bold, isTrue);
    });
  });

  group('parseSubtitleMarkup - HTML entities', () {
    test('decodes &amp;', () {
      final segs = parseSubtitleMarkup('A&amp;B');
      expect(segs[0].text, 'A&B');
    });

    test('decodes &lt; and &gt;', () {
      final segs = parseSubtitleMarkup('&lt;tag&gt;');
      expect(segs[0].text, '<tag>');
    });

    test('decodes &quot; and &apos;', () {
      final segs = parseSubtitleMarkup('&quot;hi&apos;');
      expect(segs[0].text, '"hi\'');
    });

    test('decodes hex numeric entity &#x41;', () {
      final segs = parseSubtitleMarkup('&#x41;');
      expect(segs[0].text, 'A');
    });

    test('decodes hex numeric entity with lowercase &#x61;', () {
      final segs = parseSubtitleMarkup('&#x61;');
      expect(segs[0].text, 'a');
    });

    test('decodes decimal numeric entity &#65;', () {
      final segs = parseSubtitleMarkup('&#65;');
      expect(segs[0].text, 'A');
    });

    test('invalid hex entity returned as-is', () {
      final segs = parseSubtitleMarkup('&#xZZ;');
      expect(segs[0].text, '&#xZZ;');
    });

    test('invalid decimal entity returned as-is', () {
      final segs = parseSubtitleMarkup('&#abc;');
      expect(segs[0].text, '&#abc;');
    });

    test('unknown named entity returned as-is', () {
      final segs = parseSubtitleMarkup('&nbsp;');
      expect(segs[0].text, '&nbsp;');
    });

    test('ampersand without semicolon is literal', () {
      final segs = parseSubtitleMarkup('A & B');
      expect(segs[0].text, 'A & B');
    });

    test('ampersand at end of string is literal', () {
      final segs = parseSubtitleMarkup('end&');
      expect(segs[0].text, 'end&');
    });
  });

  group('parseSubtitleMarkup - font color attribute', () {
    test('font without color attribute inherits parent color', () {
      final segs = parseSubtitleMarkup(
        '<font color="blue"><font size="3">Text</font></font>',
      );
      expect(segs.length, 1);
      expect(segs[0].text, 'Text');
      expect(segs[0].colorArgb, 0xFF0000FF);
    });

    test('font with single-quoted color', () {
      final segs = parseSubtitleMarkup("<font color='red'>Hi</font>");
      expect(segs[0].text, 'Hi');
      expect(segs[0].colorArgb, 0xFFFF0000);
    });
  });

  group('parseSubtitleMarkup - merging adjacent same-style segments', () {
    test('adjacent segments with same style are merged', () {
      // Two bold segments separated by a zero-width style change should merge.
      final segs = parseSubtitleMarkup('<b>A</b><b>B</b>');
      expect(segs.length, 1);
      expect(segs[0].text, 'AB');
      expect(segs[0].bold, isTrue);
    });

    test('adjacent segments with different styles are not merged', () {
      final segs = parseSubtitleMarkup('<b>Bold</b><i>Italic</i>');
      expect(segs.length, 2);
      expect(segs[0].text, 'Bold');
      expect(segs[0].bold, isTrue);
      expect(segs[1].text, 'Italic');
      expect(segs[1].italic, isTrue);
    });
  });

  group('parseSubtitleColorToArgb', () {
    test('parses 6-digit hex with #', () {
      expect(parseSubtitleColorToArgb('#FF8800'), 0xFFFF8800);
    });

    test('parses 3-digit shorthand hex', () {
      // #F80 -> #FF8800
      expect(parseSubtitleColorToArgb('#F80'), 0xFFFF8800);
    });

    test('parses 8-digit hex with alpha', () {
      expect(parseSubtitleColorToArgb('#80FF0000'), 0x80FF0000);
    });

    test('returns null for hex with invalid length (4 digits)', () {
      expect(parseSubtitleColorToArgb('#1234'), isNull);
    });

    test('returns null for hex with invalid length (5 digits)', () {
      expect(parseSubtitleColorToArgb('#12345'), isNull);
    });

    test('parses named colors case-insensitively', () {
      expect(parseSubtitleColorToArgb('RED'), 0xFFFF0000);
      expect(parseSubtitleColorToArgb('White'), 0xFFFFFFFF);
      expect(parseSubtitleColorToArgb('blue'), 0xFF0000FF);
    });

    test('parses all named colors', () {
      expect(parseSubtitleColorToArgb('black'), 0xFF000000);
      expect(parseSubtitleColorToArgb('green'), 0xFF008000);
      expect(parseSubtitleColorToArgb('yellow'), 0xFFFFFF00);
      expect(parseSubtitleColorToArgb('cyan'), 0xFF00FFFF);
      expect(parseSubtitleColorToArgb('magenta'), 0xFFFF00FF);
      expect(parseSubtitleColorToArgb('silver'), 0xFFC0C0C0);
      expect(parseSubtitleColorToArgb('gray'), 0xFF808080);
      expect(parseSubtitleColorToArgb('grey'), 0xFF808080);
      expect(parseSubtitleColorToArgb('lime'), 0xFF00FF00);
      expect(parseSubtitleColorToArgb('navy'), 0xFF000080);
      expect(parseSubtitleColorToArgb('teal'), 0xFF008080);
      expect(parseSubtitleColorToArgb('aqua'), 0xFF00FFFF);
      expect(parseSubtitleColorToArgb('maroon'), 0xFF800000);
      expect(parseSubtitleColorToArgb('olive'), 0xFF808000);
      expect(parseSubtitleColorToArgb('orange'), 0xFFFFA500);
    });

    test('returns null for unknown color name', () {
      expect(parseSubtitleColorToArgb('chartreuse'), isNull);
    });

    test('trims whitespace around color value', () {
      expect(parseSubtitleColorToArgb('  red  '), 0xFFFF0000);
    });
  });

  group('plainTextFromSubtitleMarkup', () {
    test('returns empty string for empty input', () {
      // parseSubtitleMarkup('') returns [], then fallback strips tags from ''
      // giving '', which is empty so returns ''.trim() = ''.
      expect(plainTextFromSubtitleMarkup(''), '');
    });

    test('strips markup and returns plain text', () {
      expect(
        plainTextFromSubtitleMarkup('<b>Hello</b> <i>World</i>'),
        'Hello World',
      );
    });

    test('preserves br as newline in plain text', () {
      expect(plainTextFromSubtitleMarkup('Line1<br>Line2'), 'Line1\nLine2');
    });

    test('fallback returns input.trim() when stripped result is empty', () {
      // '<>' yields empty segments; stripping tags gives ''; plain.isEmpty
      // triggers the branch returning input.trim() = '<>'.
      expect(plainTextFromSubtitleMarkup('<>'), '<>');
    });

    test('fallback returns trimmed input when stripped result is empty', () {
      // Input that produces no segments and stripping tags yields empty:
      // "<br>" actually produces a newline segment. Let's use just whitespace
      // inside tags scenario. Actually, plainTextFromSubtitleMarkup('<>')
      // covers the "plain.isEmpty" branch returning input.trim().
      // For the non-empty plain branch:
      expect(plainTextFromSubtitleMarkup('<x>y</x>'), 'y');
    });
  });

  group('parseSubtitleMarkup - complex real-world inputs', () {
    test('SSA-style font with color and size', () {
      final segs = parseSubtitleMarkup(
        '<font color="#00ff00" size="48">Green text</font>',
      );
      expect(segs.length, 1);
      expect(segs[0].text, 'Green text');
      expect(segs[0].colorArgb, 0xFF00FF00);
    });

    test('multiple styles in one line', () {
      final segs = parseSubtitleMarkup(
        '<font color="white">Normal <b>Bold <i>BoldItalic</i></b></font>',
      );
      expect(segs.length, 3);
      expect(segs[0].text, 'Normal ');
      expect(segs[0].colorArgb, 0xFFFFFFFF);
      expect(segs[0].bold, isFalse);

      expect(segs[1].text, 'Bold ');
      expect(segs[1].colorArgb, 0xFFFFFFFF);
      expect(segs[1].bold, isTrue);
      expect(segs[1].italic, isFalse);

      expect(segs[2].text, 'BoldItalic');
      expect(segs[2].colorArgb, 0xFFFFFFFF);
      expect(segs[2].bold, isTrue);
      expect(segs[2].italic, isTrue);
    });

    test('entities inside styled text', () {
      final segs = parseSubtitleMarkup('<b>&lt;bold&gt;</b>');
      expect(segs.length, 1);
      expect(segs[0].text, '<bold>');
      expect(segs[0].bold, isTrue);
    });

    test('color does not leak after font close', () {
      final segs = parseSubtitleMarkup('<font color="red">Red</font> Plain');
      expect(segs.length, 2);
      expect(segs[0].colorArgb, 0xFFFF0000);
      expect(segs[1].text, ' Plain');
      expect(segs[1].colorArgb, isNull);
    });
  });
}
