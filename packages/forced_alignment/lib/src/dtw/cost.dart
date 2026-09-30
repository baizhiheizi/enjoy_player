import 'dart:math' as math;
import 'dart:typed_data';

/// Euclidean distance between two contiguous [stride]-length rows of
/// flattened MFCC matrices starting at [aOffset] / [bOffset].
double euclideanDistance(
  Float64List a,
  int aOffset,
  Float64List b,
  int bOffset,
  int stride,
) {
  var sum = 0.0;
  for (var i = 0; i < stride; i++) {
    final d = a[aOffset + i] - b[bOffset + i];
    sum += d * d;
  }
  return math.sqrt(sum);
}
