import 'package:enjoy_player/core/format/cached_number_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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

  test('canonicalizes the locale so tag spellings share one entry', () {
    expect(
      identical(cachedDecimalPattern('zh-CN'), cachedDecimalPattern('zh_CN')),
      isTrue,
    );
    expect(
      identical(
        cachedNumberFormat('0.00', 'zh-CN'),
        cachedNumberFormat('0.00', 'zh_CN'),
      ),
      isTrue,
    );
  });

  test('a canonicalized entry formats like a single-locale construction', () {
    expect(
      cachedDecimalPattern('zh-CN').format(12345),
      NumberFormat.decimalPattern('zh_CN').format(12345),
    );
    expect(
      cachedNumberFormat('0.00', 'zh-CN').format(12.5),
      NumberFormat('0.00', 'zh_CN').format(12.5),
    );
  });
}
