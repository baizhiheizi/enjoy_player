/// Runs envelope + YIN pitch extraction on decoded PCM.
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/echo_segment_pcm_extractor.dart';
import '../domain/echo_region_analysis.dart';
import '../domain/waveform_envelope.dart';
import '../domain/yin_pitch.dart';

Future<EchoRegionAnalysisResult?> analyzeMediaTimeRange({
  required String mediaPath,
  required double startSec,
  required double endSec,
}) async {
  final dur = endSec - startSec;
  if (dur <= 0) return null;
  final pcm = await extractMonoFloat32Segment(
    mediaFilePath: mediaPath,
    startSec: startSec,
    durationSec: dur,
  );
  if (pcm == null) return null;
  return _analyzePcmOffUiThread(pcm.samples, pcm.sampleRate);
}

Future<EchoRegionAnalysisResult?> analyzeMediaFileFull({required String mediaPath}) async {
  final pcm = await extractEntireFileMonoF32(mediaPath);
  if (pcm == null) return null;
  return _analyzePcmOffUiThread(pcm.samples, pcm.sampleRate);
}

Future<EchoRegionAnalysisResult> _analyzePcmOffUiThread(
  Float32List samples,
  double sampleRate,
) async {
  if (kIsWeb) {
    return analyzePcmSamples(samples, sampleRate);
  }
  final s = samples;
  final sr = sampleRate;
  return Isolate.run(() => analyzePcmSamples(s, sr));
}

EchoRegionAnalysisResult analyzePcmSamples(Float32List samples, double sampleRate) {
  final env = computePeakEnvelope(samples, sampleRate, points: 520);
  final yin = estimatePitchYin(samples, sampleRate);
  final hz = pitchAtEnvelopeTimes(envelope: env, yin: yin);
  final points = buildSeriesPoints(envelope: env, pitchHzList: hz);
  final durationSeconds = samples.length / sampleRate;
  return EchoRegionAnalysisResult(
    points: points,
    durationSeconds: durationSeconds,
    sampleRate: sampleRate,
  );
}
