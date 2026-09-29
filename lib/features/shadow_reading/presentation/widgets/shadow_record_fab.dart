import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_progress_ring.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';

/// Record FAB with a circular countdown ring + over-target pulse animation.
///
/// Extracted from `shadow_reading_panel.dart` — see issue #180. The ring and
/// the lit inner button ride the aurora signature kit
/// ([EnjoyProgressRingPainter], [enjoyLitFillDecoration]).
class ShadowRecordFab extends StatelessWidget {
  const ShadowRecordFab({
    required this.recording,
    required this.echoActive,
    required this.ringProgress,
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
  final double ringProgress;
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
    final double arcProgress = !showProgressArc
        ? 0
        : overTarget
        ? 1
        : 1 - ringProgress;

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
              CustomPaint(
                size: const Size(ringOuterHitSize, ringOuterHitSize),
                painter: EnjoyProgressRingPainter(
                  progress: arcProgress,
                  trackColor: scheme.onSurface.withValues(
                    alpha: trackAlpha * 0.4,
                  ),
                  progressColor: overTarget ? scheme.error : scheme.primary,
                  strokeWidth: 4,
                ),
              ),
              EnjoyPressable(
                onTap: echoActive ? onTap : null,
                borderRadius: BorderRadius.circular(_fabInner / 2),
                child: AnimatedContainer(
                  duration: tok.motionFast,
                  width: _fabInner,
                  height: _fabInner,
                  decoration: enjoyLitFillDecoration(
                    base: litBase,
                    shape: CircleBorder(
                      side: enjoyLitHighlightSide(alpha: 0.16),
                    ),
                    sheen: 0.14,
                    shadow: enjoyLitShadow(
                      litBase,
                      alpha: recording ? 0.45 : 0.36,
                      blurRadius: recording ? 24 : 16,
                      spreadRadius: recording ? 1 : -3,
                    ),
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
