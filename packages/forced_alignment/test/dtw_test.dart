import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forced_alignment/src/dtw/windowed_dtw.dart';
import 'package:forced_alignment/src/mfcc/mfcc_extractor.dart';

MfccFrames _frames(List<List<double>> rows) => MfccFrames.fromBoxed(rows);

List<double> _vec(double x) => [x, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

void main() {
  test('identical sequences map each reference frame to itself', () {
    final rows = [for (var i = 0; i < 12; i++) _vec(i.toDouble())];
    final seq = _frames(rows);
    final map = mapReferenceFramesToSource(seq, seq);
    for (var i = 0; i < seq.frameCount; i++) {
      expect(map[i], i, reason: 'frame $i');
    }
  });

  test('source delayed by 2 frames maps i -> i+2', () {
    final referenceRows = [for (var i = 0; i < 10; i++) _vec(i.toDouble())];
    final reference = _frames(referenceRows);
    final source = _frames([_vec(-2), _vec(-1), ...referenceRows]);
    final map = mapReferenceFramesToSource(reference, source);
    for (var i = 0; i < reference.frameCount; i++) {
      expect(
        (map[i] - (i + 2)).abs(),
        lessThanOrEqualTo(1),
        reason: 'frame $i mapped to ${map[i]}',
      );
    }
  });

  test('tight drift cap still maps an identical sequence exactly', () {
    final rows = [for (var i = 0; i < 600; i++) _vec(i.toDouble())];
    final seq = _frames(rows);
    final map = mapReferenceFramesToSource(seq, seq, maxDriftFrames: 40);
    expect(map, [for (var i = 0; i < rows.length; i++) i]);
  });

  test('a capped band wider than the percentage band changes nothing', () {
    final reference = _frames([
      for (var i = 0; i < 50; i++) _vec((i % 7).toDouble()),
    ]);
    final source = _frames([
      for (var i = 0; i < 55; i++) _vec(((i - 3) % 7).toDouble()),
    ]);
    final uncapped = mapReferenceFramesToSource(reference, source);
    final looselyCapped = mapReferenceFramesToSource(
      reference,
      source,
      maxDriftFrames: 10000,
    );
    expect(looselyCapped, uncapped);
  });

  test('empty sequences are rejected', () {
    final empty = MfccFrames(data: Float64List(0), stride: 0, frameCount: 0);
    final one = _frames([_vec(1)]);
    expect(() => mapReferenceFramesToSource(empty, one), throwsArgumentError);
    expect(() => mapReferenceFramesToSource(one, empty), throwsArgumentError);
  });
}
