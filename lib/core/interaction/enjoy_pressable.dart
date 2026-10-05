/// Aurora press primitive — the tactile core behind custom tappables.
///
/// No ink ripple: a soft hover / press wash clipped to a continuous-corner
/// shape, a gentle press-scale, keyboard activation (Enter / Space), a focus
/// ring for keyboard users, the click cursor on desktop, and light haptics on
/// mobile. See ADR-0018 (shared primitives) and ADR-0089 (Aurora).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/interaction/mouse_tracker_safe.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class EnjoyPressable extends StatefulWidget {
  const EnjoyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.shape,
    this.pressedScale = 0.975,
    this.hoverScale = 1.0,
    this.showHoverWash = true,
    this.washColor,
    this.showFocusRing = true,
    this.haptic = true,
    this.semanticsLabel,
    this.excludeSemantics = false,
    this.selected,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.onHoverChanged,
  }) : assert(
         shape == null || borderRadius == null,
         'EnjoyPressable.shape owns the wash outline entirely — pass either '
         'shape or borderRadius, never both.',
       );

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Shape of the hover wash and focus ring. Defaults to [EnjoyThemeTokens.radiusMd].
  final BorderRadius? borderRadius;

  /// Full outline override for the hover/press wash and focus ring — pass
  /// [CircleBorder] for circular chrome so the wash does not read as a
  /// superellipse halo inside the true circle. When null (the default) the
  /// wash uses a [RoundedSuperellipseBorder] built from [borderRadius];
  /// when set, [borderRadius] must be omitted. Mutually exclusive with
  /// [borderRadius].
  final OutlinedBorder? shape;

  /// Scale while the pointer is down (1.0 disables).
  final double pressedScale;

  /// Scale while hovered by a mouse (1.0 disables).
  final double hoverScale;

  /// Paint a subtle hover / press wash over [child].
  final bool showHoverWash;

  /// Base color of the wash (defaults to `onSurface`).
  final Color? washColor;

  final bool showFocusRing;
  final bool haptic;
  final String? semanticsLabel;
  final bool excludeSemantics;
  final bool? selected;
  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<EnjoyPressable> createState() => _EnjoyPressableState();
}

class _EnjoyPressableState extends State<EnjoyPressable> {
  bool _hover = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setHover(bool value) {
    runOutsideMouseTrackerIfMounted(() => mounted, () {
      if (_hover == value) return;
      setState(() => _hover = value);
      widget.onHoverChanged?.call(value);
    });
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    if (widget.haptic) Haptics.selection(context);
    onTap();
  }

  BorderSide _ringSide(EnjoyThemeTokens t) {
    if (!_focused || !widget.showFocusRing) return BorderSide.none;
    return BorderSide(
      color: t.brandInk.withValues(alpha: 0.85),
      width: t.focusRingWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final instant = MediaQuery.disableAnimationsOf(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(t.radiusMd);
    final wash = widget.washColor ?? cs.onSurface;
    final light = Theme.of(context).brightness == Brightness.light;

    final double scale;
    if (instant || !_enabled) {
      scale = 1;
    } else if (_pressed) {
      scale = widget.pressedScale;
    } else if (_hover) {
      scale = widget.hoverScale;
    } else {
      scale = 1;
    }

    final double washAlpha;
    if (!widget.showHoverWash || !_enabled) {
      washAlpha = 0;
    } else if (_pressed) {
      washAlpha = light ? 0.07 : 0.09;
    } else if (_hover) {
      washAlpha = light ? 0.04 : 0.055;
    } else {
      washAlpha = 0;
    }

    final shape =
        widget.shape?.copyWith(side: _ringSide(t)) ??
        RoundedSuperellipseBorder(borderRadius: radius, side: _ringSide(t));

    Widget core = AnimatedContainer(
      duration: t.motionFast,
      curve: Curves.easeOutCubic,
      foregroundDecoration: ShapeDecoration(
        color: wash.withValues(alpha: washAlpha),
        shape: shape,
      ),
      child: widget.child,
    );

    core = AnimatedScale(
      scale: scale,
      duration: _pressed ? const Duration(milliseconds: 90) : t.motionFast,
      curve: _pressed ? Curves.easeOut : EnjoyThemeTokens.ease,
      child: core,
    );

    core = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap == null ? null : _activate,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _setPressed(false);
              if (widget.haptic) Haptics.impactMedium(context);
              widget.onLongPress!();
            },
      child: core,
    );

    core = FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          widget.mouseCursor ??
          (_enabled ? SystemMouseCursors.click : MouseCursor.defer),
      onShowHoverHighlight: _setHover,
      onShowFocusHighlight: (v) {
        if (_focused == v) return;
        setState(() => _focused = v);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      child: core,
    );

    return Semantics(
      button: _enabled,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticsLabel,
      excludeSemantics: widget.excludeSemantics,
      child: core,
    );
  }
}
