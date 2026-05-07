/// Material 3 theme configuration with premium modern-minimal tuning.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'enjoy_tokens.dart';

ThemeData buildAppTheme(Brightness brightness) {
  const seed = Color(0xFF0D47A1);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  final tokens = brightness == Brightness.light
      ? EnjoyThemeTokens.light(colorScheme)
      : EnjoyThemeTokens.dark(colorScheme);

  final baseTheme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  final navigationBarTheme = NavigationBarThemeData(
    height: 72,
    indicatorColor: colorScheme.secondaryContainer,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return textTheme.labelMedium?.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0.2,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(
        size: 24,
        color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
      );
    }),
  );

  final railTheme = NavigationRailThemeData(
    backgroundColor: colorScheme.surfaceContainerLow,
    indicatorColor: colorScheme.secondaryContainer,
    selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
    unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    ),
    unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    minWidth: 88,
    minExtendedWidth: 200,
  );

  final sliderTheme = SliderThemeData(
    trackHeight: 3,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    activeTrackColor: colorScheme.primary,
    inactiveTrackColor: colorScheme.surfaceContainerHighest,
    thumbColor: colorScheme.primary,
    overlayColor: colorScheme.primary.withValues(alpha: 0.12),
  );

  final snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
    ),
    backgroundColor: colorScheme.inverseSurface,
    contentTextStyle: textTheme.bodyMedium?.copyWith(
      color: colorScheme.onInverseSurface,
    ),
    actionTextColor: colorScheme.inversePrimary,
  );

  final bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: colorScheme.surfaceContainerHigh,
    surfaceTintColor: Colors.transparent,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusLg)),
    ),
    dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
    dragHandleSize: const Size(40, 4),
    showDragHandle: false,
  );

  final cardTheme = CardThemeData(
    elevation: tokens.elevationSurface,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
    ),
    color: colorScheme.surfaceContainerLow,
  );

  final listTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(
      horizontal: tokens.space16,
      vertical: tokens.space4,
    ),
    iconColor: colorScheme.onSurfaceVariant,
    titleTextStyle: textTheme.titleMedium,
    subtitleTextStyle: textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    minVerticalPadding: tokens.space12,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    extensions: <ThemeExtension<dynamic>>[tokens],
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: cardTheme,
    listTileTheme: listTileTheme,
    navigationBarTheme: navigationBarTheme,
    navigationRailTheme: railTheme,
    sliderTheme: sliderTheme,
    snackBarTheme: snackBarTheme,
    bottomSheetTheme: bottomSheetTheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space24,
          vertical: tokens.space12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        textStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0.2),
      ),
    ),
    // Do not set a global IconButton foregroundColor: it overrides
    // [IconButton.filled] (play/pause) and washes the icon on primary.
    iconTheme: IconThemeData(
      color: colorScheme.onSurfaceVariant,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      backgroundColor: colorScheme.surfaceContainerHigh,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      elevation: 3,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
