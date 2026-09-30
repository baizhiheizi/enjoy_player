import 'dart:math' as math;
import 'dart:typed_data';

import '../mfcc/mfcc_extractor.dart';
import 'cost.dart';

/// Sakoe-Chiba windowed DTW over flattened [MfccFrames].
///
/// Returns, for each **reference** frame index, the matched **source**
/// frame index (median along the recovered path).
///
/// Memory is two rolling cost rows of band-width doubles plus one
/// `Uint8List` direction cell per band cell (issue #827 A2) — the
/// historical boxed `n × (2r+1)` double/int triple is gone. [maxDriftFrames]
/// caps the band so whole-clip inputs scale linearly, not with
/// `windowPct × n²`; pass a huge value to keep the pure percentage band.
List<int> mapReferenceFramesToSource(
  MfccFrames reference,
  MfccFrames source, {
  double windowPct = 0.20,
  int maxDriftFrames = 1 << 40,
}) {
  final n = reference.frameCount;
  final m = source.frameCount;
  if (n == 0 || m == 0) {
    throw ArgumentError('DTW sequences must be non-empty');
  }
  if (n == 1 && m == 1) return const [0];

  final stride = math.min(reference.stride, source.stride);

  var radius = math.min(
    (windowPct * math.max(n, m)).round(),
    maxDriftFrames,
  );
  radius = math.max(radius, (n - m).abs());
  radius = math.max(radius, 1);

  const inf = 1e30;
  final width = math.min(2 * radius + 1, m);
  final directions = Uint8List(n * width);
  var rowAbove = Float64List(width)..fillRange(0, width, inf);
  var rowBelow = Float64List(width)..fillRange(0, width, inf);

  int jCenterAt(int i) => ((i + 0.5) * m / n).floor().clamp(0, m - 1);

  for (var i = 0; i < n; i++) {
    rowBelow.fillRange(0, width, inf);

    final jc = jCenterAt(i);
    final jStart = math.max(0, jc - radius);
    final jEnd = math.min(m - 1, jc + radius);
    final aboveJc = i == 0 ? -1 : jCenterAt(i - 1);
    final aboveJStart = math.max(0, aboveJc - radius);
    final aboveJEnd = math.min(m - 1, aboveJc + radius);
    final rowBase = i * width;

    for (var j = jStart; j <= jEnd; j++) {
      final d = euclideanDistance(
        reference.data,
        reference.offsetOf(i),
        source.data,
        source.offsetOf(j),
        stride,
      );
      final col = j - jStart;
      if (i == 0 && j == 0) {
        rowBelow[col] = d;
        continue;
      }
      var best = inf;
      var bestDir = 0;
      if (i > 0 && j >= aboveJStart && j <= aboveJEnd) {
        final c = rowAbove[j - aboveJStart];
        if (c < best) {
          best = c;
          bestDir = 1;
        }
      }
      if (j > 0 && j - 1 >= jStart) {
        final c = rowBelow[j - 1 - jStart];
        if (c < best) {
          best = c;
          bestDir = 2;
        }
      }
      if (i > 0 && j > 0 && j - 1 >= aboveJStart && j - 1 <= aboveJEnd) {
        final c = rowAbove[j - 1 - aboveJStart];
        if (c < best) {
          best = c;
          bestDir = 3;
        }
      }
      rowBelow[col] = d + (best >= inf / 2 ? 0 : best);
      directions[rowBase + col] = bestDir;
    }

    final spent = rowAbove;
    rowAbove = rowBelow;
    rowBelow = spent;
  }

  final jMin = Int32List(n)..fillRange(0, n, -1);
  final jMax = Int32List(n);
  var i = n - 1;
  var j = m - 1;
  final lastJStart = math.max(0, jCenterAt(n - 1) - radius);
  final lastCol = j - lastJStart;
  if (lastCol < 0 || lastCol >= width || rowAbove[lastCol] >= inf / 2) {
    return [
      for (var k = 0; k < n; k++) ((k + 0.5) * m / n).floor().clamp(0, m - 1),
    ];
  }

  var guard = n * m + 8;
  while (guard-- > 0) {
    if (jMin[i] < 0) {
      jMin[i] = j;
      jMax[i] = j;
    } else if (j < jMin[i]) {
      jMin[i] = j;
    }
    final jStart = math.max(0, jCenterAt(i) - radius);
    final dir = directions[i * width + (j - jStart)];
    if (dir == 0) break;
    if (dir == 1) {
      i--;
    } else if (dir == 2) {
      j--;
    } else {
      i--;
      j--;
    }
  }

  return [
    for (var k = 0; k < n; k++)
      jMin[k] < 0
          ? ((k + 0.5) * m / n).floor().clamp(0, m - 1)
          : jMax[k] - ((jMax[k] - jMin[k] + 1) ~/ 2),
  ];
}
