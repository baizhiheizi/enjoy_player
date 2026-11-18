import 'package:enjoy_player/core/format/cached_number_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const int _kRowCount = 502;
const int _kWarmupPasses = 200;
const int _kSamples = 30;
const int _kRounds = 3;

const List<String> _kLocales = <String>['en', 'de', 'ja'];

final List<DateTime> _kPeriodEnds = <DateTime>[
  for (var i = 0; i < _kRowCount; i++)
    DateTime.utc(2026, 8, 1).subtract(Duration(days: i, minutes: i * 61)),
];

int _benchSink = 0;

void _sink(String output) {
  _benchSink += output.length;
}

final Map<String, DateFormat> _statusDateReplica = <String, DateFormat>{};

String _freshStatusDate(DateTime at, String locale) =>
    DateFormat.yMMMMd(locale).format(at);

String _cachedStatusDate(DateTime at, String locale) => _statusDateReplica
    .putIfAbsent(locale, () => DateFormat.yMMMMd(locale))
    .format(at);

String _freshCreditsNumber(num value) =>
    NumberFormat.decimalPattern().format(value);

String _cachedCreditsNumber(num value) => cachedDecimalPattern().format(value);

int _dateMismatches(List<DateTime> timestamps) {
  var mismatches = 0;
  for (final locale in _kLocales) {
    for (final at in timestamps) {
      if (_freshStatusDate(at, locale) != _cachedStatusDate(at, locale)) {
        mismatches++;
      }
    }
  }
  return mismatches;
}

int _numberMismatches() {
  var mismatches = 0;
  for (var i = 0; i < _kRowCount; i++) {
    final value = 1000 + i * 7;
    if (_freshCreditsNumber(value) != _cachedCreditsNumber(value)) {
      mismatches++;
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

  group('subscription status card formatters match fresh construction', () {
    test('membership period date (yMMMMd, per-locale)', () {
      expect(_dateMismatches(_kPeriodEnds), 0);
    });

    test('daily credits number (decimalPattern, intl default locale)', () {
      expect(_numberMismatches(), 0);
    });

    test('explicit-locale cachedDecimalPattern matches fresh construction', () {
      var mismatches = 0;
      for (final locale in _kLocales) {
        for (var i = 0; i < _kRowCount; i++) {
          final value = 1000 + i * 7;
          final fresh = NumberFormat.decimalPattern(locale).format(value);
          if (fresh != cachedDecimalPattern(locale).format(value)) {
            mismatches++;
          }
        }
      }
      expect(mismatches, 0);
    });

    test('per-locale cache keys keep distinct labels', () {
      final at = DateTime(2026, 3, 15, 8);
      final dates = <String, String>{
        for (final locale in _kLocales) locale: _cachedStatusDate(at, locale),
      };
      expect(dates['en'], isNot(dates['de']));
      expect(dates['en'], isNot(dates['ja']));
      expect(dates['de'], isNot(dates['ja']));
      for (final locale in _kLocales) {
        expect(
          _cachedStatusDate(at, locale),
          DateFormat.yMMMMd(locale).format(at),
        );
      }
      final numbers = <String, String>{
        for (final locale in _kLocales)
          locale: cachedDecimalPattern(locale).format(12345),
      };
      expect(numbers['en'], isNot(numbers['de']));
    });

    test('repeated cached formats stay stable (no add-pattern mutation)', () {
      final at = _kPeriodEnds.first;
      for (final locale in _kLocales) {
        _expectStable(() => _cachedStatusDate(at, locale));
        _expectStable(() => cachedDecimalPattern(locale).format(12345));
      }
      _expectStable(() => _cachedCreditsNumber(12345));
    });
  });

  test('bench (local only): status date fresh DateFormat per call', () {
    final medians = _benchRounds(() {
      for (final at in _kPeriodEnds) {
        _sink(_freshStatusDate(at, 'en'));
      }
    }, 'status date fresh');
    expect(medians.last, lessThan(200));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): status date cached formatter', () {
    final medians = _benchRounds(() {
      for (final at in _kPeriodEnds) {
        _sink(_cachedStatusDate(at, 'en'));
      }
    }, 'status date cached');
    expect(medians.last, lessThan(10));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): credits number fresh decimalPattern per call', () {
    final medians = _benchRounds(() {
      for (var i = 0; i < _kRowCount; i++) {
        _sink(_freshCreditsNumber(1000 + i * 7));
      }
    }, 'credits number fresh');
    expect(medians.last, lessThan(50));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): credits number cachedDecimalPattern', () {
    final medians = _benchRounds(() {
      for (var i = 0; i < _kRowCount; i++) {
        _sink(_cachedCreditsNumber(1000 + i * 7));
      }
    }, 'credits number cached');
    expect(medians.last, lessThan(5));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): paid card build fresh formatters', () {
    final medians = _benchRounds(() {
      for (var build = 0; build < 25; build++) {
        _sink(_freshCreditsNumber(60000 - build));
        _sink(_freshStatusDate(_kPeriodEnds[build], 'en'));
        _sink(_freshStatusDate(_kPeriodEnds[build + 1], 'en'));
      }
    }, 'paid card build fresh');
    expect(medians.last, lessThan(100));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): paid card build cached formatters', () {
    final medians = _benchRounds(() {
      for (var build = 0; build < 25; build++) {
        _sink(_cachedCreditsNumber(60000 - build));
        _sink(_cachedStatusDate(_kPeriodEnds[build], 'en'));
        _sink(_cachedStatusDate(_kPeriodEnds[build + 1], 'en'));
      }
    }, 'paid card build cached');
    expect(medians.last, lessThan(5));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
