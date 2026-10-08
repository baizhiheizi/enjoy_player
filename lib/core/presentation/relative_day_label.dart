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
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(at.year, at.month, at.day);
  final days = today.difference(day).inDays;
  if (days == 0) return l10n.mediaRelativeToday;
  if (days == 1) return l10n.mediaRelativeYesterday;
  return DateFormat.MMMd(locale).format(at);
}
