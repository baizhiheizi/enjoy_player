import 'package:enjoy_player/core/format/cached_date_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const List<String> _kLocales = <String>['en', 'zh_CN', 'de', 'ja'];

final List<DateTime> _kTimestamps = <DateTime>[
  for (var i = 0; i < 40; i++)
    DateTime.utc(2024, 1, 15, 8, 30).subtract(Duration(days: i, minutes: i)),
];

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('cachedDateFormat', () {
    test('returns the identical instance per pattern+locale', () {
      final a = cachedDateFormat('MMMd', 'en');
      final b = cachedDateFormat('MMMd', 'en');
      final c = cachedDateFormat('MMMd', 'de');
      final d = cachedDateFormat('yMMMd', 'en');

      expect(identical(a, b), isTrue);
      expect(identical(a, c), isFalse);
      expect(identical(a, d), isFalse);
    });

    test('canonicalizes the locale so tag spellings share one entry', () {
      final tag = cachedDateFormat('MMMd', 'zh-CN');
      final underscored = cachedDateFormat('MMMd', 'zh_CN');

      expect(identical(tag, underscored), isTrue);
    });

    test('matches a single-skeleton DateFormat constructor', () {
      for (final locale in _kLocales) {
        for (final at in _kTimestamps) {
          expect(
            cachedDateFormat('MMMd', locale).format(at),
            DateFormat.MMMd(locale).format(at),
          );
          expect(
            cachedDateFormat('Hm', locale).format(at),
            DateFormat.Hm(locale).format(at),
          );
          expect(
            cachedDateFormat('MMMMEEEEd', locale).format(at),
            DateFormat.MMMMEEEEd(locale).format(at),
          );
          expect(
            cachedDateFormat('yMMMMd', locale).format(at),
            DateFormat.yMMMMd(locale).format(at),
          );
        }
      }
    });

    test('matches a composed DateFormat constructor', () {
      for (final locale in _kLocales) {
        for (final at in _kTimestamps) {
          expect(
            cachedDateFormat('yMMMd jm', locale).format(at),
            DateFormat.yMMMd(locale).add_jm().format(at),
          );
          expect(
            cachedDateFormat('MMMd Hm', locale).format(at),
            DateFormat.MMMd(locale).add_Hm().format(at),
          );
          expect(
            cachedDateFormat('yMMMd Hm', locale).format(at),
            DateFormat.yMMMd(locale).add_Hm().format(at),
          );
          expect(
            cachedDateFormat('jm MEd', locale).format(at),
            DateFormat.jm(locale).add_MEd().format(at),
          );
        }
      }
    });

    test('keeps per-locale output distinct', () {
      final at = DateTime(2024, 3, 15, 8, 30);
      final stamps = <String, String>{
        for (final locale in _kLocales)
          locale: cachedDateFormat('yMMMd jm', locale).format(at),
      };

      expect(stamps['en'], isNot(stamps['de']));
      expect(stamps['en'], isNot(stamps['ja']));
      expect(stamps['de'], isNot(stamps['ja']));
    });

    test('falls back to the intl default locale when none is given', () {
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);
      Intl.defaultLocale = 'en';

      expect(
        cachedDateFormat('Hm').format(_kTimestamps.first),
        DateFormat.Hm().format(_kTimestamps.first),
      );
    });
  });
}
