/// Bounded process-level memoization for hot-path `NumberFormat` instances.
library;

import 'package:intl/intl.dart';

final Map<String, NumberFormat> _decimalPatternCache = <String, NumberFormat>{};
final Map<String, NumberFormat> _patternCache = <String, NumberFormat>{};

NumberFormat cachedDecimalPattern([String? locale]) {
  final key = locale ?? Intl.getCurrentLocale();
  return _decimalPatternCache.putIfAbsent(
    key,
    () => NumberFormat.decimalPattern(locale),
  );
}

NumberFormat cachedNumberFormat(String pattern, [String? locale]) {
  final key = '$pattern\u0000${locale ?? Intl.getCurrentLocale()}';
  return _patternCache.putIfAbsent(key, () => NumberFormat(pattern, locale));
}
