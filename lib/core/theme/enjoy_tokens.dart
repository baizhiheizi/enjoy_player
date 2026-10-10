/// Design tokens: spacing, radii, motion, elevation, surfaces, shadows,
/// breakpoints (ThemeExtension). Duet design language (ADR-0093) values;
/// Aurora-named fields (ADR-0089) alias the Duet values until the rename pass.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'colors.dart';

part 'tokens/accents.dart';
part 'tokens/components.dart';
part 'tokens/effects.dart';
part 'tokens/elevation.dart';
part 'tokens/layout.dart';
part 'tokens/motion.dart';
part 'tokens/palette.dart';
part 'tokens/radius.dart';
part 'tokens/spaces.dart';

/// Design tokens; use [EnjoyThemeTokens.of] from widgets.
@immutable
class EnjoyThemeTokens extends ThemeExtension<EnjoyThemeTokens> {
  /// Tokens for [scheme]'s brightness.
  factory EnjoyThemeTokens.build(ColorScheme scheme) {
    final light = scheme.brightness == Brightness.light;
    return EnjoyThemeTokens._(
      _SpaceTokens.build(),
      _RadiusTokens.build(),
      _MotionTokens.build(),
      _ElevationTokens.build(light: light),
      _LayoutTokens.build(),
      _ComponentTokens.build(),
      _SurfaceColors.build(light: light),
      _AccentColors.build(light: light, scheme: scheme),
      _EffectTokens.build(),
    );
  }

  const EnjoyThemeTokens._(
    this._spaces,
    this._radii,
    this._motion,
    this._elevation,
    this._layout,
    this._components,
    this._palette,
    this._accents,
    this._effects,
  );

  final _SpaceTokens _spaces;
  final _RadiusTokens _radii;
  final _MotionTokens _motion;
  final _ElevationTokens _elevation;
  final _LayoutTokens _layout;
  final _ComponentTokens _components;
  final _SurfaceColors _palette;
  final _AccentColors _accents;
  final _EffectTokens _effects;

  double get space4 => _spaces.space4;
  double get space8 => _spaces.space8;
  double get space12 => _spaces.space12;
  double get space16 => _spaces.space16;
  double get space20 => _spaces.space20;
  double get space24 => _spaces.space24;
  double get space32 => _spaces.space32;
  double get space40 => _spaces.space40;
  double get space48 => _spaces.space48;

  double get radiusSm => _radii.radiusSm;
  double get radiusMd => _radii.radiusMd;
  double get radiusLg => _radii.radiusLg;
  double get radiusXl => _radii.radiusXl;
  double get radiusFull => _radii.radiusFull;

  double get elevationNone => _elevation.elevationNone;
  double get elevationCard => _elevation.elevationCard;
  double get elevationSheet => _elevation.elevationSheet;
  double get elevationModal => _elevation.elevationModal;
  double get elevationBar => _elevation.elevationBar;
  double get elevationSurface => _elevation.elevationSurface;

  double get breakpointCompact => _layout.breakpointCompact;
  double get breakpointRail => _layout.breakpointRail;
  double get breakpointTranscriptSideBySide =>
      _layout.breakpointTranscriptSideBySide;
  double get breakpointMarginDrawer => _layout.breakpointMarginDrawer;

  Duration get motionFast => _motion.motionFast;
  Duration get motionStandard => _motion.motionStandard;
  Duration get motionEnter => _motion.motionEnter;
  Duration get motionExit => _motion.motionExit;
  Duration get motionMedium => _motion.motionMedium;
  Duration get motionLens => _motion.motionLens;
  Duration get motionMargin => _motion.motionMargin;

  Color get echoActive => _accents.echoActive;
  Color get blurActive => _accents.blurActive;
  Color get scoreGood => _accents.scoreGood;
  Color get scoreWarn => _accents.scoreWarn;
  Color get scoreBad => _accents.scoreBad;
  Color get scoreGoodContainer => _accents.scoreGoodContainer;
  Color get scoreWarnContainer => _accents.scoreWarnContainer;
  Color get scoreBadContainer => _accents.scoreBadContainer;
  Color get accentSoft => _accents.accentSoft;
  Color get accentInk => _accents.accentInk;
  Color get intelligenceInk => _accents.intelligenceInk;
  Color get echoInk => _accents.echoInk;
  Color get ccBadge => _accents.ccBadge;

  EdgeInsets get transcriptLinePadding => _effects.transcriptLinePadding;

  double get contentMaxWidth => _layout.contentMaxWidth;
  double get formMaxWidth => _layout.formMaxWidth;
  double get hubMaxWidth => _layout.hubMaxWidth;

  double get pageGutterCompact => _spaces.pageGutterCompact;
  double get pageGutter => _spaces.pageGutter;

  double get miniBarBlurSigma => _components.miniBarBlurSigma;

  double get sidebarWidth => _layout.sidebarWidth;
  double get sidebarBrandHeight => _layout.sidebarBrandHeight;
  double get transportHeight => _layout.transportHeight;

  double get heroTitleLetterSpacing => _components.heroTitleLetterSpacing;

  Color get glassTint => _palette.glassTint;
  Color get glassBorder => _palette.glassBorder;
  Color get gradientStart => _palette.gradientStart;
  Color get gradientEnd => _palette.gradientEnd;

  double get bottomNavHeight => _layout.bottomNavHeight;

  double get desktopGutter => _spaces.desktopGutter;

  double get modalMaxWidth => _layout.modalMaxWidth;
  double get modalMaxWidthLarge => _layout.modalMaxWidthLarge;

  double get focusRingWidth => _elevation.focusRingWidth;

  double get radiusXs => _radii.radiusXs;
  double get radius2xl => _radii.radius2xl;

  Color get canvas => _palette.canvas;
  Color get card => _palette.card;
  Color get popover => _palette.popover;
  Color get hairline => _palette.hairline;
  Color get fill => _palette.fill;
  Color get textFaint => _palette.textFaint;
  Color get logoStart => _palette.logoStart;
  Color get logoEnd => _palette.logoEnd;
  Color get topHighlight => _palette.topHighlight;

  double get shellInset => _layout.shellInset;

  double get panelRadius => _radii.panelRadius;

  double get controlHeightSm => _components.controlHeightSm;
  double get controlHeight => _components.controlHeight;
  double get controlHeightLg => _components.controlHeightLg;

  List<BoxShadow> get shadowLift => _elevation.shadowLift;
  List<BoxShadow> get shadowFloat => _elevation.shadowFloat;
  List<BoxShadow> get shadowPopover => _elevation.shadowPopover;

  Color get ground => _palette.ground;
  Color get paper => _palette.paper;
  Color get raised => _palette.raised;
  Color get sunk => _palette.sunk;
  Color get line => _palette.line;
  Color get ink => _palette.ink;
  Color get ink2 => _palette.ink2;
  Color get ink3 => _palette.ink3;

  Color get original => _accents.original;
  Color get originalInk => _accents.originalInk;
  Color get originalSoft => _accents.originalSoft;
  Color get you => _accents.you;
  Color get youInk => _accents.youInk;
  Color get youSoft => _accents.youSoft;
  Color get youLine => _accents.youLine;
  Color get onYou => _accents.onYou;
  Color get brandInk => _accents.brandInk;
  Color get brandSoft => _accents.brandSoft;
  Color get primary => _accents.primary;
  Color get onPrimary => _accents.onPrimary;
  Color get danger => _accents.danger;

  Color get shape => _palette.shape;
  Color get tick => _palette.tick;
  Color get scrim => _palette.scrim;
  Color get video => _palette.video;

  Color get vocabNew => _accents.vocabNew;
  Color get vocabLearning => _accents.vocabLearning;
  Color get vocabReviewing => _accents.vocabReviewing;
  Color get vocabMastered => _accents.vocabMastered;

  double get radiusKeycap => _radii.radiusKeycap;
  double get radiusBadge => _radii.radiusBadge;
  double get radiusSegmentThumb => _radii.radiusSegmentThumb;
  double get radiusControl => _radii.radiusControl;
  double get radiusTile => _radii.radiusTile;
  double get radiusCard => _radii.radiusCard;
  double get radiusCardLarge => _radii.radiusCardLarge;
  double get radiusDialog => _radii.radiusDialog;
  double get radiusSheet => _radii.radiusSheet;

  double get touchTargetMin => _components.touchTargetMin;
  double get iconButtonSize => _components.iconButtonSize;
  double get iconButtonSizePhone => _components.iconButtonSizePhone;
  double get segmentHeight => _components.segmentHeight;
  double get chipHeight => _components.chipHeight;
  double get takeChipHeight => _components.takeChipHeight;
  double get playButtonSize => _components.playButtonSize;
  double get playButtonSizePhone => _components.playButtonSizePhone;
  double get recordButtonSize => _components.recordButtonSize;
  double get recordButtonSizePhone => _components.recordButtonSizePhone;
  double get originalPillWidth => _components.originalPillWidth;
  double get originalPillHeight => _components.originalPillHeight;
  double get originalButtonPhoneSize => _components.originalButtonPhoneSize;

  double get tabBarHeight => _layout.tabBarHeight;
  double get tabBarSafeInset => _layout.tabBarSafeInset;
  double get playerTopBarHeight => _layout.playerTopBarHeight;
  double get subpageHeaderHeight => _layout.subpageHeaderHeight;
  double get rulerHitHeight => _layout.rulerHitHeight;

  double get marginWidth => _spaces.marginWidth;

  double get transcriptMaxListen => _layout.transcriptMaxListen;
  double get transcriptMaxEcho => _layout.transcriptMaxEcho;
  double get videoColumnMin => _layout.videoColumnMin;
  double get videoColumnMax => _layout.videoColumnMax;
  double get videoColumnShare => _layout.videoColumnShare;
  double get pageMaxBrowse => _layout.pageMaxBrowse;
  double get pageMaxCraft => _layout.pageMaxCraft;
  double get pageMaxHub => _layout.pageMaxHub;
  double get pageMaxForm => _layout.pageMaxForm;

  double get gutter => _spaces.gutter;
  double get gutterPhone => _spaces.gutterPhone;

  List<double> get echoLensOpacity => _effects.echoLensOpacity;
  double get referencePitchOpacity => _effects.referencePitchOpacity;

  double get strokeReferencePitch => _elevation.strokeReferencePitch;
  double get strokeYourPitch => _elevation.strokeYourPitch;
  double get strokeLoopBracket => _elevation.strokeLoopBracket;
  double get strokeRulerTrack => _elevation.strokeRulerTrack;
  List<BoxShadow> get shadowBrandButton => _elevation.shadowBrandButton;
  List<BoxShadow> get shadowRecordButton => _elevation.shadowRecordButton;

  /// Soft-landing curve, cubic-bezier(.2, .8, .2, 1).
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1);

  /// Emphasized ease for selection indicators and sheet travel.
  static const Curve emphasized = Cubic(0.3, 0.0, 0.0, 1.0);

  /// Brand gradient (blue → violet) for Play, primary buttons, Pro, Upgrade.
  LinearGradient get brand => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandStart, AppColors.brandEnd],
  );

  /// Logo gradient (blue → violet) for the mark, rings, meters, covers.
  LinearGradient get logo => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [logoStart, logoEnd],
  );

  static EnjoyThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<EnjoyThemeTokens>() ??
        EnjoyThemeTokens.build(Theme.of(context).colorScheme);
  }

  @override
  EnjoyThemeTokens copyWith({
    double? space4,
    double? space8,
    double? space12,
    double? space16,
    double? space20,
    double? space24,
    double? space32,
    double? space40,
    double? space48,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusFull,
    double? elevationNone,
    double? elevationCard,
    double? elevationSheet,
    double? elevationModal,
    double? elevationBar,
    double? elevationSurface,
    double? breakpointCompact,
    double? breakpointRail,
    double? breakpointTranscriptSideBySide,
    double? breakpointMarginDrawer,
    Duration? motionFast,
    Duration? motionStandard,
    Duration? motionEnter,
    Duration? motionExit,
    Duration? motionMedium,
    Duration? motionLens,
    Duration? motionMargin,
    Color? echoActive,
    Color? blurActive,
    Color? scoreGood,
    Color? scoreWarn,
    Color? scoreBad,
    Color? scoreGoodContainer,
    Color? scoreWarnContainer,
    Color? scoreBadContainer,
    Color? accentSoft,
    Color? accentInk,
    Color? intelligenceInk,
    Color? echoInk,
    Color? ccBadge,
    EdgeInsets? transcriptLinePadding,
    double? contentMaxWidth,
    double? formMaxWidth,
    double? hubMaxWidth,
    double? pageGutterCompact,
    double? pageGutter,
    double? miniBarBlurSigma,
    double? sidebarWidth,
    double? sidebarBrandHeight,
    double? transportHeight,
    double? heroTitleLetterSpacing,
    Color? glassTint,
    Color? glassBorder,
    Color? gradientStart,
    Color? gradientEnd,
    double? bottomNavHeight,
    double? desktopGutter,
    double? modalMaxWidth,
    double? modalMaxWidthLarge,
    double? focusRingWidth,
    double? radiusXs,
    double? radius2xl,
    Color? canvas,
    Color? card,
    Color? popover,
    Color? hairline,
    Color? fill,
    Color? textFaint,
    Color? logoStart,
    Color? logoEnd,
    Color? topHighlight,
    double? shellInset,
    double? panelRadius,
    double? controlHeightSm,
    double? controlHeight,
    double? controlHeightLg,
    List<BoxShadow>? shadowLift,
    List<BoxShadow>? shadowFloat,
    List<BoxShadow>? shadowPopover,
    Color? ground,
    Color? paper,
    Color? raised,
    Color? sunk,
    Color? line,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? original,
    Color? originalInk,
    Color? originalSoft,
    Color? you,
    Color? youInk,
    Color? youSoft,
    Color? youLine,
    Color? onYou,
    Color? brandInk,
    Color? brandSoft,
    Color? primary,
    Color? onPrimary,
    Color? danger,
    Color? shape,
    Color? tick,
    Color? scrim,
    Color? video,
    Color? vocabNew,
    Color? vocabLearning,
    Color? vocabReviewing,
    Color? vocabMastered,
    double? radiusKeycap,
    double? radiusBadge,
    double? radiusSegmentThumb,
    double? radiusControl,
    double? radiusTile,
    double? radiusCard,
    double? radiusCardLarge,
    double? radiusDialog,
    double? radiusSheet,
    double? touchTargetMin,
    double? iconButtonSize,
    double? iconButtonSizePhone,
    double? segmentHeight,
    double? chipHeight,
    double? takeChipHeight,
    double? playButtonSize,
    double? playButtonSizePhone,
    double? recordButtonSize,
    double? recordButtonSizePhone,
    double? originalPillWidth,
    double? originalPillHeight,
    double? originalButtonPhoneSize,
    double? tabBarHeight,
    double? tabBarSafeInset,
    double? playerTopBarHeight,
    double? subpageHeaderHeight,
    double? rulerHitHeight,
    double? marginWidth,
    double? transcriptMaxListen,
    double? transcriptMaxEcho,
    double? videoColumnMin,
    double? videoColumnMax,
    double? videoColumnShare,
    double? pageMaxBrowse,
    double? pageMaxCraft,
    double? pageMaxHub,
    double? pageMaxForm,
    double? gutter,
    double? gutterPhone,
    List<double>? echoLensOpacity,
    double? referencePitchOpacity,
    double? strokeReferencePitch,
    double? strokeYourPitch,
    double? strokeLoopBracket,
    double? strokeRulerTrack,
    List<BoxShadow>? shadowBrandButton,
    List<BoxShadow>? shadowRecordButton,
  }) {
    return EnjoyThemeTokens._(
      _spaces.copyWith(
        space4: space4,
        space8: space8,
        space12: space12,
        space16: space16,
        space20: space20,
        space24: space24,
        space32: space32,
        space40: space40,
        space48: space48,
        pageGutterCompact: pageGutterCompact,
        pageGutter: pageGutter,
        desktopGutter: desktopGutter,
        marginWidth: marginWidth,
        gutter: gutter,
        gutterPhone: gutterPhone,
      ),
      _radii.copyWith(
        radiusSm: radiusSm,
        radiusMd: radiusMd,
        radiusLg: radiusLg,
        radiusXl: radiusXl,
        radiusFull: radiusFull,
        radiusXs: radiusXs,
        radius2xl: radius2xl,
        panelRadius: panelRadius,
        radiusKeycap: radiusKeycap,
        radiusBadge: radiusBadge,
        radiusSegmentThumb: radiusSegmentThumb,
        radiusControl: radiusControl,
        radiusTile: radiusTile,
        radiusCard: radiusCard,
        radiusCardLarge: radiusCardLarge,
        radiusDialog: radiusDialog,
        radiusSheet: radiusSheet,
      ),
      _motion.copyWith(
        motionFast: motionFast,
        motionStandard: motionStandard,
        motionEnter: motionEnter,
        motionExit: motionExit,
        motionMedium: motionMedium,
        motionLens: motionLens,
        motionMargin: motionMargin,
      ),
      _elevation.copyWith(
        elevationNone: elevationNone,
        elevationCard: elevationCard,
        elevationSheet: elevationSheet,
        elevationModal: elevationModal,
        elevationBar: elevationBar,
        elevationSurface: elevationSurface,
        focusRingWidth: focusRingWidth,
        shadowLift: shadowLift,
        shadowFloat: shadowFloat,
        shadowPopover: shadowPopover,
        strokeReferencePitch: strokeReferencePitch,
        strokeYourPitch: strokeYourPitch,
        strokeLoopBracket: strokeLoopBracket,
        strokeRulerTrack: strokeRulerTrack,
        shadowBrandButton: shadowBrandButton,
        shadowRecordButton: shadowRecordButton,
      ),
      _layout.copyWith(
        breakpointCompact: breakpointCompact,
        breakpointRail: breakpointRail,
        breakpointTranscriptSideBySide: breakpointTranscriptSideBySide,
        breakpointMarginDrawer: breakpointMarginDrawer,
        contentMaxWidth: contentMaxWidth,
        formMaxWidth: formMaxWidth,
        hubMaxWidth: hubMaxWidth,
        sidebarWidth: sidebarWidth,
        sidebarBrandHeight: sidebarBrandHeight,
        transportHeight: transportHeight,
        bottomNavHeight: bottomNavHeight,
        modalMaxWidth: modalMaxWidth,
        modalMaxWidthLarge: modalMaxWidthLarge,
        shellInset: shellInset,
        tabBarHeight: tabBarHeight,
        tabBarSafeInset: tabBarSafeInset,
        playerTopBarHeight: playerTopBarHeight,
        subpageHeaderHeight: subpageHeaderHeight,
        rulerHitHeight: rulerHitHeight,
        transcriptMaxListen: transcriptMaxListen,
        transcriptMaxEcho: transcriptMaxEcho,
        videoColumnMin: videoColumnMin,
        videoColumnMax: videoColumnMax,
        videoColumnShare: videoColumnShare,
        pageMaxBrowse: pageMaxBrowse,
        pageMaxCraft: pageMaxCraft,
        pageMaxHub: pageMaxHub,
        pageMaxForm: pageMaxForm,
      ),
      _components.copyWith(
        miniBarBlurSigma: miniBarBlurSigma,
        heroTitleLetterSpacing: heroTitleLetterSpacing,
        controlHeightSm: controlHeightSm,
        controlHeight: controlHeight,
        controlHeightLg: controlHeightLg,
        touchTargetMin: touchTargetMin,
        iconButtonSize: iconButtonSize,
        iconButtonSizePhone: iconButtonSizePhone,
        segmentHeight: segmentHeight,
        chipHeight: chipHeight,
        takeChipHeight: takeChipHeight,
        playButtonSize: playButtonSize,
        playButtonSizePhone: playButtonSizePhone,
        recordButtonSize: recordButtonSize,
        recordButtonSizePhone: recordButtonSizePhone,
        originalPillWidth: originalPillWidth,
        originalPillHeight: originalPillHeight,
        originalButtonPhoneSize: originalButtonPhoneSize,
      ),
      _palette.copyWith(
        glassTint: glassTint,
        glassBorder: glassBorder,
        gradientStart: gradientStart,
        gradientEnd: gradientEnd,
        canvas: canvas,
        card: card,
        popover: popover,
        hairline: hairline,
        fill: fill,
        textFaint: textFaint,
        logoStart: logoStart,
        logoEnd: logoEnd,
        topHighlight: topHighlight,
        ground: ground,
        paper: paper,
        raised: raised,
        sunk: sunk,
        line: line,
        ink: ink,
        ink2: ink2,
        ink3: ink3,
        shape: shape,
        tick: tick,
        scrim: scrim,
        video: video,
      ),
      _accents.copyWith(
        echoActive: echoActive,
        blurActive: blurActive,
        scoreGood: scoreGood,
        scoreWarn: scoreWarn,
        scoreBad: scoreBad,
        scoreGoodContainer: scoreGoodContainer,
        scoreWarnContainer: scoreWarnContainer,
        scoreBadContainer: scoreBadContainer,
        accentSoft: accentSoft,
        accentInk: accentInk,
        intelligenceInk: intelligenceInk,
        echoInk: echoInk,
        ccBadge: ccBadge,
        original: original,
        originalInk: originalInk,
        originalSoft: originalSoft,
        you: you,
        youInk: youInk,
        youSoft: youSoft,
        youLine: youLine,
        onYou: onYou,
        brandInk: brandInk,
        brandSoft: brandSoft,
        primary: primary,
        onPrimary: onPrimary,
        danger: danger,
        vocabNew: vocabNew,
        vocabLearning: vocabLearning,
        vocabReviewing: vocabReviewing,
        vocabMastered: vocabMastered,
      ),
      _effects.copyWith(
        transcriptLinePadding: transcriptLinePadding,
        echoLensOpacity: echoLensOpacity,
        referencePitchOpacity: referencePitchOpacity,
      ),
    );
  }

  @override
  ThemeExtension<EnjoyThemeTokens> lerp(
    covariant ThemeExtension<EnjoyThemeTokens>? other,
    double t,
  ) {
    if (other is! EnjoyThemeTokens) return this;
    if (t == 0) return this;
    if (t == 1) return other;

    return EnjoyThemeTokens._(
      _spaces.lerp(other._spaces, t),
      _radii.lerp(other._radii, t),
      _motion.lerp(other._motion, t),
      _elevation.lerp(other._elevation, t),
      _layout.lerp(other._layout, t),
      _components.lerp(other._components, t),
      _palette.lerp(other._palette, t),
      _accents.lerp(other._accents, t),
      _effects.lerp(other._effects, t),
    );
  }
}
