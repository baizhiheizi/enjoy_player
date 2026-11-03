/// Material theme skinned to the **Aurora** design language (ADR-0089).
///
/// Material is the widget toolkit, not the look: ink ripples are off,
/// shapes are continuous-corner (superellipse), elevation is replaced by
/// hairlines + soft ambient shadows, and every platform shares one page
/// transition (iOS keeps its native edge-swipe).
///
/// Composition root: shared state lives in `_AppThemeBase`; one mixin per
/// concern (buttons, inputs, surfaces, controls) lives in a sibling part
/// file and composes onto it.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'enjoy_tokens.dart';
import 'page_transitions.dart';
import 'typography.dart';

part 'app_theme_buttons.dart';
part 'app_theme_controls.dart';
part 'app_theme_inputs.dart';
part 'app_theme_surfaces.dart';

ThemeData? _cachedLight;
ThemeData? _cachedDark;

/// Continuous-corner shape used across Aurora surfaces.
RoundedSuperellipseBorder enjoyShape(double radius, {BorderSide? side}) {
  return RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side ?? BorderSide.none,
  );
}

/// Builds the Enjoy [ThemeData] for [brightness].
///
/// Results are cached per brightness. Existing call sites that omit
/// [brightness] still receive dark (historical default).
ThemeData buildAppTheme([Brightness brightness = Brightness.dark]) {
  if (brightness == Brightness.light) {
    return _cachedLight ??= _buildAppThemeImpl(Brightness.light);
  }
  return _cachedDark ??= _buildAppThemeImpl(Brightness.dark);
}

ThemeData _buildAppThemeImpl(Brightness brightness) {
  final cs = AppColors.colorScheme(brightness);
  final t = EnjoyThemeTokens.build(cs);
  final baseTheme = ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    brightness: brightness,
  );
  final tt = buildBaseTextTheme(baseTheme.textTheme, cs);
  final light = brightness == Brightness.light;

  return _AppTheme(
    brightness: brightness,
    cs: cs,
    t: t,
    tt: tt,
    hover: cs.onSurface.withValues(alpha: light ? 0.045 : 0.06),
    pressed: cs.onSurface.withValues(alpha: light ? 0.08 : 0.10),
    focus: cs.primary.withValues(alpha: 0.14),
    disabledFg: cs.onSurface.withValues(alpha: 0.36),
    disabledBg: cs.onSurface.withValues(alpha: light ? 0.06 : 0.08),
  ).build();
}

/// Shared theme state every concern mixin composes onto.
abstract class _AppThemeBase {
  _AppThemeBase({
    required this.brightness,
    required this.cs,
    required this.t,
    required this.tt,
    required this.hover,
    required this.pressed,
    required this.focus,
    required this.disabledFg,
    required this.disabledBg,
  });

  final Brightness brightness;
  final ColorScheme cs;
  final EnjoyThemeTokens t;
  final TextTheme tt;
  final Color hover;
  final Color pressed;
  final Color focus;
  final Color disabledFg;
  final Color disabledBg;

  bool get light => brightness == Brightness.light;

  WidgetStateProperty<Color?> overlay({
    Color? hoverColor,
    Color? pressedColor,
    Color? focusColor,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return pressedColor ?? pressed;
      if (states.contains(WidgetState.hovered)) return hoverColor ?? hover;
      if (states.contains(WidgetState.focused)) return focusColor ?? focus;
      return Colors.transparent;
    });
  }
}

/// The shared base plus one mixin per theme concern.
final class _AppTheme extends _AppThemeBase
    with
        _AppThemeButtons,
        _AppThemeControls,
        _AppThemeInputs,
        _AppThemeSurfaces {
  _AppTheme({
    required super.brightness,
    required super.cs,
    required super.t,
    required super.tt,
    required super.hover,
    required super.pressed,
    required super.focus,
    required super.disabledFg,
    required super.disabledBg,
  });

  ThemeData build() {
    final transcriptTokens = TranscriptTypographyTokens.build(
      useSerif: true,
      base: tt,
      scheme: cs,
    );

    return ThemeData(
      colorScheme: cs,
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: pressed,
      hoverColor: hover,
      focusColor: focus,
      canvasColor: t.raised,
      cardColor: t.paper,
      dividerColor: t.line,
      disabledColor: disabledFg,
      extensions: <ThemeExtension<dynamic>>[t, transcriptTokens],
      textTheme: tt,
      scaffoldBackgroundColor: Colors.transparent,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: cs.primary,
      ),
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      listTileTheme: listTileTheme,
      navigationBarTheme: navigationBarTheme,
      navigationRailTheme: navigationRailTheme,
      sliderTheme: sliderTheme,
      snackBarTheme: snackBarTheme,
      bottomSheetTheme: bottomSheetTheme,
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filledButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      iconButtonTheme: IconButtonThemeData(style: iconButtonStyle),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: segmentedButtonStyle,
        selectedIcon: const SizedBox.shrink(),
      ),
      toggleButtonsTheme: toggleButtonsTheme,
      switchTheme: switchTheme,
      checkboxTheme: checkboxTheme,
      radioTheme: radioTheme,
      iconTheme: iconTheme,
      primaryIconTheme: primaryIconTheme,
      dividerTheme: dividerTheme,
      dialogTheme: dialogTheme,
      popupMenuTheme: popupMenuTheme,
      menuTheme: menuTheme,
      dropdownMenuTheme: dropdownMenuTheme,
      tooltipTheme: tooltipTheme,
      inputDecorationTheme: inputDecorationTheme,
      chipTheme: chipTheme,
      badgeTheme: badgeTheme,
      progressIndicatorTheme: progressIndicatorTheme,
      tabBarTheme: tabBarTheme,
      expansionTileTheme: expansionTileTheme,
      textSelectionTheme: textSelectionTheme,
      pageTransitionsTheme: pageTransitionsTheme,
      scrollbarTheme: scrollbarTheme,
    );
  }
}

/// Status / navigation bar chrome that follows porcelain vs midnight.
SystemUiOverlayStyle enjoySystemUiOverlayStyle(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: dark
        ? AppColors.groundDark
        : AppColors.groundLight,
    systemNavigationBarIconBrightness: dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
