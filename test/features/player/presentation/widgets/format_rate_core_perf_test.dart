import 'dart:math';

import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:flutter_test/flutter_test.dart';

String legacyFormatRateCore(double rate) {
  final x = (rate * 100).round() / 100;
  return x.toStringAsFixed(2).replaceFirst(RegExp(r'(?<=\.\d)0$'), '');
}

final RegExp _rateShape = RegExp(r'^-?\d+\.\d{2}$');

void expectRateAgrees(double rate) {
  final legacy = legacyFormatRateCore(rate);
  final scanned = formatRateCore(rate);
  expect(scanned, legacy, reason: 'rate $rate');
  final fixed = ((rate * 100).round() / 100).toStringAsFixed(2);
  if (_rateShape.hasMatch(fixed) && !fixed.endsWith('0')) {
    expect(legacy, fixed, reason: 'unstripped $rate');
  }
}

void main() {
  group('differential: strip scan equals the lookbehind replaceFirst', () {
    test('dock rate options', () {
      const rates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];
      for (final rate in rates) {
        expectRateAgrees(rate);
      }
    });

    test('rounding and string-shape edges', () {
      final rates = <double>[
        0.0,
        -0.0,
        0.001,
        0.005,
        0.015,
        0.05,
        0.1,
        0.995,
        1.005,
        1.015,
        1.995,
        2.675,
        1.675,
        123.456,
        1e-9,
        -1e-9,
        1e12,
        -1e12,
        9e15,
        -9e15,
      ];
      for (final rate in rates) {
        expectRateAgrees(rate);
      }
    });

    test('fuzz corpora across magnitude regimes', () {
      final random = Random(20261127);
      final regimes = <double Function()>[
        () => random.nextDouble() * 4,
        () => random.nextDouble() * 100,
        () => (random.nextDouble() - 0.5) * 1e6,
        () => random.nextDouble() * 1e-6,
        () => (random.nextInt(2001) - 1000) / 1000,
        () => random.nextDouble() * 9e15,
      ];
      for (var i = 0; i < 3000; i++) {
        expectRateAgrees(regimes[i % regimes.length]());
      }
    });
  });

  test('rate pins', () {
    expect(formatRateCore(1.0), '1.0');
    expect(formatRateCore(1.5), '1.5');
    expect(formatRateCore(1.25), '1.25');
    expect(formatRateCore(0.75), '0.75');
    expect(formatRateCore(2.0), '2.0');
    expect(formatRateCore(3.0), '3.0');
    expect(formatRateCore(0.5), '0.5');
    expect(formatRateCore(0.05), '0.05');
    expect(formatRateCore(2.05), '2.05');
    expect(formatRateCore(10.0), '10.0');
    expect(formatRateCore(100.0), '100.0');
  });

  const int benchPasses = 200;
  const int benchSamples = 30;
  const int benchRounds = 3;

  final benchRates = [
    for (var i = 0; i < 502; i++)
      [
        0.5,
        0.75,
        1.0,
        1.25,
        1.5,
        1.75,
        2.0,
        2.5,
        3.0,
        0.05,
        0.1,
        0.995,
        1.005,
        1.995,
        2.05,
        3.5,
      ][i % 16],
  ];

  int runRatePass(List<double> rates, String Function(double) format) {
    var sink = 0;
    for (final rate in rates) {
      sink += format(rate).length;
    }
    return sink;
  }

  List<double> benchRoundsMs(
    int Function(List<double>, String Function(double)) run,
    List<double> rates,
    String Function(double) format,
  ) {
    for (var warm = 0; warm < benchPasses; warm++) {
      run(rates, format);
    }
    return [
      for (var round = 0; round < benchRounds; round++)
        () {
          final samples = <double>[];
          for (var s = 0; s < benchSamples; s++) {
            final sw = Stopwatch()..start();
            run(rates, format);
            sw.stop();
            samples.add(sw.elapsedMicroseconds / 1000);
          }
          samples.sort();
          return samples[samples.length ~/ 2];
        }(),
    ];
  }

  test(
    'bench (local only): legacy lookbehind rate format, 502-call corpus',
    skip: true,
    () {
      final rounds = benchRoundsMs(
        runRatePass,
        benchRates,
        legacyFormatRateCore,
      );
      var sink = 0;
      for (var i = 0; i < benchPasses; i++) {
        sink += runRatePass(benchRates, legacyFormatRateCore);
      }
      // ignore: avoid_print
      print(
        'legacy rounds ms ${rounds.map((m) => m.toStringAsFixed(4))} sink $sink',
      );
    },
  );

  test('bench (local only): scan rate format, 502-call corpus', skip: true, () {
    final rounds = benchRoundsMs(runRatePass, benchRates, formatRateCore);
    var sink = 0;
    for (var i = 0; i < benchPasses; i++) {
      sink += runRatePass(benchRates, formatRateCore);
    }
    // ignore: avoid_print
    print(
      'scan rounds ms ${rounds.map((m) => m.toStringAsFixed(4))} sink $sink',
    );
  });
}
