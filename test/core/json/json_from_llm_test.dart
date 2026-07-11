import 'package:enjoy_player/core/json/json_from_llm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractJsonObject', () {
    test('returns the trimmed input verbatim when it starts with `{`', () {
      const raw = '{"word":"hi","senses":[]}';
      expect(extractJsonObject(raw), raw);
    });

    test('strips a single ```json fenced block', () {
      const raw = '```json\n{"word":"hi","senses":[]}\n```';
      expect(extractJsonObject(raw), '{"word":"hi","senses":[]}');
    });

    test('strips an unfenced ``` block', () {
      const raw = '```\n{"word":"hi"}\n```';
      expect(extractJsonObject(raw), '{"word":"hi"}');
    });

    test('falls back to the outermost braces when no fences are present', () {
      const raw = 'Sure! Here you go: {"word":"hi","senses":[]} cheers';
      expect(extractJsonObject(raw), '{"word":"hi","senses":[]}');
    });

    test('throws FormatException when the response is not JSON at all', () {
      expect(() => extractJsonObject('plain text'), throwsFormatException);
    });
  });
}
