import 'package:enjoy_player/core/format/cached_number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cachedDecimalPattern returns identical instance per locale key', () {
    final a = cachedDecimalPattern('en');
    final b = cachedDecimalPattern('en');
    final c = cachedDecimalPattern('zh_CN');

    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
    expect(a.format(12345), '12,345');
  });

  test('cachedNumberFormat returns identical instance per pattern+locale', () {
    final a = cachedNumberFormat('0.00', 'en');
    final b = cachedNumberFormat('0.00', 'en');
    final c = cachedNumberFormat('0.0', 'en');

    expect(identical(a, b), isTrue);
    expect(identical(a, c), isFalse);
    expect(a.format(12.5), '12.50');
  });
}
