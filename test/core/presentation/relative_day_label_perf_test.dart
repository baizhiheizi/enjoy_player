import 'package:enjoy_player/core/presentation/relative_day_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const int _kRowCount = 502;
const int _kWarmupPasses = 200;
const int _kSamples = 30;
const int _kRounds = 3;

const List<String> _kLocales = <String>['en', 'de', 'ja'];

final List<DateTime> _kRows = <DateTime>[
  for (var i = 0; i < _kRowCount; i++)
    DateTime(2026, 9, 27).subtract(Duration(days: i, hours: i % 13)),
];

final DateTime _kNow = DateTime(2026, 9, 29, 14, 30);

final Map<String, DateFormat> _craftCacheReplica = <String, DateFormat>{};

String _legacyRelativeDayLabel(
  AppLocalizations l10n,
  String locale,
  DateTime at,
  DateTime now,
) {
  final referenceDay = DateTime.utc(now.year, now.month, now.day);
  final atDay = DateTime.utc(at.year, at.month, at.day);
  final days = referenceDay.difference(atDay).inDays;
  if (days == 0) return l10n.mediaRelativeToday;
  if (days == 1) return l10n.mediaRelativeYesterday;
  return DateFormat.MMMd(locale).format(at);
}

String _freshCraftSubtitle(DateTime at) =>
    DateFormat.yMMMd().add_jm().format(at);

String _cachedCraftSubtitle(DateTime at, String locale) => _craftCacheReplica
    .putIfAbsent(locale, () => DateFormat.yMMMd(locale).add_jm())
    .format(at);

List<double> _benchRounds(String Function(DateTime at) pass, String tag) {
  final medians = <double>[];
  var sink = 0;
  for (var round = 0; round < _kRounds; round++) {
    for (var i = 0; i < _kWarmupPasses; i++) {
      for (final at in _kRows) {
        sink += pass(at).length;
      }
    }
    final samples = <double>[];
    for (var i = 0; i < _kSamples; i++) {
      final sw = Stopwatch()..start();
      for (final at in _kRows) {
        sink += pass(at).length;
      }
      sw.stop();
      samples.add(sw.elapsedMicroseconds / 1000);
    }
    samples.sort();
    medians.add(samples[samples.length ~/ 2]);
  }
  // ignore: avoid_print
  print(
    '$tag rounds: '
    '${medians.map((m) => m.toStringAsFixed(3)).join(' / ')} ms/pass '
    '($_kRowCount rows, sink=$sink)',
  );
  return medians;
}

void main() {
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting();
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('relativeDayLabel matches the fresh short-date derivation', () {
    var mismatches = 0;
    for (final locale in _kLocales) {
      for (final at in _kRows) {
        final fresh = _legacyRelativeDayLabel(en, locale, at, _kNow);
        final cached = relativeDayLabel(en, locale, at, now: _kNow);
        if (fresh != cached) mismatches++;
      }
    }
    expect(mismatches, 0);
  });

  test('per-locale cache keys keep distinct short-date labels', () {
    final at = DateTime(2026, 3, 15, 8);
    final labels = <String, String>{
      for (final locale in _kLocales)
        locale: relativeDayLabel(en, locale, at, now: _kNow),
    };
    expect(labels['en'], isNot(labels['de']));
    expect(labels['en'], isNot(labels['ja']));
    expect(labels['de'], isNot(labels['ja']));
    for (final locale in _kLocales) {
      expect(
        relativeDayLabel(en, locale, at, now: _kNow),
        DateFormat.MMMd(locale).format(at),
      );
    }
  });

  test(
    'the craft subtitle shape stays identical through a cached formatter',
    () {
      final rows = <DateTime>[
        for (var i = 0; i < _kRowCount; i++)
          DateTime(2026, 1, 1).add(Duration(days: i % 365, minutes: i * 7)),
      ];
      var mismatches = 0;
      for (final locale in _kLocales) {
        for (final at in rows) {
          final fresh = DateFormat.yMMMd(locale).add_jm().format(at);
          final cached = _cachedCraftSubtitle(at, locale);
          if (fresh != cached) mismatches++;
        }
      }
      expect(mismatches, 0);
    },
  );

  test('bench (local only): relativeDayLabel fresh DateFormat per row', () {
    final medians = _benchRounds(
      (at) => _legacyRelativeDayLabel(en, 'en', at, _kNow),
      'relativeDayLabel fresh',
    );
    expect(medians.last, lessThan(50));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): relativeDayLabel cached formatter', () {
    final medians = _benchRounds(
      (at) => relativeDayLabel(en, 'en', at, now: _kNow),
      'relativeDayLabel cached',
    );
    expect(medians.last, lessThan(5));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): craft subtitle fresh DateFormat per row', () {
    final medians = _benchRounds(_freshCraftSubtitle, 'craft fresh');
    expect(medians.last, lessThan(50));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): craft subtitle cached formatter', () {
    final medians = _benchRounds(
      (at) => _cachedCraftSubtitle(at, 'en'),
      'craft cached',
    );
    expect(medians.last, lessThan(5));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
