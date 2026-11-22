/// Bounded process-level memoization for hot-path `NumberFormat` instances.
library;

import 'package:intl/intl.dart';

final Map<String, NumberFormat> _decimalPatternCache = <String, NumberFormat>{};
final Map<String, NumberFormat> _patternCache = <String, NumberFormat>{};

NumberFormat cachedDecimalPattern([String? locale]) {
  final key = Intl.canonicalizedLocale(locale);
  return _decimalPatternCache.putIfAbsent(
    key,
    () => NumberFormat.decimalPattern(locale),
  );
}

NumberFormat cachedNumberFormat(String pattern, [String? locale]) {
  final key = '$pattern\u0000${Intl.canonicalizedLocale(locale)}';
  return _patternCache.putIfAbsent(key, () => NumberFormat(pattern, locale));
}

/// The memoized [NumberFormat.simpleCurrency] for [name] in [locale].
///
/// [name] defaults to the locale's default currency and [decimalDigits] to
/// the currency's own precision. A null [locale] resolves to
/// [Intl.getCurrentLocale].
NumberFormat cachedSimpleCurrency({
  String? locale,
  String? name,
  int? decimalDigits,
}) {
  final key =
      'simpleCurrency\u0000${name ?? '<locale default>'}\u0000'
      '${decimalDigits ?? '<currency default>'}\u0000'
      '${Intl.canonicalizedLocale(locale)}';
  return _patternCache.putIfAbsent(
    key,
    () => NumberFormat.simpleCurrency(
      locale: locale,
      name: name,
      decimalDigits: decimalDigits,
    ),
  );
}
