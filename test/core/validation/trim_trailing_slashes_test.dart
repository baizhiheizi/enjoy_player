/// Unit tests for the shared base-URL trailing-slash normalization.
library;

import 'package:enjoy_player/core/validation/trim_trailing_slashes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trimTrailingSlashes', () {
    test('returns a URL without trailing slashes unchanged', () {
      expect(
        trimTrailingSlashes('https://enjoy.bot/api/v1'),
        'https://enjoy.bot/api/v1',
      );
    });

    test('strips a single trailing slash', () {
      expect(trimTrailingSlashes('https://enjoy.bot/'), 'https://enjoy.bot');
    });

    test('strips multiple trailing slashes', () {
      expect(
        trimTrailingSlashes('https://enjoy.bot/api/v1//'),
        'https://enjoy.bot/api/v1',
      );
    });

    test('strips everything when the input is only slashes', () {
      expect(trimTrailingSlashes('///'), '');
    });

    test('does not trim whitespace; callers own that step', () {
      expect(trimTrailingSlashes('https://enjoy.bot/ '), 'https://enjoy.bot/ ');
    });

    test('returns the empty string unchanged', () {
      expect(trimTrailingSlashes(''), '');
    });
  });
}
