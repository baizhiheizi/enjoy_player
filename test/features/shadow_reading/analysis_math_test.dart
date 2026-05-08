import 'dart:typed_data';

import 'package:enjoy_player/features/shadow_reading/domain/echo_region_analysis.dart';
import 'package:enjoy_player/features/shadow_reading/domain/waveform_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computePeakEnvelope', () {
    test('normalizes peak envelope', () {
      final samples = Float32List.fromList([0, 1, 0, -1, 0, 0.5]);
      final env = computePeakEnvelope(samples, 6.0, points: 8);
      expect(env.isNotEmpty, true);
      expect(env.every((p) => p.amp >= 0 && p.amp <= 1), true);
    });
  });

  group('mergeUserPitchOntoReference', () {
    test('scales user times onto reference duration', () {
      const ref = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
        EchoRegionSeriesPoint(t: 1, ampRef: 0.5, pitchRefHz: 110),
      ];
      const user = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90),
        EchoRegionSeriesPoint(t: 1, ampRef: 0.4, pitchRefHz: 95),
      ];
      final merged = mergeUserPitchOntoReference(
        referencePoints: ref,
        userPoints: user,
        referenceDurationSec: 2,
        userDurationSec: 2,
      );
      expect(merged.length, 2);
      expect(merged[0].pitchUserHz, 90);
    });
  });
}
