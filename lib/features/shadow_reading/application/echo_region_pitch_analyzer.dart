/// Runs envelope + YIN pitch extraction on decoded PCM.
library;

import 'dart:typed_data';

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
  return analyzePcmSamples(pcm.samples, pcm.sampleRate);
}

Future<EchoRegionAnalysisResult?> analyzeMediaFileFull({required String mediaPath}) async {
  final pcm = await extractEntireFileMonoF32(mediaPath);
  if (pcm == null) return null;
  return analyzePcmSamples(pcm.samples, pcm.sampleRate);
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
