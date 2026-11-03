part of 'app_theme.dart';

mixin _AppThemeButtons on _AppThemeBase {
  late final WidgetStateProperty<OutlinedBorder> buttonShape =
      WidgetStatePropertyAll<OutlinedBorder>(enjoyShape(t.radiusMd));

  late final WidgetStateProperty<Size> buttonMinSize =
      WidgetStatePropertyAll<Size>(Size(64, t.controlHeight));

  late final WidgetStateProperty<EdgeInsetsGeometry> buttonPadding =
      WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: t.space16 + 2),
      );

  late final WidgetStateProperty<TextStyle?> buttonText =
      WidgetStatePropertyAll<TextStyle?>(
        tt.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      );

  late final ButtonStyle filledButtonStyle = ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: buttonShape,
    minimumSize: buttonMinSize,
    padding: buttonPadding,
    textStyle: buttonText,
    splashFactory: NoSplash.splashFactory,
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledBg : cs.primary,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : cs.onPrimary,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : cs.onPrimary,
    ),
    iconSize: const WidgetStatePropertyAll(17),
    overlayColor: overlay(
      hoverColor: Colors.white.withValues(alpha: 0.10),
      pressedColor: Colors.black.withValues(alpha: 0.12),
      focusColor: Colors.white.withValues(alpha: 0.14),
    ),
  );

  late final ButtonStyle outlinedButtonStyle = ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: buttonShape,
    minimumSize: buttonMinSize,
    padding: buttonPadding,
    textStyle: buttonText,
    splashFactory: NoSplash.splashFactory,
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? Colors.transparent : t.paper,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : cs.onSurface,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : cs.onSurface,
    ),
    iconSize: const WidgetStatePropertyAll(17),
    side: WidgetStateProperty.resolveWith(
      (s) => BorderSide(
        color: s.contains(WidgetState.disabled)
            ? cs.outlineVariant
            : (light ? cs.outline.withValues(alpha: 0.75) : cs.outline),
      ),
    ),
    overlayColor: overlay(),
  );

  late final ButtonStyle textButtonStyle = ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: buttonShape,
    minimumSize: WidgetStatePropertyAll(Size(48, t.controlHeightSm + 4)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: t.space12),
    ),
    textStyle: buttonText,
    splashFactory: NoSplash.splashFactory,
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : t.brandInk,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : t.brandInk,
    ),
    iconSize: const WidgetStatePropertyAll(17),
    overlayColor: overlay(
      hoverColor: t.brandInk.withValues(alpha: 0.08),
      pressedColor: t.brandInk.withValues(alpha: 0.14),
    ),
  );

  late final ButtonStyle iconButtonStyle = ButtonStyle(
    shape: WidgetStatePropertyAll(enjoyShape(t.radiusMd - 2)),
    splashFactory: NoSplash.splashFactory,
    iconSize: const WidgetStatePropertyAll(20),
    foregroundColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.disabled)) return disabledFg;
      if (s.contains(WidgetState.selected)) return t.brandInk;
      return cs.onSurfaceVariant;
    }),
    overlayColor: overlay(),
  );

  late final ButtonStyle segmentedButtonStyle = ButtonStyle(
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: WidgetStatePropertyAll(
      tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    shape: WidgetStatePropertyAll(enjoyShape(t.radiusSm + 1)),
    side: WidgetStatePropertyAll(BorderSide(color: t.line)),
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? t.paper : t.fill,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) =>
          s.contains(WidgetState.selected) ? cs.onSurface : cs.onSurfaceVariant,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (s) =>
          s.contains(WidgetState.selected) ? t.brandInk : cs.onSurfaceVariant,
    ),
    overlayColor: overlay(),
  );

  late final ToggleButtonsThemeData toggleButtonsTheme = ToggleButtonsThemeData(
    borderRadius: BorderRadius.circular(t.radiusSm),
    borderColor: t.line,
    selectedBorderColor: t.line,
    fillColor: t.paper,
    selectedColor: cs.onSurface,
    color: cs.onSurfaceVariant,
  );
}
