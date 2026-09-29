/// Material theme skinned to the **Aurora** design language (ADR-0089).
///
/// Material is the widget toolkit, not the look: ink ripples are off,
/// shapes are continuous-corner (superellipse), elevation is replaced by
/// hairlines + soft ambient shadows, and every platform shares one page
/// transition (iOS keeps its native edge-swipe).
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'enjoy_tokens.dart';
import 'page_transitions.dart';
import 'typography.dart';

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
  final light = brightness == Brightness.light;
  final cs = AppColors.colorScheme(brightness);
  final t = EnjoyThemeTokens.build(cs);

  final baseTheme = ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    brightness: brightness,
  );
  final tt = buildBaseTextTheme(baseTheme.textTheme, cs);

  final transcriptTokens = TranscriptTypographyTokens.build(
    useSerif: true,
    base: tt,
    scheme: cs,
  );

  final hover = cs.onSurface.withValues(alpha: light ? 0.045 : 0.06);
  final pressed = cs.onSurface.withValues(alpha: light ? 0.08 : 0.10);
  final focus = cs.primary.withValues(alpha: 0.14);

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

  final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
    enjoyShape(t.radiusMd),
  );
  final buttonMinSize = WidgetStatePropertyAll<Size>(Size(64, t.controlHeight));
  final buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
    EdgeInsets.symmetric(horizontal: t.space16 + 2),
  );
  final buttonText = WidgetStatePropertyAll<TextStyle?>(
    tt.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
  );
  final disabledFg = cs.onSurface.withValues(alpha: 0.36);
  final disabledBg = cs.onSurface.withValues(alpha: light ? 0.06 : 0.08);

  final filledButtonStyle = ButtonStyle(
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

  final outlinedButtonStyle = ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: buttonShape,
    minimumSize: buttonMinSize,
    padding: buttonPadding,
    textStyle: buttonText,
    splashFactory: NoSplash.splashFactory,
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? Colors.transparent : t.card,
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

  final textButtonStyle = ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shape: buttonShape,
    minimumSize: WidgetStatePropertyAll(Size(48, t.controlHeightSm + 4)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: t.space12),
    ),
    textStyle: buttonText,
    splashFactory: NoSplash.splashFactory,
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : t.accentInk,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? disabledFg : t.accentInk,
    ),
    iconSize: const WidgetStatePropertyAll(17),
    overlayColor: overlay(
      hoverColor: t.accentInk.withValues(alpha: 0.08),
      pressedColor: t.accentInk.withValues(alpha: 0.14),
    ),
  );

  final iconButtonStyle = ButtonStyle(
    shape: WidgetStatePropertyAll(enjoyShape(t.radiusMd - 2)),
    splashFactory: NoSplash.splashFactory,
    iconSize: const WidgetStatePropertyAll(20),
    foregroundColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.disabled)) return disabledFg;
      if (s.contains(WidgetState.selected)) return t.accentInk;
      return cs.onSurfaceVariant;
    }),
    overlayColor: overlay(),
  );

  final inputRadius = BorderRadius.circular(t.radiusMd - 2);
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  final menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(t.popover),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(12),
    shadowColor: WidgetStatePropertyAll(
      Colors.black.withValues(alpha: light ? 0.28 : 0.7),
    ),
    shape: WidgetStatePropertyAll(
      enjoyShape(t.radiusMd, side: BorderSide(color: t.hairline)),
    ),
    padding: WidgetStatePropertyAll(EdgeInsets.all(t.space4 + 2)),
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
    canvasColor: t.popover,
    cardColor: t.card,
    dividerColor: t.hairline,
    disabledColor: disabledFg,
    extensions: <ThemeExtension<dynamic>>[t, transcriptTokens],
    textTheme: tt,
    scaffoldBackgroundColor: Colors.transparent,
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: cs.primary,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 52,
      backgroundColor: Colors.transparent,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: cs.onSurface, size: 20),
      actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 20),
      titleTextStyle: tt.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: t.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: enjoyShape(t.radiusLg, side: BorderSide(color: t.hairline)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: t.space16),
      iconColor: cs.onSurfaceVariant,
      textColor: cs.onSurface,
      titleTextStyle: tt.titleMedium,
      subtitleTextStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      leadingAndTrailingTextStyle: tt.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
      ),
      minVerticalPadding: 10,
      minLeadingWidth: 24,
      horizontalTitleGap: t.space12,
      selectedColor: t.accentInk,
      selectedTileColor: t.accentSoft,
      shape: enjoyShape(t.radiusMd - 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: t.bottomNavHeight,
      backgroundColor: t.card,
      indicatorColor: t.accentSoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(tt.labelSmall),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: t.accentSoft,
      selectedIconTheme: IconThemeData(color: t.accentInk, size: 20),
      unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 20),
      selectedLabelTextStyle: tt.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      unselectedLabelTextStyle: tt.labelMedium?.copyWith(
        color: cs.onSurfaceVariant,
      ),
    ),
    sliderTheme: SliderThemeData(
      // ignore: deprecated_member_use
      year2023: true,
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 8,
        elevation: 2,
        pressedElevation: 3,
      ),
      overlayShape: SliderComponentShape.noOverlay,
      activeTrackColor: cs.primary,
      inactiveTrackColor: t.fill,
      thumbColor: Colors.white,
      overlayColor: Colors.transparent,
      valueIndicatorColor: light ? AppColors.onSurfaceLight : t.popover,
      valueIndicatorTextStyle: tt.labelSmall?.copyWith(color: Colors.white),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      shape: enjoyShape(
        t.radiusLg,
        side: BorderSide(color: light ? Colors.transparent : t.hairline),
      ),
      backgroundColor: light ? AppColors.onSurfaceLight : t.popover,
      contentTextStyle: tt.bodyMedium?.copyWith(
        color: light ? AppColors.onSurfaceDark : cs.onSurface,
      ),
      actionTextColor: AppColors.brandOnDark,
      showCloseIcon: false,
      closeIconColor: light ? AppColors.onSurfaceDark : cs.onSurface,
      dismissDirection: DismissDirection.horizontal,
      insetPadding: EdgeInsets.all(t.space16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.popover,
      modalBackgroundColor: t.popover,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius2xl)),
      ),
      clipBehavior: Clip.antiAlias,
      dragHandleColor: cs.onSurfaceVariant.withValues(alpha: 0.35),
      dragHandleSize: const Size(36, 5),
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
    ),
    filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: filledButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    iconButtonTheme: IconButtonThemeData(style: iconButtonStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(
          tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll(enjoyShape(t.radiusSm + 1)),
        side: WidgetStatePropertyAll(BorderSide(color: t.hairline)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.card : t.fill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? cs.onSurface
              : cs.onSurfaceVariant,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? t.accentInk
              : cs.onSurfaceVariant,
        ),
        overlayColor: overlay(),
      ),
      selectedIcon: const SizedBox.shrink(),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      borderRadius: BorderRadius.circular(t.radiusSm),
      borderColor: t.hairline,
      selectedBorderColor: t.hairline,
      fillColor: t.card,
      selectedColor: cs.onSurface,
      color: cs.onSurfaceVariant,
    ),
    switchTheme: SwitchThemeData(
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
    ),
    checkboxTheme: CheckboxThemeData(
      shape: enjoyShape(5),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BorderSide(color: cs.primary, width: 1.5)
            : BorderSide(color: cs.outline, width: 1.5),
      ),
      fillColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? cs.primary : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashRadius: 0,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cs.primary : cs.outline,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashRadius: 0,
    ),
    iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 22),
    primaryIconTheme: IconThemeData(color: cs.onPrimary, size: 22),
    dividerTheme: DividerThemeData(color: t.hairline, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: light ? 0.32 : 0.8),
      shape: enjoyShape(
        t.radiusXl,
        side: BorderSide(color: light ? Colors.transparent : t.hairline),
      ),
      backgroundColor: t.popover,
      surfaceTintColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: light ? 0.22 : 0.55),
      titleTextStyle: tt.titleLarge,
      contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      insetPadding: EdgeInsets.symmetric(
        horizontal: t.space24,
        vertical: t.space24,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        t.space20,
        t.space8,
        t.space20,
        t.space20,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.popover,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: light ? 0.28 : 0.7),
      shape: enjoyShape(t.radiusMd, side: BorderSide(color: t.hairline)),
      elevation: 12,
      textStyle: tt.bodyMedium,
      labelTextStyle: WidgetStatePropertyAll(tt.bodyMedium),
      menuPadding: EdgeInsets.all(t.space4 + 2),
      position: PopupMenuPosition.under,
      iconColor: cs.onSurfaceVariant,
      iconSize: 18,
    ),
    menuTheme: MenuThemeData(style: menuStyle),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: menuStyle,
      textStyle: tt.bodyMedium,
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: t.fill,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space8,
        ),
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(cs.primary, 1.5),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: light ? const Color(0xF216161D) : const Color(0xF22A2A33),
        shape: enjoyShape(t.radiusSm - 1),
      ),
      textStyle: tt.labelSmall?.copyWith(
        color: const Color(0xFFF4F4F7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      waitDuration: const Duration(milliseconds: 450),
      preferBelow: true,
      verticalOffset: 18,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: t.fill,
      hoverColor: cs.onSurface.withValues(alpha: 0.03),
      border: inputBorder(Colors.transparent),
      enabledBorder: inputBorder(Colors.transparent),
      disabledBorder: inputBorder(Colors.transparent),
      focusedBorder: inputBorder(cs.primary, 1.5),
      errorBorder: inputBorder(cs.error.withValues(alpha: 0.7)),
      focusedErrorBorder: inputBorder(cs.error, 1.5),
      contentPadding: EdgeInsets.symmetric(
        horizontal: t.space12 + 2,
        vertical: t.space12,
      ),
      isDense: false,
      hintStyle: tt.bodyMedium?.copyWith(color: t.textFaint),
      labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      floatingLabelStyle: tt.labelLarge?.copyWith(
        color: t.accentInk,
        fontWeight: FontWeight.w600,
      ),
      helperStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      errorStyle: tt.bodySmall?.copyWith(color: cs.error),
      prefixIconColor: cs.onSurfaceVariant,
      suffixIconColor: cs.onSurfaceVariant,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
      focusColor: focus,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: t.fill,
      selectedColor: t.accentSoft,
      disabledColor: t.fill.withValues(alpha: 0.5),
      secondarySelectedColor: t.accentSoft,
      labelStyle: tt.labelMedium?.copyWith(color: cs.onSurface),
      secondaryLabelStyle: tt.labelMedium?.copyWith(color: t.accentInk),
      iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 15),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      showCheckmark: false,
      checkmarkColor: t.accentInk,
      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: cs.error,
      textColor: Colors.white,
      smallSize: 7,
      largeSize: 16,
      textStyle: tt.labelSmall?.copyWith(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      // ignore: deprecated_member_use
      year2023: true,
      color: cs.primary,
      linearTrackColor: t.fill,
      circularTrackColor: Colors.transparent,
      linearMinHeight: 4,
      borderRadius: BorderRadius.circular(t.radiusFull),
      strokeCap: StrokeCap.round,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: cs.onSurface,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: tt.titleSmall,
      unselectedLabelStyle: tt.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: cs.primary, width: 2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
      dividerColor: t.hairline,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: cs.onSurfaceVariant,
      collapsedIconColor: cs.onSurfaceVariant,
      tilePadding: EdgeInsets.symmetric(horizontal: t.space16),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cs.primary,
      selectionColor: cs.primary.withValues(alpha: light ? 0.22 : 0.38),
      selectionHandleColor: cs.primary,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: EnjoyGlidePageTransitionsBuilder(),
        TargetPlatform.android: EnjoyGlidePageTransitionsBuilder(),
        TargetPlatform.fuchsia: EnjoyGlidePageTransitionsBuilder(),
        TargetPlatform.linux: EnjoyGlidePageTransitionsBuilder(),
        TargetPlatform.windows: EnjoyGlidePageTransitionsBuilder(),
      },
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? 8 : 5,
      ),
      radius: Radius.circular(t.radiusFull),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => cs.onSurface.withValues(
          alpha: s.contains(WidgetState.dragged)
              ? 0.42
              : s.contains(WidgetState.hovered)
              ? 0.32
              : 0.2,
        ),
      ),
      crossAxisMargin: 3,
      mainAxisMargin: 6,
    ),
  );
}

/// Status / navigation bar chrome that follows porcelain vs midnight.
SystemUiOverlayStyle enjoySystemUiOverlayStyle(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: dark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight,
    systemNavigationBarIconBrightness: dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
