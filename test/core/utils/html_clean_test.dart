import 'package:enjoy_player/core/utils/html_clean.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('htmlDecode', () {
    test('decodes named entities', () {
      expect(htmlDecode('Hello &amp; goodbye'), 'Hello & goodbye');
    });

    test('decodes numeric entities', () {
      expect(htmlDecode('&#39;test&#39;'), "'test'");
    });

    test('decodes hex entities', () {
      expect(htmlDecode('&#x27;test&#x27;'), "'test'");
    });

    test('decodes common HTML entities', () {
      expect(htmlDecode('&lt;b&gt;bold&lt;/b&gt;'), '<b>bold</b>');
      expect(htmlDecode('&quot;quoted&quot;'), '"quoted"');
    });

    test('passes through text without entities', () {
      expect(htmlDecode('plain text'), 'plain text');
    });
  });

  group('stripTags', () {
    test('removes simple HTML tags', () {
      expect(stripTags('<b>bold</b>'), 'bold');
    });

    test('removes self-closing tags', () {
      expect(stripTags('line<br/>break'), 'linebreak');
    });

    test('removes font tags with attributes', () {
      expect(stripTags('<font color="#ffffff">text</font>'), 'text');
    });

    test('passes through text without tags', () {
      expect(stripTags('plain text'), 'plain text');
    });

    test('handles nested tags', () {
      expect(stripTags('<i><b>nested</b></i>'), 'nested');
    });
  });

  group('cleanHtmlText', () {
    test('decodes entities and strips tags', () {
      expect(cleanHtmlText('<b>Hello &amp; goodbye</b>'), 'Hello & goodbye');
    });

    test('trims whitespace', () {
      expect(cleanHtmlText('  <i>  text  </i>  '), 'text');
    });

    test('handles YouTube caption markup', () {
      expect(
        cleanHtmlText(
          '<font color="#E5E5E5">We&#39;re no strangers to love</font>',
        ),
        "We're no strangers to love",
      );
    });

    test('returns empty string for empty input after clean', () {
      expect(cleanHtmlText('<b></b>'), '');
      expect(cleanHtmlText('   '), '');
    });
  });
}
