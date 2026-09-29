/// Circular play / pause control with buffering ring.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/colors.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_chrome_icon.dart';

/// Rides the aurora signature kit exactly like its sibling, the shadow-
/// reading record FAB: the lit fill via [enjoyLitFillDecoration], the press
/// interaction (wash, press-scale, keyboard activation, focus ring) via
/// [EnjoyPressable]. The kit's built-in tap haptic stays off because callers
/// wrap [onPressed] in `Haptics.wrapTap` — enabling both would double-fire.
class TransportPlayRingButton extends StatelessWidget {
  const TransportPlayRingButton({
    super.key,
    required this.playing,
    required this.buffering,
    required this.tooltip,
    required this.onPressed,
    this.accentColor,
  });

  final bool playing;
  final bool buffering;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);
    final ringColor = accentColor ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: tooltip,
        child: EnjoyPressable(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(46 / 2),
          pressedScale: 0.94,
          haptic: false,
          child: AnimatedContainer(
            duration: t.motionFast,
            width: 46,
            height: 46,
            decoration: enjoyLitFillDecoration(
              base: ringColor,
              shape: CircleBorder(side: enjoyLitHighlightSide(alpha: 0.16)),
              sheen: 0.14,
              shadow: enjoyLitShadow(
                ringColor,
                alpha: 0.38,
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ),
            child: Center(
              child: buffering
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: EnjoyChromeIcon(
                        playing
                            ? EnjoyChromeGlyph.pause
                            : EnjoyChromeGlyph.play,
                        key: ValueKey<bool>(playing),
                        color: AppColors.onAccent,
                        size: 20,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
