part of 'app_theme.dart';

mixin _AppThemeInputs on _AppThemeBase {
  late final BorderRadius inputRadius = BorderRadius.circular(t.radiusControl);

  late final MenuStyle menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(t.raised),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(12),
    shadowColor: WidgetStatePropertyAll(
      Colors.black.withValues(alpha: light ? 0.28 : 0.7),
    ),
    shape: WidgetStatePropertyAll(
      enjoyShape(t.radiusMd, side: BorderSide(color: t.line)),
    ),
    padding: WidgetStatePropertyAll(EdgeInsets.all(t.space4 + 2)),
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  late final PopupMenuThemeData popupMenuTheme = PopupMenuThemeData(
    color: t.raised,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black.withValues(alpha: light ? 0.28 : 0.7),
    shape: enjoyShape(t.radiusMd, side: BorderSide(color: t.line)),
    elevation: 12,
    textStyle: tt.bodyMedium,
    labelTextStyle: WidgetStatePropertyAll(tt.bodyMedium),
    menuPadding: EdgeInsets.all(t.space4 + 2),
    position: PopupMenuPosition.under,
    iconColor: cs.onSurfaceVariant,
    iconSize: 18,
  );

  late final MenuThemeData menuTheme = MenuThemeData(style: menuStyle);

  late final DropdownMenuThemeData dropdownMenuTheme = DropdownMenuThemeData(
    menuStyle: menuStyle,
    textStyle: tt.bodyMedium,
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: t.paper,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: t.space12,
        vertical: t.space8,
      ),
      border: inputBorder(t.line),
      enabledBorder: inputBorder(t.line),
      focusedBorder: inputBorder(t.original, 1.5),
    ),
  );

  late final TooltipThemeData tooltipTheme = TooltipThemeData(
    decoration: ShapeDecoration(
      color: t.ink,
      shape: enjoyShape(t.radiusSm - 1),
    ),
    textStyle: tt.labelSmall?.copyWith(
      color: t.ground,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    waitDuration: const Duration(milliseconds: 450),
    preferBelow: true,
    verticalOffset: 18,
  );

  late final InputDecorationThemeData inputDecorationTheme =
      InputDecorationThemeData(
        filled: true,
        fillColor: t.paper,
        hoverColor: Colors.transparent,
        border: inputBorder(t.line),
        enabledBorder: inputBorder(t.line),
        disabledBorder: inputBorder(t.line.withValues(alpha: 0.6)),
        focusedBorder: inputBorder(t.original, 1.5),
        errorBorder: inputBorder(cs.error.withValues(alpha: 0.7)),
        focusedErrorBorder: inputBorder(cs.error, 1.5),
        contentPadding: EdgeInsets.symmetric(
          horizontal: t.space12 + 2,
          vertical: t.space12,
        ),
        isDense: false,
        hintStyle: tt.bodyMedium?.copyWith(color: t.ink3),
        labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: tt.labelLarge?.copyWith(
          color: t.ink2,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        errorStyle: tt.bodySmall?.copyWith(color: cs.error),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 36,
        ),
        focusColor: focus,
      );
}
