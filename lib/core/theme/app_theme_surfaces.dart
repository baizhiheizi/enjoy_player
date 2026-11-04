part of 'app_theme.dart';

mixin _AppThemeSurfaces on _AppThemeBase {
  AppBarTheme get appBarTheme => AppBarTheme(
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
  );

  CardThemeData get cardTheme => CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    color: t.paper,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    shape: enjoyShape(t.radiusCard, side: BorderSide(color: t.line)),
  );

  ListTileThemeData get listTileTheme => ListTileThemeData(
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
    selectedColor: t.brandInk,
    selectedTileColor: t.brandSoft,
    shape: enjoyShape(t.radiusMd - 2),
  );

  NavigationBarThemeData get navigationBarTheme => NavigationBarThemeData(
    height: t.bottomNavHeight,
    backgroundColor: t.paper,
    indicatorColor: t.brandSoft,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    labelTextStyle: WidgetStatePropertyAll(tt.labelSmall),
  );

  NavigationRailThemeData get navigationRailTheme => NavigationRailThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: t.brandSoft,
    selectedIconTheme: IconThemeData(color: t.brandInk, size: 20),
    unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 20),
    selectedLabelTextStyle: tt.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    unselectedLabelTextStyle: tt.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
    ),
  );

  SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    elevation: 8,
    shape: enjoyShape(
      t.radiusLg,
      side: BorderSide(color: light ? Colors.transparent : t.line),
    ),
    backgroundColor: t.ink,
    contentTextStyle: tt.bodyMedium?.copyWith(color: t.ground),
    actionTextColor: t.originalInk,
    showCloseIcon: false,
    closeIconColor: light ? AppColors.onSurfaceDark : cs.onSurface,
    dismissDirection: DismissDirection.horizontal,
    insetPadding: EdgeInsets.all(t.space16),
  );

  BottomSheetThemeData get bottomSheetTheme => BottomSheetThemeData(
    backgroundColor: t.raised,
    modalBackgroundColor: t.raised,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusSheet)),
    ),
    clipBehavior: Clip.antiAlias,
    dragHandleColor: cs.onSurfaceVariant.withValues(alpha: 0.35),
    dragHandleSize: const Size(36, 5),
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
  );

  IconThemeData get iconTheme =>
      IconThemeData(color: cs.onSurfaceVariant, size: 22);

  IconThemeData get primaryIconTheme =>
      IconThemeData(color: cs.onPrimary, size: 22);

  DividerThemeData get dividerTheme =>
      DividerThemeData(color: t.line, thickness: 1, space: 1);

  DialogThemeData get dialogTheme => DialogThemeData(
    elevation: 16,
    shadowColor: Colors.black.withValues(alpha: light ? 0.32 : 0.8),
    shape: enjoyShape(
      t.radiusDialog,
      side: BorderSide(color: light ? Colors.transparent : t.line),
    ),
    backgroundColor: t.raised,
    surfaceTintColor: Colors.transparent,
    barrierColor: t.scrim,
    titleTextStyle: tt.displaySmall?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: -0.4,
      color: cs.onSurface,
    ),
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
  );

  ChipThemeData get chipTheme => ChipThemeData(
    shape: const StadiumBorder(),
    side: BorderSide.none,
    backgroundColor: t.sunk,
    selectedColor: t.ink,
    disabledColor: t.sunk.withValues(alpha: 0.5),
    secondarySelectedColor: t.ink,
    labelStyle: tt.labelMedium?.copyWith(color: t.ink),
    secondaryLabelStyle: tt.labelMedium?.copyWith(color: t.ground),
    iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 15),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    showCheckmark: false,
    checkmarkColor: t.ground,
    elevation: 0,
    pressElevation: 0,
    surfaceTintColor: Colors.transparent,
  );

  BadgeThemeData get badgeTheme => BadgeThemeData(
    backgroundColor: cs.error,
    textColor: Colors.white,
    smallSize: 7,
    largeSize: 16,
    textStyle: tt.labelSmall?.copyWith(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 5),
  );

  TabBarThemeData get tabBarTheme => TabBarThemeData(
    labelColor: cs.onSurface,
    unselectedLabelColor: cs.onSurfaceVariant,
    labelStyle: tt.titleSmall,
    unselectedLabelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
    indicatorSize: TabBarIndicatorSize.label,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: cs.primary, width: 2),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
    ),
    dividerColor: t.line,
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    splashFactory: NoSplash.splashFactory,
  );

  ExpansionTileThemeData get expansionTileTheme => ExpansionTileThemeData(
    shape: const Border(),
    collapsedShape: const Border(),
    iconColor: cs.onSurfaceVariant,
    collapsedIconColor: cs.onSurfaceVariant,
    tilePadding: EdgeInsets.symmetric(horizontal: t.space16),
  );
}
