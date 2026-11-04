part of 'app_theme.dart';

mixin _AppThemeControls on _AppThemeBase {
  SliderThemeData get sliderTheme => SliderThemeData(
    // ignore: deprecated_member_use
    year2023: true,
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 8,
      elevation: 2,
      pressedElevation: 3,
    ),
    overlayShape: SliderComponentShape.noOverlay,
    activeTrackColor: t.original,
    inactiveTrackColor: t.sunk,
    thumbColor: Colors.white,
    overlayColor: Colors.transparent,
    valueIndicatorColor: t.ink,
    valueIndicatorTextStyle: tt.labelSmall?.copyWith(color: t.ground),
  );

  SwitchThemeData get switchTheme => SwitchThemeData(
    thumbIcon: const WidgetStatePropertyAll(Icon(null)),
    thumbColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.disabled)) {
        return light ? const Color(0xFFF4F4F6) : const Color(0xFF5A5A64);
      }
      return Colors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.selected)) {
        return s.contains(WidgetState.disabled)
            ? cs.primary.withValues(alpha: 0.4)
            : cs.primary;
      }
      return light ? const Color(0xFFDCDCE3) : const Color(0xFF34343D);
    }),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    trackOutlineWidth: const WidgetStatePropertyAll(0),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    splashRadius: 0,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  CheckboxThemeData get checkboxTheme => CheckboxThemeData(
    shape: enjoyShape(5),
    side: WidgetStateBorderSide.resolveWith(
      (s) => s.contains(WidgetState.selected)
          ? BorderSide(color: cs.primary, width: 1.5)
          : BorderSide(color: cs.outline, width: 1.5),
    ),
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? cs.primary : Colors.transparent,
    ),
    checkColor: const WidgetStatePropertyAll(Colors.white),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    splashRadius: 0,
  );

  RadioThemeData get radioTheme => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? cs.primary : cs.outline,
    ),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    splashRadius: 0,
  );

  ProgressIndicatorThemeData get progressIndicatorTheme =>
      ProgressIndicatorThemeData(
        // ignore: deprecated_member_use
        year2023: true,
        color: cs.primary,
        linearTrackColor: t.fill,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
        borderRadius: BorderRadius.circular(t.radiusFull),
        strokeCap: StrokeCap.round,
      );

  TextSelectionThemeData get textSelectionTheme => TextSelectionThemeData(
    cursorColor: t.original,
    selectionColor: t.originalSoft,
    selectionHandleColor: t.original,
  );

  PageTransitionsTheme get pageTransitionsTheme => const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: EnjoyGlidePageTransitionsBuilder(),
      TargetPlatform.android: EnjoyGlidePageTransitionsBuilder(),
      TargetPlatform.fuchsia: EnjoyGlidePageTransitionsBuilder(),
      TargetPlatform.linux: EnjoyGlidePageTransitionsBuilder(),
      TargetPlatform.windows: EnjoyGlidePageTransitionsBuilder(),
    },
  );

  ScrollbarThemeData get scrollbarTheme => ScrollbarThemeData(
    thickness: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.hovered) ? 8 : 5,
    ),
    radius: Radius.circular(t.radiusFull),
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => t.ink3.withValues(
        alpha: s.contains(WidgetState.dragged)
            ? 0.6
            : s.contains(WidgetState.hovered)
            ? 0.5
            : 0.4,
      ),
    ),
    crossAxisMargin: 3,
    mainAxisMargin: 6,
  );
}
