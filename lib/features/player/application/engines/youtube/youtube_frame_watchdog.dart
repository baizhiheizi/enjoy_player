/// Frame-stall detector for the Linux embedded-browser texture pipeline
/// (specs/047 T047).
///
/// A playing video produces a continuously changing texture. Pairs of
/// luminance samples that are both near-black and identical while playback is
/// reported live indicate the hardware frame-export stall; the verdict fires
/// once and the recovery path re-creates the WebView with software GL.
library;

import 'dart:async';

/// One luminance snapshot of the video stage (0..1 scales).
typedef FrameSample = ({double mean, double deviation});

typedef FrameSampleProvider = Future<FrameSample?> Function();

class YoutubeFrameWatchdog {
  YoutubeFrameWatchdog({
    required FrameSampleProvider sampleProvider,
    required bool Function() playingCheck,
    required void Function() stalledCallback,
    this.pairInterval = const Duration(milliseconds: 900),
    this.requiredStalledPairs = 3,
    this.blackMeanThreshold = 0.06,
    this.pairDriftThreshold = 0.01,
    Future<void> Function(Duration delay)? sleepFn,
  }) : _luminanceSampler = sampleProvider,
       _isPlayingLive = playingCheck,
       _onStallVerdict = stalledCallback,
       _pacer = sleepFn;

  final FrameSampleProvider _luminanceSampler;
  final bool Function() _isPlayingLive;
  final void Function() _onStallVerdict;
  final Duration pairInterval;
  final int requiredStalledPairs;
  final double blackMeanThreshold;
  final double pairDriftThreshold;
  final Future<void> Function(Duration delay)? _pacer;

  Timer? _timer;
  int _stalledPairs = 0;
  bool _verdictFired = false;
  bool _inTick = false;

  bool get isRunning => _timer != null;

  bool get verdictFired => _verdictFired;

  void start() {
    if (_verdictFired || isRunning) return;
    _stalledPairs = 0;
    _timer = Timer.periodic(pairInterval, (_) => unawaited(_tick()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  Future<void> _sleep() =>
      _pacer?.call(pairInterval) ?? Future<void>.delayed(pairInterval);

  Future<void> _tick() async {
    if (_inTick || _verdictFired || !_isPlayingLive()) return;
    _inTick = true;
    try {
      final first = await _luminanceSampler();
      if (_verdictFired || first == null) return;
      await _sleep();
      if (_verdictFired || !_isPlayingLive()) return;
      final second = await _luminanceSampler();
      if (_verdictFired || second == null) return;

      final drift =
          (first.mean - second.mean).abs() +
          (first.deviation - second.deviation).abs();
      final stalledPair =
          first.mean < blackMeanThreshold &&
          second.mean < blackMeanThreshold &&
          drift < pairDriftThreshold;
      _stalledPairs = stalledPair ? _stalledPairs + 1 : 0;
      if (_stalledPairs >= requiredStalledPairs) {
        _verdictFired = true;
        stop();
        _onStallVerdict();
      }
    } finally {
      _inTick = false;
    }
  }
}
