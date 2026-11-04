import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/shadow_reading/domain/echo_region_analysis.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/pitch_contour_chart.dart';

const int _kSeriesPoints = 520;
const int _kSweepSeries = 512;
const int _kTicksPerPass = 200;
const int _kWarmupPasses = 50;
const int _kSamplesPerRound = 20;
const int _kRounds = 3;
const int _kFuzzCases = 200;

typedef RunPoint = (double, double);
typedef Run = List<RunPoint>;
typedef RunList = List<Run>;

double _legacySemitones(double hz) => 12 * math.log(hz) / math.ln2;

bool _legacyVoiced(double? hz) => hz != null && hz.isFinite && hz > 0;

Run _legacyMedianFilter(Run run) {
  if (run.length < 5) return run;
  return [
    for (var i = 0; i < run.length; i++)
      (
        run[i].$1,
        (([
          for (
            var j = math.max(0, i - 2);
            j <= math.min(run.length - 1, i + 2);
            j++
          )
            run[j].$2,
        ]..sort())[(math.min(run.length - 1, i + 2) - math.max(0, i - 2)) ~/
            2]),
      ),
  ];
}

RunList _legacyRuns(
  List<EchoRegionSeriesPoint> points,
  double? Function(EchoRegionSeriesPoint) hz,
) {
  final raw = <Run>[];
  Run? current;
  double? lastT;
  for (final p in points) {
    final v = hz(p);
    if (!_legacyVoiced(v)) continue;
    if (current == null ||
        (lastT != null && p.t - lastT > kPitchContourMaxGapSec)) {
      current = [];
      raw.add(current);
    }
    current.add((p.t, _legacySemitones(v!)));
    lastT = p.t;
  }
  final kept = [
    for (final run in raw)
      if (run.last.$1 - run.first.$1 >= kPitchContourMinRunSec) run,
  ];
  final all = [
    for (final run in kept)
      for (final (_, st) in run) st,
  ]..sort();
  if (all.isEmpty) return const [];
  final center = all[all.length ~/ 2];
  double fold(double st) {
    var v = st;
    while (v - center > kPitchContourOctaveFoldSemitones) {
      v -= 12;
    }
    while (center - v > kPitchContourOctaveFoldSemitones) {
      v += 12;
    }
    return v;
  }

  return [
    for (final run in kept)
      _legacyMedianFilter([for (final (t, st) in run) (t, fold(st))]),
  ];
}

bool _runsEqual(RunList a, RunList b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final ra = a[i];
    final rb = b[i];
    if (ra.length != rb.length) return false;
    for (var j = 0; j < ra.length; j++) {
      if (ra[j].$1 != rb[j].$1 || ra[j].$2 != rb[j].$2) return false;
    }
  }
  return true;
}

List<EchoRegionSeriesPoint> _buildSeries({
  int n = _kSeriesPoints,
  int seed = 7,
  bool includeOctaveErrors = true,
  double voicedFraction = 0.85,
}) {
  final rnd = math.Random(seed);
  final out = <EchoRegionSeriesPoint>[];
  var voicedHere = true;
  var gate = 0;
  for (var i = 0; i < n; i++) {
    final t = i * 4.0 / n;
    gate--;
    if (gate <= 0) {
      voicedHere = rnd.nextDouble() < voicedFraction;
      gate = 3 + rnd.nextInt(45);
    }
    if (!voicedHere) {
      out.add(EchoRegionSeriesPoint(t: t, ampRef: 0.2));
      continue;
    }
    final hz = 180 + 60 * math.sin(t * 3) + rnd.nextDouble() * 20;
    final refHz = includeOctaveErrors && i % 37 == 0 ? hz * 2 : hz;
    final userVoiced = i.isEven || rnd.nextDouble() > 0.3;
    out.add(
      EchoRegionSeriesPoint(
        t: t,
        ampRef: 0.4 + rnd.nextDouble() * 0.5,
        pitchRefHz: refHz,
        ampUser: userVoiced ? 0.35 + rnd.nextDouble() * 0.4 : 0,
        pitchUserHz: userVoiced ? hz * 0.98 : null,
      ),
    );
  }
  return out;
}

void main() {
  test('memoized runs match the legacy derivation over the corpus', () {
    final cases = <List<EchoRegionSeriesPoint>>[
      _buildSeries(),
      _buildSeries(n: 8, seed: 3),
      _buildSeries(n: 4, seed: 11, voicedFraction: 1),
      <EchoRegionSeriesPoint>[],
      <EchoRegionSeriesPoint>[
        const EchoRegionSeriesPoint(t: 0.0, ampRef: 0.2, pitchRefHz: 200),
      ],
      <EchoRegionSeriesPoint>[
        const EchoRegionSeriesPoint(t: 0.0, ampRef: 0.2, pitchRefHz: 200),
        const EchoRegionSeriesPoint(t: 0.05, ampRef: 0.2, pitchRefHz: 200),
      ],
      <EchoRegionSeriesPoint>[
        const EchoRegionSeriesPoint(t: 0.0, ampRef: 0.2, pitchRefHz: 200),
        const EchoRegionSeriesPoint(t: 0.25, ampRef: 0.2, pitchRefHz: 200),
        const EchoRegionSeriesPoint(t: 0.50, ampRef: 0.2, pitchRefHz: 200),
      ],
      <EchoRegionSeriesPoint>[
        const EchoRegionSeriesPoint(t: 0.0, ampRef: 0.2, pitchRefHz: 200),
        const EchoRegionSeriesPoint(t: 1.0, ampRef: 0.2, pitchRefHz: 200),
      ],
      _buildSeries(n: 2000, seed: 23),
    ];
    for (final points in cases) {
      final got = pitchContourRuns(points, showReference: true, showUser: true);
      expect(
        _runsEqual(got.reference, _legacyRuns(points, (p) => p.pitchRefHz)),
        isTrue,
        reason: 'reference series mismatch for n=${points.length}',
      );
      expect(
        _runsEqual(got.user, _legacyRuns(points, (p) => p.pitchUserHz)),
        isTrue,
        reason: 'user series mismatch for n=${points.length}',
      );
    }
  });

  test('memoized runs match the legacy derivation over random series', () {
    for (var seed = 0; seed < _kFuzzCases; seed++) {
      final points = _buildSeries(seed: seed * 13 + 1);
      final got = pitchContourRuns(points, showReference: true, showUser: true);
      expect(
        _runsEqual(got.reference, _legacyRuns(points, (p) => p.pitchRefHz)),
        isTrue,
        reason: 'fuzz reference mismatch (seed $seed)',
      );
      expect(
        _runsEqual(got.user, _legacyRuns(points, (p) => p.pitchUserHz)),
        isTrue,
        reason: 'fuzz user mismatch (seed $seed)',
      );
    }
  });

  test('derives each series once per points identity', () {
    final points = _buildSeries(seed: 101);
    final before = pitchContourRunsDerivationCount;
    for (var pass = 0; pass < 10; pass++) {
      pitchContourRuns(points, showReference: true, showUser: true);
    }
    expect(pitchContourRunsDerivationCount, before + 2);
  });

  test('a fresh equal-content series derives its own entries', () {
    final a = _buildSeries(seed: 202);
    final b = _buildSeries(seed: 202);
    expect(a, isNot(same(b)));
    final before = pitchContourRunsDerivationCount;
    pitchContourRuns(a, showReference: true, showUser: true);
    pitchContourRuns(b, showReference: true, showUser: true);
    expect(pitchContourRunsDerivationCount, before + 4);
  });

  test('a disabled series derives nothing until it is toggled on', () {
    final points = _buildSeries(seed: 303);
    final before = pitchContourRunsDerivationCount;
    pitchContourRuns(points, showReference: true, showUser: false);
    expect(pitchContourRunsDerivationCount, before + 1);
    pitchContourRuns(points, showReference: false, showUser: false);
    expect(pitchContourRunsDerivationCount, before + 1);
    final toggled = pitchContourRuns(
      points,
      showReference: false,
      showUser: true,
    );
    expect(pitchContourRunsDerivationCount, before + 2);
    expect(
      _runsEqual(toggled.user, _legacyRuns(points, (p) => p.pitchUserHz)),
      isTrue,
    );
  });

  test('playback-loop stays under the loose ceiling (local only)', () {
    final legacy =
        (Platform.environment['PITCH_RUNS_BENCH_MODE'] ?? '') == 'legacy';
    final points = _buildSeries();
    (RunList, RunList) paintTick() {
      if (legacy) {
        return (
          _legacyRuns(points, (p) => p.pitchRefHz),
          _legacyRuns(points, (p) => p.pitchUserHz),
        );
      }
      final r = pitchContourRuns(points, showReference: true, showUser: true);
      return (r.reference, r.user);
    }

    double sinkOf((RunList, RunList) runs) {
      final (ref, user) = runs;
      var s = 0.0 + ref.length + user.length;
      for (final run in ref) {
        s += run.first.$2;
      }
      for (final run in user) {
        s += run.first.$2;
      }
      return s;
    }

    var sink = 0.0;
    final warm = paintTick();
    for (var pass = 0; pass < _kWarmupPasses; pass++) {
      sink += sinkOf(warm);
    }
    final rounds = <double>[];
    for (var round = 0; round < _kRounds; round++) {
      final samples = <double>[];
      for (var sample = 0; sample < _kSamplesPerRound; sample++) {
        final sw = Stopwatch()..start();
        for (var tick = 0; tick < _kTicksPerPass; tick++) {
          sink += sinkOf(paintTick());
        }
        sw.stop();
        samples.add(sw.elapsedMicroseconds / 1000);
      }
      samples.sort();
      rounds.add(samples[samples.length ~/ 2]);
    }
    // ignore: avoid_print
    print(
      'pitch-runs playback-loop (${legacy ? 'legacy' : 'memoized'}): '
      '${rounds.map((m) => m.toStringAsFixed(3)).join(' / ')} ms per '
      '$_kTicksPerPass-tick pass (n=$_kSeriesPoints, sink=$sink)',
    );
    expect(rounds[rounds.length ~/ 2], lessThan(200));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');

  test('fresh-series sweep stays under the loose ceiling (local only)', () {
    final legacy =
        (Platform.environment['PITCH_RUNS_BENCH_MODE'] ?? '') == 'legacy';
    final rounds = <double>[];
    var sink = 0.0;
    for (var round = 0; round < _kRounds; round++) {
      for (var i = 0; i < 15; i++) {
        sink += _legacyRuns(
          _buildSeries(seed: 9000 + i),
          (p) => p.pitchRefHz,
        ).fold(0.0, (acc, run) => acc + run.first.$2);
      }
      final samples = <double>[];
      for (var sample = 0; sample < 20; sample++) {
        final series = [
          for (var i = 0; i < _kSweepSeries; i++)
            _buildSeries(seed: sample * 100000 + round * 10000 + i),
        ];
        final sw = Stopwatch()..start();
        for (final points in series) {
          if (legacy) {
            sink += _legacyRuns(
              points,
              (p) => p.pitchRefHz,
            ).fold(0.0, (acc, run) => acc + run.first.$2);
            sink += _legacyRuns(
              points,
              (p) => p.pitchUserHz,
            ).fold(0.0, (acc, run) => acc + run.first.$2);
          } else {
            final r = pitchContourRuns(
              points,
              showReference: true,
              showUser: true,
            );
            sink += r.reference.fold(0.0, (acc, run) => acc + run.first.$2);
            sink += r.user.fold(0.0, (acc, run) => acc + run.first.$2);
          }
        }
        sw.stop();
        samples.add(sw.elapsedMicroseconds / 1000);
      }
      samples.sort();
      rounds.add(samples[samples.length ~/ 2]);
    }
    // ignore: avoid_print
    print(
      'pitch-runs sweep (${legacy ? 'legacy' : 'memoized'}): '
      '${rounds.map((m) => m.toStringAsFixed(1)).join(' / ')} ms per '
      '$_kSweepSeries-fresh-series sweep (sink=$sink)',
    );
    expect(rounds[rounds.length ~/ 2], lessThan(5000));
  }, skip: 'Local-only microbenchmark; run with --run-skipped.');
}
