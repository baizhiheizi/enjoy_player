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

  test(
    'cachedSimpleCurrency returns identical instance per locale+name key',
    () {
      final a = cachedSimpleCurrency(name: 'USD');
      final b = cachedSimpleCurrency(name: 'USD');
      final c = cachedSimpleCurrency(name: 'EUR');
      final d = cachedSimpleCurrency(locale: 'de', name: 'USD');

      expect(identical(a, b), isTrue);
      expect(identical(a, c), isFalse);
      expect(identical(a, d), isFalse);
      expect(
        a.format(12.5),
        NumberFormat.simpleCurrency(name: 'USD').format(12.5),
      );
      expect(
        cachedSimpleCurrency(locale: 'de', name: 'USD').format(12345.6),
        NumberFormat.simpleCurrency(locale: 'de', name: 'USD').format(12345.6),
      );
    },
  );

  test('cachedSimpleCurrency canonicalizes the locale key', () {
    expect(
      identical(
        cachedSimpleCurrency(locale: 'zh-CN', name: 'USD'),
        cachedSimpleCurrency(locale: 'zh_CN', name: 'USD'),
      ),
      isTrue,
    );
  });

  test('cachedSimpleCurrency keeps name-distinct labels apart', () {
    final usd = cachedSimpleCurrency(name: 'USD');
    final eur = cachedSimpleCurrency(name: 'EUR');
    expect(usd.format(100), isNot(eur.format(100)));
    expect(
      usd.format(100),
      NumberFormat.simpleCurrency(name: 'USD').format(100),
    );
    expect(
      eur.format(100),
      NumberFormat.simpleCurrency(name: 'EUR').format(100),
    );
  });
}
