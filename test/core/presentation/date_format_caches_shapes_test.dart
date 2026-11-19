import 'package:enjoy_player/core/format/cached_date_format.dart';
import 'package:enjoy_player/core/format/cached_number_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const int _kRowCount = 502;
const int _kWarmupPasses = 200;
const int _kSamples = 30;
const int _kRounds = 3;

const List<String> _kLocales = <String>['en', 'de', 'ja'];

final List<DateTime> _kTimestamps = <DateTime>[
  for (var i = 0; i < _kRowCount; i++)
    DateTime.utc(2024, 1, 15).subtract(Duration(days: i, minutes: i * 37)),
];

int _benchSink = 0;

void _sink(String output) {
  _benchSink += output.length;
}

String _freshTableTime(DateTime at, String localeName) =>
    DateFormat.Hm(localeName).format(at);

String _cachedTableTime(DateTime at, String localeName) =>
    cachedDateFormat('Hm', localeName).format(at);

String _freshTableNumber(num value, String localeName) =>
    NumberFormat.decimalPattern(localeName).format(value);

String _cachedTableNumber(num value, String localeName) =>
    cachedDecimalPattern(localeName).format(value);

String _freshCardTimestamp(DateTime at, String localeName) =>
    DateFormat.yMMMd(localeName).add_jm().format(at);

String _cachedCardTimestamp(DateTime at, String localeName) =>
    cachedDateFormat('yMMMd jm', localeName).format(at);

String _freshLastSyncTime(DateTime at, String locale) =>
    DateFormat.Hm(locale).format(at);

String _cachedLastSyncTime(DateTime at, String locale) =>
    cachedDateFormat('Hm', locale).format(at);

String _freshLastSyncShortDate(DateTime at, String locale) =>
    DateFormat.MMMd(locale).add_Hm().format(at);

String _cachedLastSyncShortDate(DateTime at, String locale) =>
    cachedDateFormat('MMMd Hm', locale).format(at);

String _freshLastSyncYearDate(DateTime at, String locale) =>
    DateFormat.yMMMd(locale).add_Hm().format(at);

String _cachedLastSyncYearDate(DateTime at, String locale) =>
    cachedDateFormat('yMMMd Hm', locale).format(at);

String _freshHomeOverline(DateTime at, String locale) =>
    DateFormat.MMMMEEEEd(locale).format(at);

String _cachedHomeOverline(DateTime at, String locale) =>
    cachedDateFormat('MMMMEEEEd', locale).format(at);

int _mismatchesAcross(
  String Function(DateTime, String) fresh,
  String Function(DateTime, String) cached,
  List<DateTime> timestamps,
) {
  var mismatches = 0;
  for (final locale in _kLocales) {
    for (final at in timestamps) {
      if (fresh(at, locale) != cached(at, locale)) mismatches++;
    }
  }
  return mismatches;
}

void _expectStable(String Function() format) {
  final first = format();
  for (var i = 0; i < 5; i++) {
    expect(format(), first);
  }
}

List<double> _benchRounds(void Function() pass, String tag) {
  final medians = <double>[];
  for (var round = 0; round < _kRounds; round++) {
    for (var i = 0; i < _kWarmupPasses; i++) {
      pass();
    }
    final samples = <double>[];
    for (var i = 0; i < _kSamples; i++) {
      final sw = Stopwatch()..start();
      pass();
      sw.stop();
      samples.add(sw.elapsedMicroseconds / 1000);
    }
    samples.sort();
    medians.add(samples[samples.length ~/ 2]);
  }
  // ignore: avoid_print
  print(
    '$tag rounds: ${medians.map((m) => m.toStringAsFixed(3)).join(' / ')} '
    'ms/pass (sink=$_benchSink)',
  );
  return medians;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'en';
  });

  group('once-per-locale formatter caches match fresh construction', () {
    test('usage table time cell (Hm)', () {
      expect(
        _mismatchesAcross(_freshTableTime, _cachedTableTime, _kTimestamps),
        0,
      );
    });

    test('usage table number cell (decimalPattern)', () {
      var mismatches = 0;
      for (final locale in _kLocales) {
        for (var i = 0; i < _kRowCount; i++) {
          final value = 1000 + i * 7;
          if (_freshTableNumber(value, locale) !=
              _cachedTableNumber(value, locale)) {
            mismatches++;
          }
        }
      }
      expect(mismatches, 0);
    });

    test('usage log card timestamp (yMMMd + jm)', () {
      expect(
        _mismatchesAcross(
          _freshCardTimestamp,
          _cachedCardTimestamp,
          _kTimestamps,
        ),
        0,
      );
    });

    test('last-sync time (Hm)', () {
      expect(
        _mismatchesAcross(
          _freshLastSyncTime,
          _cachedLastSyncTime,
          _kTimestamps,
        ),
        0,
      );
    });

    test('last-sync same-year date (MMMd + Hm)', () {
      final thisYear = <DateTime>[
        for (var i = 0; i < _kRowCount; i++)
          DateTime.now().subtract(Duration(days: i % 300, minutes: i)),
      ];
      expect(
        _mismatchesAcross(
          _freshLastSyncShortDate,
          _cachedLastSyncShortDate,
          thisYear,
        ),
        0,
      );
    });

    test('last-sync older date (yMMMd + Hm)', () {
      expect(
        _mismatchesAcross(
          _freshLastSyncYearDate,
          _cachedLastSyncYearDate,
          _kTimestamps,
        ),
        0,
      );
    });

    test('home overline (MMMMEEEEd)', () {
      expect(
        _mismatchesAcross(
          _freshHomeOverline,
          _cachedHomeOverline,
          _kTimestamps,
        ),
        0,
      );
    });

    test('repeated cached formats stay stable (no add-pattern mutation)', () {
      final at = _kTimestamps.first;
      for (final locale in _kLocales) {
        _expectStable(() => _cachedCardTimestamp(at, locale));
        _expectStable(() => _cachedLastSyncTime(at, locale));
        _expectStable(() => _cachedLastSyncShortDate(at, locale));
        _expectStable(() => _cachedLastSyncYearDate(at, locale));
        _expectStable(() => _cachedHomeOverline(at, locale));
      }
      _expectStable(() => _cachedTableTime(at, 'en'));
      _expectStable(() => _cachedTableNumber(12345, 'en'));
    });
  });

  test('per-locale cache keys keep distinct labels', () {
    final at = DateTime(2024, 3, 15, 8, 30);
    final stamps = <String, String>{
      for (final locale in _kLocales) locale: _cachedCardTimestamp(at, locale),
    };
    expect(stamps['en'], isNot(stamps['de']));
    expect(stamps['en'], isNot(stamps['ja']));
    expect(stamps['de'], isNot(stamps['ja']));
    final numbers = <String, String>{
      for (final locale in _kLocales) locale: _cachedTableNumber(12345, locale),
    };
    expect(numbers['en'], isNot(numbers['de']));
    for (final locale in _kLocales) {
      expect(
        numbers[locale],
        NumberFormat.decimalPattern(locale).format(12345),
      );
    }
    expect(_cachedHomeOverline(at, 'ja'), _freshHomeOverline(at, 'ja'));
  });

  test('bench (local only): usage card timestamp fresh DateFormat per row', () {
    final medians = _benchRounds(() {
      for (final at in _kTimestamps) {
        _sink(_freshCardTimestamp(at, 'en'));
      }
    }, 'card timestamp fresh');
    expect(medians.last, lessThan(120));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): usage card timestamp cached formatter', () {
    final medians = _benchRounds(() {
      for (final at in _kTimestamps) {
        _sink(_cachedCardTimestamp(at, 'en'));
      }
    }, 'card timestamp cached');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): usage table fresh formatters per build', () {
    final medians = _benchRounds(() {
      for (var build = 0; build < 25; build++) {
        final tf = DateFormat.Hm('en');
        final number = NumberFormat.decimalPattern('en');
        for (final at in _kTimestamps.take(50)) {
          _sink(tf.format(at));
          _sink(number.format(1000 + build));
        }
      }
    }, 'table fresh');
    expect(medians.last, lessThan(120));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): usage table cached formatters per build', () {
    final medians = _benchRounds(() {
      for (var build = 0; build < 25; build++) {
        final tf = cachedDateFormat('Hm', 'en');
        final number = cachedDecimalPattern('en');
        for (final at in _kTimestamps.take(50)) {
          _sink(tf.format(at));
          _sink(number.format(1000 + build));
        }
      }
    }, 'table cached');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
