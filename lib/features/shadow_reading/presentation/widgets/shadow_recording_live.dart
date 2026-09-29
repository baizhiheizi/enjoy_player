/// Live recording stage: paint-only countdown ring + ~10 Hz caption.
///
/// Extracted from `shadow_reading_panel.dart` (issue #810 E2): the ring is
/// driven by an [AnimationController] as its repaint listenable, so each
/// vsync repaints the ring without rebuilding any element, and only the
/// caption text re-renders on its coarse timer.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'shadow_record_fab.dart';
import 'shadow_recording_caption.dart';

class ShadowRecordingLive extends StatefulWidget {
  const ShadowRecordingLive({
    required this.targetSec,
    required this.echoActive,
    required this.stopTooltip,
    required this.onStop,
    required this.l10n,
    required this.tt,
    required this.scheme,
    required this.tok,
    super.key,
  });

  /// Countdown target in seconds; `0` keeps the ring full with no over state.
  final double targetSec;
  final bool echoActive;
  final String stopTooltip;
  final VoidCallback onStop;
  final AppLocalizations l10n;
  final TextTheme tt;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;

  @override
  State<ShadowRecordingLive> createState() => _ShadowRecordingLiveState();
}

class _ShadowRecordingLiveState extends State<ShadowRecordingLive>
    with TickerProviderStateMixin {
  static const _kOverPulseInterval = Duration(milliseconds: 600);

  late final AnimationController _elapsedSec = AnimationController.unbounded(
    vsync: this,
  );
  late final Ticker _ticker = createTicker(_onTick);
  Timer? _overPulseTimer;
  bool _overPulseHigh = false;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _overPulseTimer?.cancel();
    _ticker.dispose();
    _elapsedSec.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsedSec.value = elapsed.inMicroseconds / 1e6;
    final over = widget.targetSec > 0 && _elapsedSec.value > widget.targetSec;
    if (over == _over) return;
    if (over) {
      _overPulseTimer ??= Timer.periodic(_kOverPulseInterval, (_) {
        if (!mounted) return;
        setState(() => _overPulseHigh = !_overPulseHigh);
      });
      setState(() => _over = true);
    } else {
      _overPulseTimer?.cancel();
      _overPulseTimer = null;
      setState(() {
        _over = false;
        _overPulseHigh = false;
      });
    }
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
                ringElapsedSec: _elapsedSec,
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
        _ShadowRecordingCaption(
          elapsedSec: _elapsedSec,
          targetSec: widget.targetSec,
          l10n: widget.l10n,
          tt: widget.tt,
          scheme: widget.scheme,
          tok: widget.tok,
        ),
      ],
    );
  }
}

class _ShadowRecordingCaption extends StatefulWidget {
  const _ShadowRecordingCaption({
    required this.elapsedSec,
    required this.targetSec,
    required this.l10n,
    required this.tt,
    required this.scheme,
    required this.tok,
  });

  final Animation<double> elapsedSec;
  final double targetSec;
  final AppLocalizations l10n;
  final TextTheme tt;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;

  @override
  State<_ShadowRecordingCaption> createState() =>
      _ShadowRecordingCaptionState();
}

class _ShadowRecordingCaptionState extends State<_ShadowRecordingCaption> {
  static const _kRefreshInterval = Duration(milliseconds: 100);

  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(_kRefreshInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSec = widget.elapsedSec.value;
    final overTarget = widget.targetSec > 0 && elapsedSec > widget.targetSec;
    return ShadowRecordingCaptionRow(
      elapsedSec: elapsedSec,
      targetSec: widget.targetSec,
      overTarget: overTarget,
      overBySec: overTarget ? elapsedSec - widget.targetSec : 0.0,
      l10n: widget.l10n,
      tt: widget.tt,
      scheme: widget.scheme,
      tok: widget.tok,
    );
  }
}
