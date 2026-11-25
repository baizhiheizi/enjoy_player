import 'dart:math' as math;
import 'dart:typed_data';

/// Iterative radix-2 FFT over paired [Float64List] real/imaginary buffers.
///
/// The plan owns the twiddle table for one [size]; [transform] runs in place
/// with no per-call allocations.
final class Radix2FftPlan {
  Radix2FftPlan(this.size)
    : _twiddleCos = Float64List(size),
      _twiddleSin = Float64List(size) {
    final turn = 2 * math.pi / size;
    for (var n = 0; n < size; n++) {
      final argument = (-n * turn) % (2 * math.pi);
      _twiddleCos[n] = math.cos(argument);
      _twiddleSin[n] = math.sin(argument);
    }
  }

  final int size;
  final Float64List _twiddleCos;
  final Float64List _twiddleSin;

  void transform(Float64List real, Float64List imag) {
    final size = this.size;
    var j = 0;
    for (var i = 1; i < size; i++) {
      var bit = size >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final swappedReal = real[i];
        real[i] = real[j];
        real[j] = swappedReal;
        final swappedImag = imag[i];
        imag[i] = imag[j];
        imag[j] = swappedImag;
      }
    }
    for (var length = 2; length <= size; length <<= 1) {
      final half = length >> 1;
      final twiddleStride = size ~/ length;
      for (var base = 0; base < size; base += length) {
        for (var k = 0; k < half; k++) {
          final n = k * twiddleStride;
          final wr = _twiddleCos[n];
          final wi = _twiddleSin[n];
          final xr = real[base + k + half];
          final xi = imag[base + k + half];
          final tr = xr * wr - xi * wi;
          final ti = xr * wi + xi * wr;
          final ar = real[base + k];
          final ai = imag[base + k];
          real[base + k] = ar + tr;
          imag[base + k] = ai + ti;
          real[base + k + half] = ar - tr;
          imag[base + k + half] = ai - ti;
        }
      }
    }
  }
}
