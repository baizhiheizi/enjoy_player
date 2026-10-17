/// Frame-stall detector for the Linux embedded-browser texture pipeline
/// (specs/047 T047).
///
/// A playing video produces a continuously changing texture. Pairs of
/// luminance samples that are both near-black and identical while playback is
/// reported live indicate the hardware frame-export stall; the verdict fires
/// once and the recovery path arms software GL for the next launch.
///
/// The probe is Linux-only: ADR-0098's verdict writes the Linux runner's
/// software-GL marker, and every other target short-circuits YouTube
/// availability to playable. [supportedOn] is the one place that policy lives;
/// the stage consults it before sampling anything.
///
/// Healthy playback does not need a fast cadence forever. After
/// [healthyPairsBeforeBackoff] consecutive non-stall pairs the probe backs off
/// from [pairInterval] to [slowPairInterval], so a long healthy session still
/// detects a late stall without paying the fast readback cadence.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform;

/// One luminance snapshot of the video stage (0..1 scales).
typedef FrameSample = ({double mean, double deviation});

typedef FrameSampleProvider = Future<FrameSample?> Function();

class YoutubeFrameWatchdog {
  YoutubeFrameWatchdog({
    required FrameSampleProvider sampleProvider,
    required bool Function() playingCheck,
    required void Function() stalledCallback,
    this.pairInterval = const Duration(milliseconds: 900),
    this.slowPairInterval = const Duration(seconds: 15),
    this.healthyPairsBeforeBackoff = 3,
    this.requiredStalledPairs = 3,
    this.blackMeanThreshold = 0.06,
    this.pairDriftThreshold = 0.01,
    Future<void> Function(Duration delay)? sleepFn,
  }) : _luminanceSampler = sampleProvider,
       _isPlayingLive = playingCheck,
       _onStallVerdict = stalledCallback,
       _pacer = sleepFn;

  /// The only platform whose recovery path consumes a verdict (ADR-0098).
  static bool supportedOn(TargetPlatform platform) =>
      platform == TargetPlatform.linux;

  final FrameSampleProvider _luminanceSampler;
  final bool Function() _isPlayingLive;
  final void Function() _onStallVerdict;
  final Duration pairInterval;
  final Duration slowPairInterval;
  final int healthyPairsBeforeBackoff;
  final int requiredStalledPairs;
  final double blackMeanThreshold;
  final double pairDriftThreshold;
  final Future<void> Function(Duration delay)? _pacer;

  Timer? _timer;
  int _stalledPairs = 0;
  int _healthyPairs = 0;
  bool _verdictFired = false;
  bool _inTick = false;

  bool get isRunning => _timer != null;

  bool get verdictFired => _verdictFired;

  void start() {
    if (_verdictFired || isRunning) return;
    _stalledPairs = 0;
    _healthyPairs = 0;
    _scheduleNext(pairInterval);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  Duration get _nextPairDelay => _healthyPairs >= healthyPairsBeforeBackoff
      ? slowPairInterval
      : pairInterval;

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(_tick()));
  }

  Future<void> _sleep() =>
      _pacer?.call(pairInterval) ?? Future<void>.delayed(pairInterval);

  Future<void> _tick() async {
    if (_verdictFired || !isRunning) return;
    if (_inTick || !_isPlayingLive()) {
      _scheduleNext(_nextPairDelay);
      return;
    }
    _inTick = true;
    try {
      final first = await _luminanceSampler();
      if (_verdictFired || !isRunning || first == null) return;
      await _sleep();
      if (_verdictFired || !isRunning || !_isPlayingLive()) return;
      final second = await _luminanceSampler();
      if (_verdictFired || !isRunning || second == null) return;

      final drift =
          (first.mean - second.mean).abs() +
          (first.deviation - second.deviation).abs();
      final stalledPair =
          first.mean < blackMeanThreshold &&
          second.mean < blackMeanThreshold &&
          drift < pairDriftThreshold;
      if (stalledPair) {
        _stalledPairs++;
        _healthyPairs = 0;
      } else {
        _stalledPairs = 0;
        _healthyPairs++;
      }
      if (_stalledPairs >= requiredStalledPairs) {
        _verdictFired = true;
        stop();
        _onStallVerdict();
      }
    } finally {
      _inTick = false;
      if (!_verdictFired && isRunning) _scheduleNext(_nextPairDelay);
    }
  }
}
