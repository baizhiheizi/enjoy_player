import 'package:intl/intl.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';

/// Compact relative age of a feed entry or refresh: `just now`, `12m ago`,
/// `3h ago`, `yesterday`, `4d ago`, then a short date (`Sep 29`).
String discoverAgeLabel(
  AppLocalizations l10n,
  String locale,
  DateTime at, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final local = at.toLocal();
  final diff = reference.difference(local);
  if (diff.inMinutes < 1) return l10n.discoverJustNow;
  if (diff.inHours < 1) return l10n.discoverMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.discoverHoursAgo(diff.inHours);
  if (diff.inDays < 2) return l10n.mediaRelativeYesterday;
  if (diff.inDays < 7) return l10n.discoverDaysAgo(diff.inDays);
  final formats = _formatCache.putIfAbsent(
    locale,
    () => (DateFormat.MMMd(locale), DateFormat.yMMMd(locale)),
  );
  return local.year == reference.year
      ? formats.$1.format(local)
      : formats.$2.format(local);
}

final Map<String, (DateFormat, DateFormat)> _formatCache = {};
