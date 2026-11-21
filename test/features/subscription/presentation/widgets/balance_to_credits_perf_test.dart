import 'package:enjoy_player/core/format/cached_number_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

const int _kRowCount = 502;
const int _kWarmupPasses = 200;
const int _kSamples = 30;
const int _kRounds = 3;

const List<String> _kLocales = <String>['en', 'de', 'ja'];

final List<double> _kBalances = <double>[
  for (var i = 0; i < _kRowCount; i++) 0.0 + i * 13.37,
];

int _benchSink = 0;

String _freshUsdLabel(double balance) =>
    NumberFormat.simpleCurrency(name: 'USD').format(balance);

String _cachedUsdLabel(double balance) =>
    cachedSimpleCurrency(name: 'USD').format(balance);

int _mismatches(List<double> balances) {
  var mismatches = 0;
  for (final locale in _kLocales) {
    for (final balance in balances) {
      final fresh = NumberFormat.simpleCurrency(
        locale: locale,
        name: 'USD',
      ).format(balance);
      final cached = cachedSimpleCurrency(
        locale: locale,
        name: 'USD',
      ).format(balance);
      if (fresh != cached) {
        mismatches++;
      }
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
  setUpAll(() {
    Intl.defaultLocale = 'en';
  });

  group('balance card currency formatter matches fresh construction', () {
    test('per-locale differential (en/de/ja)', () {
      expect(_mismatches(_kBalances), 0);
    });

    test('per-locale patterns flow through the cached formatter', () {
      final labels = <String, String>{
        for (final locale in _kLocales)
          locale: cachedSimpleCurrency(
            locale: locale,
            name: 'USD',
          ).format(12345.6),
      };
      expect(labels['en'], isNot(labels['de']));
      expect(labels['en'], cachedSimpleCurrency(name: 'USD').format(12345.6));
    });

    test('repeated cached formats stay stable', () {
      _expectStable(() => _cachedUsdLabel(314.15));
      _expectStable(
        () => cachedSimpleCurrency(locale: 'de', name: 'USD').format(314.15),
      );
    });
  });

  test('bench (local only): fresh simpleCurrency per call', () {
    final medians = _benchRounds(() {
      for (final balance in _kBalances) {
        _benchSink += _freshUsdLabel(balance).length;
      }
    }, 'balance label fresh');
    expect(medians.last, lessThan(200));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('bench (local only): cachedSimpleCurrency', () {
    final medians = _benchRounds(() {
      for (final balance in _kBalances) {
        _benchSink += _cachedUsdLabel(balance).length;
      }
    }, 'balance label cached');
    expect(medians.last, lessThan(20));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test(
    'bench (local only): balance card build fresh formatter per rebuild',
    () {
      final medians = _benchRounds(() {
        for (var build = 0; build < 25; build++) {
          _benchSink += _freshUsdLabel(_kBalances[build]).length;
        }
      }, 'balance card build fresh');
      expect(medians.last, lessThan(20));
    },
    skip: 'Local-only microbenchmark; run with --run-skipped.',
  );

  test('bench (local only): balance card build cached formatter', () {
    final medians = _benchRounds(() {
      for (var build = 0; build < 25; build++) {
        _benchSink += _cachedUsdLabel(_kBalances[build]).length;
      }
    }, 'balance card build cached');
    expect(medians.last, lessThan(2));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
