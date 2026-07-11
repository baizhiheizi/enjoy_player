import 'package:enjoy_player/core/validation/byok_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeByokBaseUrl', () {
    test('strips a single trailing slash', () {
      expect(
        normalizeByokBaseUrl('https://api.openai.com/v1/'),
        'https://api.openai.com/v1',
      );
    });

    test('strips multiple trailing slashes', () {
      expect(
        normalizeByokBaseUrl('https://api.openai.com/v1///'),
        'https://api.openai.com/v1',
      );
    });

    test('trims whitespace before stripping slashes', () {
      expect(
        normalizeByokBaseUrl('  https://api.openai.com/v1/  '),
        'https://api.openai.com/v1',
      );
    });

    test('returns the input unchanged when there is no trailing slash', () {
      expect(
        normalizeByokBaseUrl('https://api.openai.com/v1'),
        'https://api.openai.com/v1',
      );
    });
  });
}
