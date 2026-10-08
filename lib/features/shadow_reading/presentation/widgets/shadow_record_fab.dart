import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_progress_ring.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';

/// Record FAB with a circular countdown ring + over-target pulse animation.
///
/// Extracted from `shadow_reading_panel.dart` — see issue #180. The ring and
/// the lit inner button ride the aurora signature kit
/// ([EnjoyProgressRingPainter]).
///
/// The ring is static ([ringProgress]) for the idle FAB, or driven per vsync
/// by a live elapsed-seconds animation ([ringElapsedSec] +
/// [ringTargetSec], issue #810 E2) which repaints without rebuilding this
/// widget.
class ShadowRecordFab extends StatelessWidget {
  const ShadowRecordFab({
    required this.recording,
    required this.echoActive,
    this.ringProgress = 0,
    this.ringElapsedSec,
    this.ringTargetSec,
    required this.overTarget,
    required this.overPulseHigh,
    required this.showProgressArc,
    required this.onTap,
    required this.scheme,
    required this.tok,
    super.key,
  });

  /// Outer hit target / ring diameter; keep in sync with the toolbar slot in
  /// [ShadowReadingToolbarRow].
  static const double ringOuterHitSize = 56;
  static const double _fabInner = 44;

  final bool recording;
  final bool echoActive;

  /// Ring completion fraction for the static ring (idle FAB).
  final double ringProgress;

  /// Live elapsed-seconds animation driving the recording ring.
  final Animation<double>? ringElapsedSec;

  /// Countdown target in seconds for [ringElapsedSec].
  final double? ringTargetSec;

  final bool overTarget;
  final bool overPulseHigh;
  final bool showProgressArc;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;

  @override
  Widget build(BuildContext context) {
    final scale = overTarget ? (overPulseHigh ? 1.04 : 1.0) : 1.0;
    final trackAlpha = showProgressArc ? 0.38 : 0.18;
    final iconSize = _fabInner <= 44 ? 22.0 : (_fabInner <= 56 ? 24.0 : 28.0);
    final litBase = recording ? tok.echoActive : scheme.primary;
    final trackColor = scheme.onSurface.withValues(alpha: trackAlpha * 0.4);
    final progressColor = overTarget ? scheme.error : scheme.primary;
    final elapsed = ringElapsedSec;
    final Widget ring = elapsed == null
        ? CustomPaint(
            size: const Size(ringOuterHitSize, ringOuterHitSize),
            painter: EnjoyProgressRingPainter(
              progress: !showProgressArc
                  ? 0
                  : overTarget
                  ? 1
                  : 1 - ringProgress,
              trackColor: trackColor,
              progressColor: progressColor,
              strokeWidth: 4,
            ),
          )
        : RepaintBoundary(
            child: CustomPaint(
              size: const Size(ringOuterHitSize, ringOuterHitSize),
              painter: _ElapsedRingPainter(
                elapsedSec: elapsed,
                targetSec: ringTargetSec ?? 0,
                overTarget: overTarget,
                trackColor: trackColor,
                progressColor: progressColor,
                strokeWidth: 4,
              ),
            ),
          );

    return OnboardingTarget(
      tipId: OnboardingTipId.playerRecord,
      onTargetAction: echoActive ? onTap : null,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: ringOuterHitSize,
          height: ringOuterHitSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ring,
              EnjoyPressable(
                onTap: echoActive ? onTap : null,
                borderRadius: BorderRadius.circular(_fabInner / 2),
                child: AnimatedContainer(
                  duration: tok.motionFast,
                  width: _fabInner,
                  height: _fabInner,
                  decoration: ShapeDecoration(
                    color: litBase,
                    shape: const CircleBorder(),
                    shadows: [
                      BoxShadow(
                        color: litBase.withValues(
                          alpha: recording ? 0.45 : 0.32,
                        ),
                        blurRadius: recording ? 24 : 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    recording ? EnjoyIcons.stop : EnjoyIcons.micFill,
                    color: recording ? Colors.white : scheme.onPrimary,
                    size: iconSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Countdown ring repainting per vsync off the elapsed-seconds animation,
/// without an element rebuild per frame (issue #810 E2).
class _ElapsedRingPainter extends CustomPainter {
  _ElapsedRingPainter({
    required this.elapsedSec,
    required this.targetSec,
    required this.overTarget,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  }) : super(repaint: elapsedSec);

  final Animation<double> elapsedSec;
  final double targetSec;
  final bool overTarget;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final arcProgress = overTarget || targetSec <= 0
        ? 1.0
        : 1.0 - (elapsedSec.value / targetSec).clamp(0.0, 1.0);
    EnjoyProgressRingPainter(
      progress: arcProgress,
      trackColor: trackColor,
      progressColor: progressColor,
      strokeWidth: strokeWidth,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _ElapsedRingPainter oldDelegate) {
    return oldDelegate.targetSec != targetSec ||
        oldDelegate.overTarget != overTarget ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
