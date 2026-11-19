/// Bounded process-level memoization for hot-path `DateFormat` instances.
library;

import 'package:intl/intl.dart';

final Map<String, DateFormat> _dateFormatCache = <String, DateFormat>{};

/// The memoized [DateFormat] for [pattern] in [locale].
///
/// [pattern] is a space-separated list of CLDR skeletons; every part resolves
/// through the locale's preferred pattern, so `'yMMMd jm'` renders exactly
/// like `DateFormat.yMMMd(locale).add_jm()`. A null [locale] resolves to
/// [Intl.getCurrentLocale].
DateFormat cachedDateFormat(String pattern, [String? locale]) {
  final resolved = locale ?? Intl.getCurrentLocale();
  final key = '$pattern\u0000${Intl.canonicalizedLocale(resolved)}';
  return _dateFormatCache.putIfAbsent(key, () => _build(pattern, resolved));
}

DateFormat _build(String pattern, String locale) {
  final parts = pattern.split(' ');
  final format = DateFormat(parts.first, locale);
  for (final part in parts.skip(1)) {
    format.addPattern(part);
  }
  return format;
}
