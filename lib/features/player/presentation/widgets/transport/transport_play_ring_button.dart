/// Circular play / pause control with buffering ring.
library;

import 'package:flutter/material.dart';

class TransportPlayRingButton extends StatefulWidget {
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
  State<TransportPlayRingButton> createState() => _TransportPlayRingButtonState();
}

class _TransportPlayRingButtonState extends State<TransportPlayRingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringColor = widget.accentColor ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: widget.tooltip,
        child: Listener(
          onPointerDown:
              widget.onPressed == null
                  ? null
                  : (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: AnimatedScale(
                scale: _pressed ? 0.94 : 1,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOutCubic,
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
                        widget.buffering
                            ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ringColor,
                              ),
                            )
                            : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: Icon(
                                widget.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                key: ValueKey<bool>(widget.playing),
                                color: cs.onSurface,
                                size: 26,
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
