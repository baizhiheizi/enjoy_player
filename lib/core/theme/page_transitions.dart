/// Aurora page transition — one motion language on every platform except iOS
/// (which keeps [CupertinoPageTransitionsBuilder] for the native edge-swipe).
library;

import 'package:flutter/material.dart';

import 'enjoy_tokens.dart';

/// Incoming page fades in while gliding 24px from the trailing edge; the
/// outgoing page recedes 12px and fades. Short, soft, directional —
/// never the Android zoom or the Windows fade-upwards.
class EnjoyGlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const EnjoyGlidePageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _EnjoyGlideTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _EnjoyGlideTransition extends StatelessWidget {
  const _EnjoyGlideTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dir = rtl ? -1.0 : 1.0;
    final enter = CurvedAnimation(
      parent: animation,
      curve: EnjoyThemeTokens.ease,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: EnjoyThemeTokens.ease,
      reverseCurve: Curves.easeInCubic,
    );
    // Shell pages are transparent (the canvas / content panel paints behind
    // them), so the outgoing page must fade out too or its text would ghost
    // through the incoming page.
    final exitFade = ReverseAnimation(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
        reverseCurve: const Interval(0.45, 1, curve: Curves.easeIn),
      ),
    );
    return FadeTransition(
      opacity: exitFade,
      child: FadeTransition(
        opacity: enter,
        child: AnimatedBuilder(
          animation: Listenable.merge([enter, exit]),
          child: child,
          builder: (context, child) {
            final inDx = (1 - enter.value) * 24 * dir;
            final outDx = -exit.value * 12 * dir;
            return Transform.translate(
              offset: Offset(inDx + outDx, 0),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
