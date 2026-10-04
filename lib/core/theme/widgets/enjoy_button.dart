/// Duet action buttons — consistent haptics, sizes, and one brand gradient.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

enum EnjoyButtonVariant { brand, primary, secondary, tonal, ghost, destructive }

enum EnjoyButtonSize { small, medium, large }

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

  /// The brand gradient with a white label — the one brand action per screen.
  factory EnjoyButton.brand({
    Key? key,
    required VoidCallback? onPressed,
    required Widget child,
    IconData? icon,
    EnjoyButtonSize size = EnjoyButtonSize.medium,
    bool expand = false,
  }) => EnjoyButton._(
    variant: EnjoyButtonVariant.brand,
    onPressed: onPressed,
    icon: icon,
    size: size,
    expand: expand,
    key: key,
    child: child,
  );

  /// Ink fill (`Choose file`, `Continue with Apple`, `Create`).
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

  /// Legacy name of [secondary]; removed in the D5.1 rename pass.
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

    final (height, hPad, iconSize, fontSize) = switch (widget.size) {
      EnjoyButtonSize.small => (t.controlHeightSm, t.space12, 15.0, 13.0),
      EnjoyButtonSize.medium => (t.controlHeight, t.space16 + 2, 17.0, 14.0),
      EnjoyButtonSize.large => (t.controlHeightLg, t.space24, 18.0, 15.0),
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
      borderRadius: BorderRadius.circular(t.radiusControl),
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
                    ? BorderSide(color: t.line)
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
      case EnjoyButtonVariant.brand:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(
            background: Colors.transparent,
            foreground: Colors.white,
            backgroundBuilder: (context, states, child) => _BrandFill(
              t: t,
              states: states,
              radius: t.radiusControl,
              child: child,
            ),
          ),
          child: label,
        );
      case EnjoyButtonVariant.primary:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(background: t.primary, foreground: t.onPrimary),
          child: label,
        );
      case EnjoyButtonVariant.secondary:
      case EnjoyButtonVariant.tonal:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(
            background: t.paper,
            foreground: cs.onSurface,
            side: BorderSide(color: t.line),
          ),
          child: label,
        );
      case EnjoyButtonVariant.ghost:
        button = TextButton(
          onPressed: tap,
          statesController: _states,
          style: base(background: Colors.transparent, foreground: t.ink2),
          child: label,
        );
      case EnjoyButtonVariant.destructive:
        button = FilledButton(
          onPressed: tap,
          statesController: _states,
          style: base(background: t.danger, foreground: Colors.white),
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

class _BrandFill extends StatelessWidget {
  const _BrandFill({
    required this.t,
    required this.states,
    required this.radius,
    required this.child,
  });

  final EnjoyThemeTokens t;
  final Set<WidgetState> states;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final wash = states.contains(WidgetState.pressed)
        ? Colors.black.withValues(alpha: 0.08)
        : states.contains(WidgetState.hovered)
        ? Colors.white.withValues(alpha: 0.06)
        : null;
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: t.brand,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        shadows: states.contains(WidgetState.disabled)
            ? const []
            : t.shadowBrandButton,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          color: wash,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: child,
      ),
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
    this.size,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final EnjoyButtonVariant variant;

  /// Fixed edge; defaults to 40 on desktop and 44 on phone.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final resolvedSize =
        size ??
        (MediaQuery.sizeOf(context).width < t.breakpointCompact
            ? t.iconButtonSizePhone
            : t.iconButtonSize);
    final radius = resolvedSize * 0.32;
    final (
      Color bg,
      Color fg,
      BorderSide side,
      ButtonLayerBuilder? builder,
    ) = switch (variant) {
      EnjoyButtonVariant.brand => (
        Colors.transparent,
        Colors.white,
        BorderSide.none,
        (context, states, child) =>
            _BrandFill(t: t, states: states, radius: radius, child: child),
      ),
      EnjoyButtonVariant.primary => (
        t.primary,
        t.onPrimary,
        BorderSide.none,
        null,
      ),
      EnjoyButtonVariant.secondary => (
        t.paper,
        cs.onSurface,
        BorderSide(color: t.line),
        null,
      ),
      EnjoyButtonVariant.tonal => (
        t.paper,
        cs.onSurface,
        BorderSide(color: t.line),
        null,
      ),
      EnjoyButtonVariant.ghost => (
        Colors.transparent,
        t.ink2,
        BorderSide.none,
        null,
      ),
      EnjoyButtonVariant.destructive => (
        t.danger,
        Colors.white,
        BorderSide.none,
        null,
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
      icon: Icon(icon, size: resolvedSize * 0.48),
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(Size(resolvedSize, resolvedSize)),
        minimumSize: WidgetStatePropertyAll(Size(resolvedSize, resolvedSize)),
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
        splashFactory: NoSplash.splashFactory,
        backgroundBuilder: builder,
      ),
    );
  }
}
