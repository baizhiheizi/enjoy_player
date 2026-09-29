/// Aurora action buttons — consistent haptics, sizes, and a lit primary.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

enum EnjoyButtonVariant { primary, secondary, tonal, ghost, destructive }

enum EnjoyButtonSize { small, medium, large }

/// The lit fill's 1px inner top highlight (ADR-0089 §6), exposed as the
/// [ShapeBorder.side] of the fill's shape.
BorderSide enjoyLitHighlightSide({double alpha = 0.14}) =>
    BorderSide(color: Colors.white.withValues(alpha: alpha));

/// The lit fill's tinted drop shadow — pooled light under the control rather
/// than Material elevation. Circular signature controls (the record FAB, the
/// transport play ring) tune the intensity; buttons use the defaults.
BoxShadow enjoyLitShadow(
  Color base, {
  double alpha = 0.32,
  double blurRadius = 14,
  double spreadRadius = -5,
  Offset offset = const Offset(0, 5),
}) => BoxShadow(
  color: base.withValues(alpha: alpha),
  blurRadius: blurRadius,
  spreadRadius: spreadRadius,
  offset: offset,
);

/// The lit fill (ADR-0089 §6) as one [ShapeDecoration]: a gentle top sheen
/// over [fill] (defaults to [base]) plus a single tinted drop shadow. This is
/// the decoration-level export behind [enjoyLitFillBuilder] — circular
/// signature controls paint it with a [CircleBorder] (highlight attached via
/// [enjoyLitHighlightSide]), while the button builder layers the highlight in
/// front so the shadow stays cast by the un-stroked path. Pass `shadow: null`
/// to suppress the glow (pressed states).
ShapeDecoration enjoyLitFillDecoration({
  required Color base,
  required ShapeBorder shape,
  Color? fill,
  double sheen = 0.10,
  BoxShadow? shadow,
}) {
  final resolved = fill ?? base;
  return ShapeDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(resolved, Colors.white, sheen)!, resolved],
    ),
    shape: shape,
    shadows: shadow == null ? const [] : [shadow],
  );
}

/// Background painter for lit (primary / destructive-solid) fills: a gentle
/// top sheen, a 1px inner top highlight, and a soft tinted drop shadow. Hover
/// brightens and press deepens the fill itself so the label never fades.
Widget enjoyLitFillBuilder(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child, {
  required Color base,
  required double radius,
}) {
  if (states.contains(WidgetState.disabled)) {
    return child ?? const SizedBox.shrink();
  }
  final pressed = states.contains(WidgetState.pressed);
  final hovered = states.contains(WidgetState.hovered);
  final fill = pressed
      ? Color.lerp(base, Colors.black, 0.10)!
      : hovered
      ? Color.lerp(base, Colors.white, 0.08)!
      : base;
  return DecoratedBox(
    decoration: enjoyLitFillDecoration(
      base: base,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      fill: fill,
      sheen: pressed ? 0.02 : 0.10,
      shadow: pressed ? null : enjoyLitShadow(base),
    ),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius),
          side: enjoyLitHighlightSide(),
        ),
      ),
      child: child,
    ),
  );
}

class EnjoyButton extends StatefulWidget {
  const EnjoyButton._({
    super.key,
    required this.variant,
    required this.onPressed,
    this.icon,
    this.size = EnjoyButtonSize.medium,
    this.expand = false,
    required this.child,
  });

  factory EnjoyButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icon,
    EnjoyButtonSize size = EnjoyButtonSize.medium,
    bool expand = false,
  }) => EnjoyButton._(
    variant: EnjoyButtonVariant.primary,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    key: key,
    child: child,
  );

  factory EnjoyButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icon,
    EnjoyButtonSize size = EnjoyButtonSize.medium,
    bool expand = false,
  }) => EnjoyButton._(
    variant: EnjoyButtonVariant.secondary,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    key: key,
    child: child,
  );

  /// Soft accent wash — secondary emphasis that still reads as "brand".
  factory EnjoyButton.tonal({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icon,
    EnjoyButtonSize size = EnjoyButtonSize.medium,
    bool expand = false,
  }) => EnjoyButton._(
    variant: EnjoyButtonVariant.tonal,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    key: key,
    child: child,
  );

  factory EnjoyButton.ghost({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icon,
    EnjoyButtonSize size = EnjoyButtonSize.medium,
    bool expand = false,
  }) => EnjoyButton._(
    variant: EnjoyButtonVariant.ghost,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    key: key,
    child: child,
  );

  factory EnjoyButton.destructive({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icon,
    EnjoyButtonSize size = EnjoyButtonSize.medium,
    bool expand = false,
  }) => EnjoyButton._(
    variant: EnjoyButtonVariant.destructive,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    key: key,
    child: child,
  );

  final EnjoyButtonVariant variant;
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final EnjoyButtonSize size;

  /// Stretch to the parent's width (form / sheet footers).
  final bool expand;

  @override
  State<EnjoyButton> createState() => _EnjoyButtonState();
}

class _EnjoyButtonState extends State<EnjoyButton> {
  final _states = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStates);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_onStates)
      ..dispose();
    super.dispose();
  }

  void _onStates() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (pressed != _pressed && mounted) setState(() => _pressed = pressed);
  }

  void _handleTap(BuildContext context) {
    if (widget.onPressed == null) return;
    Haptics.selection(context);
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final light = Theme.of(context).brightness == Brightness.light;

    final (height, hPad, iconSize, fontSize, radius) = switch (widget.size) {
      EnjoyButtonSize.small => (
        t.controlHeightSm,
        t.space12,
        15.0,
        13.0,
        t.radiusSm + 1,
      ),
      EnjoyButtonSize.medium => (
        t.controlHeight,
        t.space16 + 2,
        17.0,
        14.0,
        t.radiusMd,
      ),
      EnjoyButtonSize.large => (
        t.controlHeightLg,
        t.space24,
        18.0,
        15.0,
        t.radiusMd + 2,
      ),
    };

    final label = widget.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: iconSize),
              SizedBox(width: t.space8 - 1),
              Flexible(child: widget.child),
            ],
          )
        : widget.child;

    final tap = widget.onPressed == null ? null : () => _handleTap(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final disabledFg = cs.onSurface.withValues(alpha: 0.36);
    final disabledBg = cs.onSurface.withValues(alpha: light ? 0.06 : 0.08);

    ButtonStyle base({
      required Color background,
      required Color foreground,
      BorderSide? side,
      Color? hoverWash,
      ButtonLayerBuilder? backgroundBuilder,
    }) {
      final wash = hoverWash ?? cs.onSurface;
      return ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabledBg : background,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabledFg : foreground,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabledFg : foreground,
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (backgroundBuilder != null) return Colors.transparent;
          if (states.contains(WidgetState.pressed)) {
            return wash.withValues(alpha: light ? 0.08 : 0.11);
          }
          if (states.contains(WidgetState.hovered)) {
            return wash.withValues(alpha: light ? 0.045 : 0.07);
          }
          if (states.contains(WidgetState.focused)) {
            return wash.withValues(alpha: 0.10);
          }
          return Colors.transparent;
        }),
        side: side == null
            ? null
            : WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.disabled)
                    ? BorderSide(color: t.hairline)
                    : side,
              ),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: hPad)),
        minimumSize: WidgetStatePropertyAll(
          Size(widget.expand ? double.infinity : 48, height),
        ),
        fixedSize: widget.expand
            ? WidgetStatePropertyAll(Size.fromHeight(height))
            : null,
        textStyle: WidgetStatePropertyAll(
          tt.labelLarge?.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
        iconSize: WidgetStatePropertyAll(iconSize),
        shape: WidgetStatePropertyAll(shape),
        elevation: const WidgetStatePropertyAll(0),
        splashFactory: NoSplash.splashFactory,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        backgroundBuilder: backgroundBuilder,
      );
    }

    Widget button;
    switch (widget.variant) {
      case EnjoyButtonVariant.primary:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(
            background: Colors.transparent,
            foreground: cs.onPrimary,
            backgroundBuilder: (context, states, child) => enjoyLitFillBuilder(
              context,
              states,
              child,
              base: cs.primary,
              radius: radius,
            ),
          ),
          child: label,
        );
      case EnjoyButtonVariant.secondary:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(
            background: t.card,
            foreground: cs.onSurface,
            side: BorderSide(
              color: light ? cs.outline.withValues(alpha: 0.7) : cs.outline,
            ),
          ),
          child: label,
        );
      case EnjoyButtonVariant.tonal:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(
            background: t.accentSoft,
            foreground: t.accentInk,
            hoverWash: t.accentInk,
          ),
          child: label,
        );
      case EnjoyButtonVariant.ghost:
        button = TextButton(
          onPressed: tap,
          statesController: _states,
          style: base(background: Colors.transparent, foreground: cs.onSurface),
          child: label,
        );
      case EnjoyButtonVariant.destructive:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(
            background: cs.error.withValues(alpha: light ? 0.09 : 0.14),
            foreground: cs.error,
            hoverWash: cs.error,
          ),
          child: label,
        );
    }

    final instant = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _pressed && !instant ? 0.97 : 1,
      duration: _pressed ? const Duration(milliseconds: 90) : t.motionFast,
      curve: _pressed ? Curves.easeOut : EnjoyThemeTokens.ease,
      child: button,
    );
  }
}

/// Square icon-only action (continuous corners) in the same variants as
/// [EnjoyButton] — for compact headers and toolbars.
class EnjoyIconButton extends StatelessWidget {
  const EnjoyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = EnjoyButtonVariant.secondary,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final EnjoyButtonVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final radius = size * 0.32;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      EnjoyButtonVariant.primary => (
        Colors.transparent,
        cs.onPrimary,
        BorderSide.none,
      ),
      EnjoyButtonVariant.secondary => (
        t.card,
        cs.onSurface,
        BorderSide(
          color: light ? cs.outline.withValues(alpha: 0.7) : cs.outline,
        ),
      ),
      EnjoyButtonVariant.tonal => (t.accentSoft, t.accentInk, BorderSide.none),
      EnjoyButtonVariant.ghost => (
        Colors.transparent,
        cs.onSurfaceVariant,
        BorderSide.none,
      ),
      EnjoyButtonVariant.destructive => (
        cs.error.withValues(alpha: light ? 0.09 : 0.14),
        cs.error,
        BorderSide.none,
      ),
    };
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              Haptics.selection(context);
              onPressed!();
            },
      icon: Icon(icon, size: size * 0.48),
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(Size(size, size)),
        minimumSize: WidgetStatePropertyAll(Size(size, size)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(bg),
        foregroundColor: WidgetStatePropertyAll(fg),
        side: WidgetStatePropertyAll(side),
        shape: WidgetStatePropertyAll(
          RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundBuilder: variant == EnjoyButtonVariant.primary
            ? (context, states, child) => enjoyLitFillBuilder(
                context,
                states,
                child,
                base: cs.primary,
                radius: radius,
              )
            : null,
      ),
    );
  }
}
