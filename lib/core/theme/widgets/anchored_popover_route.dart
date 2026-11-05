/// The shared anchored-popover route (ADR-0018).
library;

import 'package:flutter/material.dart';

/// Resolves the insets between the anchored edge and the popover's child.
typedef AnchoredPopoverInsets =
    EdgeInsetsGeometry Function(BuildContext context);

EdgeInsetsGeometry _noInsets(BuildContext context) => EdgeInsets.zero;

/// A [PopupRoute] that anchors its child to a screen edge.
///
/// The player parks its video surface under an anchored popover (ADR-0066).
/// This route owns the shared skeleton: a transparent dismissible barrier, a
/// barrier label for screen readers, the anchored placement, and a fade
/// (optionally with a slide) transition.
class AnchoredPopoverRoute<T> extends PopupRoute<T> {
  AnchoredPopoverRoute({
    required this.builder,
    required this.barrierLabel,
    this.alignment = Alignment.topRight,
    this.insets = _noInsets,
    this.transitionDuration = const Duration(milliseconds: 140),
    this.reverseTransitionDuration = const Duration(milliseconds: 100),
    this.slideOffset,
    this.slideCurve = Curves.easeOut,
    this.fade = true,
  });

  /// Builds the popover's content.
  final WidgetBuilder builder;

  /// The barrier's accessible label; also makes the barrier dismissible for
  /// screen readers.
  @override
  final String barrierLabel;

  /// Which edge the child is anchored to.
  final Alignment alignment;

  /// The insets between the anchored edge and the child.
  final AnchoredPopoverInsets insets;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  /// Where the child slides in from; no slide when null.
  final Offset? slideOffset;

  /// The curve of the slide; the fade always uses [Curves.easeOut].
  final Curve slideCurve;

  /// Whether the child fades in.
  final bool fade;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Align(
      alignment: alignment,
      child: Padding(padding: insets(context), child: builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    Widget result = child;
    final slideOffset = this.slideOffset;
    if (slideOffset != null) {
      result = SlideTransition(
        position: Tween<Offset>(
          begin: slideOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: slideCurve)),
        child: result,
      );
    }
    if (fade) {
      result = FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: result,
      );
    }
    return result;
  }
}
