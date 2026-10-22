import 'package:intl/intl.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

/// `today`, `yesterday`, else a short date (`Sep 29`) in [locale].
String relativeDayLabel(
  AppLocalizations l10n,
  String locale,
  DateTime at, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final days = _calendarDaysBefore(reference, at);
  if (days == 0) return l10n.mediaRelativeToday;
  if (days == 1) return l10n.mediaRelativeYesterday;
  return DateFormat.MMMd(locale).format(at);
}

/// Calendar days between two local calendar dates, counted between UTC
/// midnights so a DST transition cannot shorten a day to 23 hours.
int _calendarDaysBefore(DateTime reference, DateTime at) {
  final referenceDay = DateTime.utc(
    reference.year,
    reference.month,
    reference.day,
  );
  final atDay = DateTime.utc(at.year, at.month, at.day);
  return referenceDay.difference(atDay).inDays;
}
