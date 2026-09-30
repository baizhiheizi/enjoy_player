/// Live recording stage: paint-only countdown ring + 10 Hz caption.
///
/// Extracted from `shadow_reading_panel.dart` (issue #810 E2): a single
/// [Ticker] is the only timing source — each vsync it sets the elapsed
/// seconds on an [AnimationController] that exists purely as the painter's
/// `repaint:` listenable (so the ring repaints without rebuilding any
/// element), re-evaluates the over-target pulse phase, and bumps a
/// `ValueNotifier<int>` of tenths-of-a-second. The caption is a
/// `ValueListenableBuilder` over that notifier, so it rebuilds 10 times a
/// second and never per frame, and no second timer runs (issue #818). The
/// notifier — not the `Animation` — is the caption's input deliberately:
/// a `ListenableBuilder` on the controller would rebuild the caption on
/// every vsync, which is exactly the cost this design avoids.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
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
  static const _kOverPulseStepMs = 600;

  late final AnimationController _elapsedSec = AnimationController.unbounded(
    vsync: this,
  );
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<int> _elapsedTenths = ValueNotifier<int>(0);
  bool _overPulseHigh = false;
  bool _over = false;
  int _overStartMs = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsedSec.dispose();
    _elapsedTenths.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsedSec.value = elapsed.inMicroseconds / 1e6;
    final tenths = (elapsed.inMicroseconds ~/ 100000);
    if (tenths != _elapsedTenths.value) _elapsedTenths.value = tenths;
    final over = widget.targetSec > 0 && _elapsedSec.value > widget.targetSec;
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
          elapsedTenths: _elapsedTenths,
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

class _ShadowRecordingCaption extends StatelessWidget {
  const _ShadowRecordingCaption({
    required this.elapsedTenths,
    required this.targetSec,
    required this.l10n,
    required this.tt,
    required this.scheme,
    required this.tok,
  });

  final ValueListenable<int> elapsedTenths;
  final double targetSec;
  final AppLocalizations l10n;
  final TextTheme tt;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: elapsedTenths,
      builder: (context, tenths, _) {
        final elapsedSec = tenths / 10;
        final overTarget = targetSec > 0 && elapsedSec > targetSec;
        return ShadowRecordingCaptionRow(
          elapsedSec: elapsedSec,
          targetSec: targetSec,
          overTarget: overTarget,
          overBySec: overTarget ? elapsedSec - targetSec : 0.0,
          l10n: l10n,
          tt: tt,
          scheme: scheme,
          tok: tok,
        );
      },
    );
  }
}
