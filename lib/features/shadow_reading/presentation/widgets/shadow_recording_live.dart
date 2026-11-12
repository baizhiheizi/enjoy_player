/// Live recording stage: paint-only countdown ring + 10 Hz caption.
///
/// The elapsed timebase is the shared `RecordingElapsedTicker` mixin; the
/// paint-only rationale and its history live in that mixin's library docs
/// and docs/features/shadow-reading.md. This stage adds the over-target
/// pulse evaluation and the ring/caption rendering.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/recording_elapsed_ticker.dart';

import 'shadow_record_fab.dart';
import 'shadow_recording_caption.dart';

class ShadowRecordingLive extends StatefulWidget {
  const ShadowRecordingLive({
    required this.targetSec,
    required this.echoActive,
    required this.stopTooltip,
    required this.onStop,
    required this.scheme,
    required this.tok,
    super.key,
  });

  /// Countdown target in seconds; `0` keeps the ring full with no over state.
  final double targetSec;
  final bool echoActive;
  final String stopTooltip;
  final VoidCallback onStop;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;

  @override
  State<ShadowRecordingLive> createState() => _ShadowRecordingLiveState();
}

class _ShadowRecordingLiveState extends State<ShadowRecordingLive>
    with TickerProviderStateMixin, RecordingElapsedTicker<ShadowRecordingLive> {
  static const _kOverPulseStepMs = 600;

  bool _overPulseHigh = false;
  bool _over = false;
  int _overStartMs = 0;

  @override
  void onRecordingTick(Duration elapsed) {
    final over =
        widget.targetSec > 0 && elapsedController.value > widget.targetSec;
    if (over && !_over) _overStartMs = elapsed.inMilliseconds;
    final overPulseHigh =
        over &&
        ((elapsed.inMilliseconds - _overStartMs) ~/ _kOverPulseStepMs).isOdd;
    if (over == _over && overPulseHigh == _overPulseHigh) return;
    setState(() {
      _over = over;
      _overPulseHigh = overPulseHigh;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Tooltip(
            message: widget.stopTooltip,
            child: RepaintBoundary(
              child: ShadowRecordFab(
                recording: true,
                echoActive: widget.echoActive,
                ringElapsedSec: elapsedController,
                ringTargetSec: widget.targetSec,
                overTarget: _over,
                overPulseHigh: _overPulseHigh,
                showProgressArc: true,
                onTap: widget.onStop,
                scheme: widget.scheme,
                tok: widget.tok,
              ),
            ),
          ),
        ),
        SizedBox(height: widget.tok.space4),
        ShadowRecordingElapsedCaption(
          elapsedTenths: elapsedTenths,
          targetSec: widget.targetSec,
        ),
      ],
    );
  }
}
