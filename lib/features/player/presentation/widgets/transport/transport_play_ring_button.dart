/// Circular play / pause control with buffering ring.
library;

import 'package:flutter/material.dart';

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
    final ringColor = accentColor ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child:
                    buffering
                        ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ringColor,
                          ),
                        )
                        : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: cs.onSurface,
                          size: 26,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
