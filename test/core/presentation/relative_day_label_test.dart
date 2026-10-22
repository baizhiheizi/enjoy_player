import 'dart:io';

import 'package:enjoy_player/core/presentation/relative_day_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  final springForwardDay = _findSpringForwardDay();
  final requireDstZone = Platform.environment['REQUIRE_DST_TIMEZONE'] == '1';

  group('relativeDayLabel', () {
    test('labels the current calendar day as today', () {
      final now = DateTime(2026, 9, 29, 14, 30);
      expect(
        relativeDayLabel(l10n, 'en', DateTime(2026, 9, 29, 3, 15), now: now),
        l10n.mediaRelativeToday,
      );
    });

    test('labels the previous calendar day as yesterday', () {
      final now = DateTime(2026, 9, 29, 14, 30);
      expect(
        relativeDayLabel(l10n, 'en', DateTime(2026, 9, 28, 23, 59), now: now),
        l10n.mediaRelativeYesterday,
      );
    });

    test('labels two calendar days back with a short date', () {
      final now = DateTime(2026, 9, 29, 14, 30);
      expect(
        relativeDayLabel(l10n, 'en', DateTime(2026, 9, 27, 8), now: now),
        'Sep 27',
      );
    });

    test('labels a future timestamp with a short date', () {
      final now = DateTime(2026, 9, 29, 14, 30);
      expect(
        relativeDayLabel(l10n, 'en', DateTime(2026, 9, 30, 8), now: now),
        'Sep 30',
      );
    });

    test('falls back to the current time when now is omitted', () {
      expect(
        relativeDayLabel(l10n, 'en', DateTime.now()),
        l10n.mediaRelativeToday,
      );
    });

    test('labels the previous calendar day as yesterday on a 23-hour day', () {
      final day = springForwardDay;
      if (day == null) {
        if (requireDstZone) {
          fail(
            'REQUIRE_DST_TIMEZONE=1 but the local time zone has no daylight '
            'saving transition',
          );
        }
        markTestSkipped(
          'the local time zone has no daylight saving transition',
        );
        return;
      }

      final nextDay = DateTime(day.year, day.month, day.day + 1);

      expect(
        relativeDayLabel(l10n, 'en', day, now: nextDay),
        l10n.mediaRelativeYesterday,
      );
      expect(
        relativeDayLabel(
          l10n,
          'en',
          day,
          now: DateTime(nextDay.year, nextDay.month, nextDay.day, 12),
        ),
        l10n.mediaRelativeYesterday,
      );
    });
  });
}

DateTime? _findSpringForwardDay() {
  for (var year = 2024; year <= 2028; year++) {
    var cursor = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    while (!cursor.isAfter(lastDay)) {
      final next = DateTime(cursor.year, cursor.month, cursor.day + 1);
      if (next.difference(cursor) == const Duration(hours: 23)) return cursor;
      cursor = next;
    }
  }
  return null;
}
