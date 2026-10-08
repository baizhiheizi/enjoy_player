/// Design tokens: spacing, radii, motion, elevation, surfaces, shadows,
/// breakpoints (ThemeExtension). Duet design language (ADR-0093) values;
/// Aurora-named fields (ADR-0089) alias the Duet values until the rename pass.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'colors.dart';

/// Design tokens; use [EnjoyThemeTokens.of] from widgets.
@immutable
class EnjoyThemeTokens extends ThemeExtension<EnjoyThemeTokens> {
  /// Tokens for [scheme]'s brightness.
  factory EnjoyThemeTokens.build(ColorScheme scheme) {
    final light = scheme.brightness == Brightness.light;
    return EnjoyThemeTokens(
      space4: 4,
      space8: 8,
      space12: 12,
      space16: 16,
      space20: 20,
      space24: 24,
      space32: 32,
      space40: 40,
      space48: 48,
      radiusSm: 8,
      radiusMd: 12,
      radiusLg: 16,
      radiusXl: 22,
      radiusFull: 999,
      elevationNone: 0,
      elevationCard: 1,
      elevationSheet: 3,
      elevationModal: 8,
      elevationBar: 2,
      elevationSurface: 1,
      breakpointCompact: 600,
      breakpointRail: 900,
      breakpointTranscriptSideBySide: 720,
      breakpointMarginDrawer: 1100,
      motionFast: const Duration(milliseconds: 160),
      motionStandard: const Duration(milliseconds: 280),
      motionEnter: const Duration(milliseconds: 260),
      motionExit: const Duration(milliseconds: 160),
      motionMedium: const Duration(milliseconds: 220),
      motionLens: const Duration(milliseconds: 280),
      motionMargin: const Duration(milliseconds: 220),
      echoActive: light ? AppColors.youLight : AppColors.youDark,
      blurActive: light ? AppColors.inkLight : AppColors.inkDark,
      scoreGood: light ? AppColors.ink2Light : AppColors.ink2Dark,
      scoreWarn: light ? AppColors.ink2Light : AppColors.ink2Dark,
      scoreBad: light ? AppColors.dangerLight : AppColors.dangerDark,
      scoreGoodContainer: light ? AppColors.sunkLight : AppColors.sunkDark,
      scoreWarnContainer: light ? AppColors.sunkLight : AppColors.sunkDark,
      scoreBadContainer: light ? AppColors.sunkLight : AppColors.sunkDark,
      accentSoft: light ? AppColors.brandSoftLight : AppColors.brandSoftDark,
      accentInk: light ? AppColors.brandInkLight : AppColors.brandInkDark,
      intelligenceInk: light
          ? AppColors.originalInkLight
          : AppColors.originalInkDark,
      echoInk: light ? AppColors.youInkLight : AppColors.youInkDark,
      ccBadge: scheme.primary,
      transcriptLinePadding: const EdgeInsets.symmetric(horizontal: 16),
      contentMaxWidth: 700,
      formMaxWidth: 680,
      hubMaxWidth: 840,
      pageGutterCompact: 16,
      pageGutter: 40,
      miniBarBlurSigma: 24,
      sidebarWidth: 244,
      sidebarBrandHeight: 52,
      transportHeight: 88,
      heroTitleLetterSpacing: -0.9,
      glassTint: light ? AppColors.paperLight : AppColors.paperDark,
      glassBorder: light ? AppColors.lineLight : AppColors.lineDark,
      gradientStart: light ? AppColors.groundLight : AppColors.groundDark,
      gradientEnd: light ? AppColors.groundLight : AppColors.groundDark,
      bottomNavHeight: 64,
      desktopGutter: 24,
      modalMaxWidth: 400,
      modalMaxWidthLarge: 560,
      focusRingWidth: 2,
      radiusXs: 6,
      radius2xl: 30,
      canvas: light ? AppColors.groundLight : AppColors.groundDark,
      card: light ? AppColors.paperLight : AppColors.paperDark,
      popover: light ? AppColors.raisedLight : AppColors.raisedDark,
      hairline: light ? AppColors.lineLight : AppColors.lineDark,
      fill: light ? AppColors.sunkLight : AppColors.sunkDark,
      textFaint: light ? AppColors.ink3Light : AppColors.ink3Dark,
      logoStart: AppColors.logoStart,
      logoEnd: AppColors.logoEnd,
      topHighlight: Colors.transparent,
      shellInset: 0,
      panelRadius: 0,
      controlHeightSm: 32,
      controlHeight: 40,
      controlHeightLg: 50,
      shadowLift: _shadowLift(light),
      shadowFloat: _shadowFloat(light),
      shadowPopover: _shadowFloat(light),
      ground: light ? AppColors.groundLight : AppColors.groundDark,
      paper: light ? AppColors.paperLight : AppColors.paperDark,
      raised: light ? AppColors.raisedLight : AppColors.raisedDark,
      sunk: light ? AppColors.sunkLight : AppColors.sunkDark,
      line: light ? AppColors.lineLight : AppColors.lineDark,
      ink: light ? AppColors.inkLight : AppColors.inkDark,
      ink2: light ? AppColors.ink2Light : AppColors.ink2Dark,
      ink3: light ? AppColors.ink3Light : AppColors.ink3Dark,
      original: light ? AppColors.originalLight : AppColors.originalDark,
      originalInk: light
          ? AppColors.originalInkLight
          : AppColors.originalInkDark,
      originalSoft: light
          ? AppColors.originalSoftLight
          : AppColors.originalSoftDark,
      you: light ? AppColors.youLight : AppColors.youDark,
      youInk: light ? AppColors.youInkLight : AppColors.youInkDark,
      youSoft: light ? AppColors.youSoftLight : AppColors.youSoftDark,
      youLine: light ? AppColors.youLineLight : AppColors.youLineDark,
      onYou: light ? AppColors.onYouLight : AppColors.onYouDark,
      brandInk: light ? AppColors.brandInkLight : AppColors.brandInkDark,
      brandSoft: light ? AppColors.brandSoftLight : AppColors.brandSoftDark,
      primary: light ? AppColors.primaryInkLight : AppColors.primaryInkDark,
      onPrimary: light
          ? AppColors.onPrimaryInkLight
          : AppColors.onPrimaryInkDark,
      danger: light ? AppColors.dangerLight : AppColors.dangerDark,
      shape: light ? AppColors.shapeLight : AppColors.shapeDark,
      tick: light ? AppColors.tickLight : AppColors.tickDark,
      scrim: light ? AppColors.scrimLight : AppColors.scrimDark,
      video: light ? AppColors.videoLight : AppColors.videoDark,
      vocabNew: light ? AppColors.vocabNewLight : AppColors.vocabNewDark,
      vocabLearning: light
          ? AppColors.vocabLearningLight
          : AppColors.vocabLearningDark,
      vocabReviewing: light
          ? AppColors.vocabReviewingLight
          : AppColors.vocabReviewingDark,
      vocabMastered: light
          ? AppColors.vocabMasteredLight
          : AppColors.vocabMasteredDark,
      radiusKeycap: 5,
      radiusBadge: 7,
      radiusSegmentThumb: 9,
      radiusControl: 12,
      radiusTile: 14,
      radiusCard: 20,
      radiusCardLarge: 24,
      radiusDialog: 24,
      radiusSheet: 26,
      touchTargetMin: 44,
      iconButtonSize: 40,
      iconButtonSizePhone: 44,
      segmentHeight: 38,
      chipHeight: 34,
      takeChipHeight: 36,
      playButtonSize: 60,
      playButtonSizePhone: 68,
      recordButtonSize: 62,
      recordButtonSizePhone: 76,
      originalPillWidth: 150,
      originalPillHeight: 52,
      originalButtonPhoneSize: 56,
      tabBarHeight: 84,
      tabBarSafeInset: 26,
      playerTopBarHeight: 60,
      subpageHeaderHeight: 64,
      rulerHitHeight: 34,
      marginWidth: 340,
      transcriptMaxListen: 700,
      transcriptMaxEcho: 760,
      videoColumnMin: 300,
      videoColumnMax: 380,
      videoColumnShare: 0.28,
      pageMaxBrowse: 1180,
      pageMaxCraft: 1080,
      pageMaxHub: 840,
      pageMaxForm: 680,
      gutter: 40,
      gutterPhone: 16,
      echoLensOpacity: const [1, 0.65, 0.35, 0.2],
      referencePitchOpacity: 0.35,
      strokeReferencePitch: 9,
      strokeYourPitch: 3,
      strokeLoopBracket: 2,
      strokeRulerTrack: 4,
      shadowBrandButton: _shadowBrandButton(light),
      shadowRecordButton: _shadowRecordButton(light),
    );
  }
  const EnjoyThemeTokens({
    required this.space4,
    required this.space8,
    required this.space12,
    required this.space16,
    required this.space20,
    required this.space24,
    required this.space32,
    required this.space40,
    required this.space48,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusFull,
    required this.elevationNone,
    required this.elevationCard,
    required this.elevationSheet,
    required this.elevationModal,
    required this.elevationBar,
    required this.elevationSurface,
    required this.breakpointCompact,
    required this.breakpointRail,
    required this.breakpointTranscriptSideBySide,
    required this.breakpointMarginDrawer,
    required this.motionFast,
    required this.motionStandard,
    required this.motionEnter,
    required this.motionExit,

    /// Transport / layout morphs: 220ms (between [motionFast] and [motionStandard]).
    required this.motionMedium,
    required this.motionLens,
    required this.motionMargin,
    required this.echoActive,
    required this.blurActive,
    required this.scoreGood,
    required this.scoreWarn,
    required this.scoreBad,
    required this.scoreGoodContainer,
    required this.scoreWarnContainer,
    required this.scoreBadContainer,
    required this.accentSoft,
    required this.accentInk,
    required this.intelligenceInk,
    required this.echoInk,
    required this.ccBadge,
    required this.transcriptLinePadding,
    required this.contentMaxWidth,
    required this.formMaxWidth,
    required this.hubMaxWidth,
    required this.pageGutterCompact,
    required this.pageGutter,
    required this.miniBarBlurSigma,
    required this.sidebarWidth,
    required this.sidebarBrandHeight,
    required this.transportHeight,
    required this.heroTitleLetterSpacing,
    required this.glassTint,
    required this.glassBorder,
    required this.gradientStart,
    required this.gradientEnd,
    required this.bottomNavHeight,
    required this.desktopGutter,
    required this.modalMaxWidth,
    required this.modalMaxWidthLarge,
    required this.focusRingWidth,
    required this.radiusXs,
    required this.radius2xl,
    required this.canvas,
    required this.card,
    required this.popover,
    required this.hairline,
    required this.fill,
    required this.textFaint,
    required this.logoStart,
    required this.logoEnd,
    required this.topHighlight,
    required this.shellInset,
    required this.panelRadius,
    required this.controlHeightSm,
    required this.controlHeight,
    required this.controlHeightLg,
    required this.shadowLift,
    required this.shadowFloat,
    required this.shadowPopover,
    required this.ground,
    required this.paper,
    required this.raised,
    required this.sunk,
    required this.line,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.original,
    required this.originalInk,
    required this.originalSoft,
    required this.you,
    required this.youInk,
    required this.youSoft,
    required this.youLine,
    required this.onYou,
    required this.brandInk,
    required this.brandSoft,
    required this.primary,
    required this.onPrimary,
    required this.danger,
    required this.shape,
    required this.tick,
    required this.scrim,
    required this.video,
    required this.vocabNew,
    required this.vocabLearning,
    required this.vocabReviewing,
    required this.vocabMastered,
    required this.radiusKeycap,
    required this.radiusBadge,
    required this.radiusSegmentThumb,
    required this.radiusControl,
    required this.radiusTile,
    required this.radiusCard,
    required this.radiusCardLarge,
    required this.radiusDialog,
    required this.radiusSheet,
    required this.touchTargetMin,
    required this.iconButtonSize,
    required this.iconButtonSizePhone,
    required this.segmentHeight,
    required this.chipHeight,
    required this.takeChipHeight,
    required this.playButtonSize,
    required this.playButtonSizePhone,
    required this.recordButtonSize,
    required this.recordButtonSizePhone,
    required this.originalPillWidth,
    required this.originalPillHeight,
    required this.originalButtonPhoneSize,
    required this.tabBarHeight,
    required this.tabBarSafeInset,
    required this.playerTopBarHeight,
    required this.subpageHeaderHeight,
    required this.rulerHitHeight,
    required this.marginWidth,
    required this.transcriptMaxListen,
    required this.transcriptMaxEcho,
    required this.videoColumnMin,
    required this.videoColumnMax,
    required this.videoColumnShare,
    required this.pageMaxBrowse,
    required this.pageMaxCraft,
    required this.pageMaxHub,
    required this.pageMaxForm,
    required this.gutter,
    required this.gutterPhone,
    required this.echoLensOpacity,
    required this.referencePitchOpacity,
    required this.strokeReferencePitch,
    required this.strokeYourPitch,
    required this.strokeLoopBracket,
    required this.strokeRulerTrack,
    required this.shadowBrandButton,
    required this.shadowRecordButton,
  });

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

  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space20;
  final double space24;
  final double space32;
  final double space40;
  final double space48;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusFull;

  final double elevationNone;
  final double elevationCard;
  final double elevationSheet;
  final double elevationModal;

  /// Legacy aliases kept for widgets that still call elevationBar/elevationSurface.
  final double elevationBar;
  final double elevationSurface;

  /// Pane width below which [pageGutterCompact] applies.
  final double breakpointCompact;

  /// Width at which shell switches from bottom nav to extended sidebar.
  final double breakpointRail;

  /// Width at which player shows transcript side-by-side vs stacked.
  final double breakpointTranscriptSideBySide;

  /// Player width below which the side margin opens as a drawer.
  final double breakpointMarginDrawer;

  /// Micro-interactions: 160ms.
  final Duration motionFast;

  /// Standard transitions: 280ms.
  final Duration motionStandard;

  /// Screen enter: 260ms.
  final Duration motionEnter;

  /// Screen exit: 160ms (faster than enter for responsiveness).
  final Duration motionExit;

  /// Transport / layout morphs: 220ms (between [motionFast] and [motionStandard]).
  final Duration motionMedium;

  /// Listen ↔ Echo lens transition: 280ms.
  final Duration motionLens;

  /// Side margin open/close slide: 220ms.
  final Duration motionMargin;

  final Color echoActive;

  /// Accent used for the listening-focus (hide text) toggle when active.
  final Color blurActive;

  /// Evaluation & assessment good color (ink in Duet — scores are uncolored).
  final Color scoreGood;

  /// Evaluation & assessment warn color (ink in Duet — scores are uncolored).
  final Color scoreWarn;

  /// Evaluation & assessment bad color (danger).
  final Color scoreBad;

  final Color scoreGoodContainer;
  final Color scoreWarnContainer;
  final Color scoreBadContainer;

  /// Soft translucent brand accent background.
  final Color accentSoft;

  /// Violet used as text/icon ink (deep on paper, bright on graphite).
  final Color accentInk;

  /// Original-speaker blue ink.
  final Color intelligenceInk;

  /// Learner violet ink.
  final Color echoInk;

  final Color ccBadge;

  final EdgeInsets transcriptLinePadding;

  /// Listen transcript column cap.
  final double contentMaxWidth;

  /// Centered max width for form pages (Preferences, Edit Profile, …).
  final double formMaxWidth;

  /// Centered max width for hub pages (Profile, Settings, Subscription, …).
  final double hubMaxWidth;

  /// Horizontal gutter when pane width is below [breakpointCompact].
  final double pageGutterCompact;

  /// Default horizontal gutter for page content (browse + capped columns).
  final double pageGutter;

  /// Backdrop-filter blur for the transport glass bar.
  final double miniBarBlurSigma;

  final double sidebarWidth;
  final double sidebarBrandHeight;
  final double transportHeight;

  /// Letter-spacing for hero display titles (negative = tight).
  final double heroTitleLetterSpacing;

  final Color glassTint;
  final Color glassBorder;
  final Color gradientStart;
  final Color gradientEnd;

  /// Mobile bottom nav content height (excluding system home-indicator inset).
  final double bottomNavHeight;

  /// Horizontal inset for wide layouts (sidebar + content rhythm).
  final double desktopGutter;

  /// Typical alert / form dialog max width.
  final double modalMaxWidth;

  /// Wide modals (e.g. assessment summary).
  final double modalMaxWidthLarge;

  /// Keyboard focus ring stroke width for custom controls.
  final double focusRingWidth;

  /// Tight radius for tiny badges and keycaps.
  final double radiusXs;

  /// Hero artwork, sheets, and large modal corners.
  final double radius2xl;

  /// Window canvas behind the sidebar and the content area.
  final Color canvas;

  /// Card / grouped-list surface.
  final Color card;

  /// Menus, popovers, dialogs, and sheets.
  final Color popover;

  /// 1px separators and card outlines.
  final Color hairline;

  /// Subtle control fill (search fields, segmented tracks, chips).
  final Color fill;

  /// Tertiary text (timestamps, hints).
  final Color textFaint;

  /// Logo gradient start (original blue).
  final Color logoStart;

  /// Logo gradient end (you violet).
  final Color logoEnd;

  /// Legacy dark-surface lit edge; transparent in Duet.
  final Color topHighlight;

  /// Legacy gap between the canvas and the floating content panel; 0 in Duet.
  final double shellInset;

  /// Legacy floating content panel corner radius; 0 in Duet.
  final double panelRadius;

  /// Compact control height (toolbar buttons, chips).
  final double controlHeightSm;

  /// Default control height (buttons, fields, segmented).
  final double controlHeight;

  /// Prominent control height (primary CTAs, dock play button).
  final double controlHeightLg;

  /// Resting card shadow.
  final List<BoxShadow> shadowLift;

  /// Floating chrome shadow (tab bar, dock, popovers).
  final List<BoxShadow> shadowFloat;

  /// Menus / dialogs shadow.
  final List<BoxShadow> shadowPopover;

  /// Page and sidebar ground.
  final Color ground;

  /// Cards and content tiles.
  final Color paper;

  /// Menus, popovers, dialogs, and sheets.
  final Color raised;

  /// Sunk control fill (search fields, segmented tracks, chips).
  final Color sunk;

  /// 1px separators, card outlines, and the you-soft boundary.
  final Color line;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Tertiary text (timestamps, hints) — readable in both themes.
  final Color ink3;

  /// Original-speaker blue: playback, spoken word, reference pitch, Listen.
  final Color original;

  /// Original blue as text/icon ink.
  final Color originalInk;

  /// Translucent original wash (selected rows, soft pills).
  final Color originalSoft;

  /// Learner violet: Echo loop, Record, takes, your pitch.
  final Color you;

  /// Learner violet as text/icon ink.
  final Color youInk;

  /// Translucent you wash (selected rows, soft pills).
  final Color youSoft;

  /// You-tinted outline (loop brackets, wavy underlines).
  final Color youLine;

  /// Label/icon color on [you] fills.
  final Color onYou;

  /// Brand ink — the readable end of the brand gradient.
  final Color brandInk;

  /// Soft brand wash (selected rows, tab-bar pill, radio fill).
  final Color brandSoft;

  /// Ink-fill primary buttons.
  final Color primary;

  /// Label color on [primary] fills.
  final Color onPrimary;

  /// Destructive actions and errors.
  final Color danger;

  /// Hidden-word shape bars.
  final Color shape;

  /// Sentence-ruler track ticks.
  final Color tick;

  /// Modal and drawer scrims.
  final Color scrim;

  /// Video stage letterbox.
  final Color video;

  /// Vocabulary status scale (new / learning / reviewing / mastered).
  final Color vocabNew;
  final Color vocabLearning;
  final Color vocabReviewing;
  final Color vocabMastered;

  final double radiusKeycap;
  final double radiusBadge;
  final double radiusSegmentThumb;
  final double radiusControl;
  final double radiusTile;
  final double radiusCard;
  final double radiusCardLarge;
  final double radiusDialog;
  final double radiusSheet;

  /// Smallest tappable dimension.
  final double touchTargetMin;
  final double iconButtonSize;
  final double iconButtonSizePhone;
  final double segmentHeight;
  final double chipHeight;
  final double takeChipHeight;
  final double playButtonSize;
  final double playButtonSizePhone;
  final double recordButtonSize;
  final double recordButtonSizePhone;
  final double originalPillWidth;
  final double originalPillHeight;
  final double originalButtonPhoneSize;
  final double tabBarHeight;
  final double tabBarSafeInset;
  final double playerTopBarHeight;
  final double subpageHeaderHeight;
  final double rulerHitHeight;
  final double marginWidth;
  final double transcriptMaxListen;
  final double transcriptMaxEcho;
  final double videoColumnMin;
  final double videoColumnMax;
  final double videoColumnShare;
  final double pageMaxBrowse;
  final double pageMaxCraft;
  final double pageMaxHub;
  final double pageMaxForm;
  final double gutter;
  final double gutterPhone;

  /// Listen ↔ Echo neighbour fade steps, by distance from the loop.
  final List<double> echoLensOpacity;

  /// Reference-pitch band opacity in the pitch duet.
  final double referencePitchOpacity;

  final double strokeReferencePitch;
  final double strokeYourPitch;
  final double strokeLoopBracket;
  final double strokeRulerTrack;

  /// Brand-gradient button shadow.
  final List<BoxShadow> shadowBrandButton;

  /// Record button shadow.
  final List<BoxShadow> shadowRecordButton;

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
    return EnjoyThemeTokens(
      space4: space4 ?? this.space4,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      space16: space16 ?? this.space16,
      space20: space20 ?? this.space20,
      space24: space24 ?? this.space24,
      space32: space32 ?? this.space32,
      space40: space40 ?? this.space40,
      space48: space48 ?? this.space48,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusFull: radiusFull ?? this.radiusFull,
      elevationNone: elevationNone ?? this.elevationNone,
      elevationCard: elevationCard ?? this.elevationCard,
      elevationSheet: elevationSheet ?? this.elevationSheet,
      elevationModal: elevationModal ?? this.elevationModal,
      elevationBar: elevationBar ?? this.elevationBar,
      elevationSurface: elevationSurface ?? this.elevationSurface,
      breakpointCompact: breakpointCompact ?? this.breakpointCompact,
      breakpointRail: breakpointRail ?? this.breakpointRail,
      breakpointTranscriptSideBySide:
          breakpointTranscriptSideBySide ?? this.breakpointTranscriptSideBySide,
      breakpointMarginDrawer:
          breakpointMarginDrawer ?? this.breakpointMarginDrawer,
      motionFast: motionFast ?? this.motionFast,
      motionStandard: motionStandard ?? this.motionStandard,
      motionEnter: motionEnter ?? this.motionEnter,
      motionExit: motionExit ?? this.motionExit,
      motionMedium: motionMedium ?? this.motionMedium,
      motionLens: motionLens ?? this.motionLens,
      motionMargin: motionMargin ?? this.motionMargin,
      echoActive: echoActive ?? this.echoActive,
      blurActive: blurActive ?? this.blurActive,
      scoreGood: scoreGood ?? this.scoreGood,
      scoreWarn: scoreWarn ?? this.scoreWarn,
      scoreBad: scoreBad ?? this.scoreBad,
      scoreGoodContainer: scoreGoodContainer ?? this.scoreGoodContainer,
      scoreWarnContainer: scoreWarnContainer ?? this.scoreWarnContainer,
      scoreBadContainer: scoreBadContainer ?? this.scoreBadContainer,
      accentSoft: accentSoft ?? this.accentSoft,
      accentInk: accentInk ?? this.accentInk,
      intelligenceInk: intelligenceInk ?? this.intelligenceInk,
      echoInk: echoInk ?? this.echoInk,
      ccBadge: ccBadge ?? this.ccBadge,
      transcriptLinePadding:
          transcriptLinePadding ?? this.transcriptLinePadding,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      formMaxWidth: formMaxWidth ?? this.formMaxWidth,
      hubMaxWidth: hubMaxWidth ?? this.hubMaxWidth,
      pageGutterCompact: pageGutterCompact ?? this.pageGutterCompact,
      pageGutter: pageGutter ?? this.pageGutter,
      miniBarBlurSigma: miniBarBlurSigma ?? this.miniBarBlurSigma,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      sidebarBrandHeight: sidebarBrandHeight ?? this.sidebarBrandHeight,
      transportHeight: transportHeight ?? this.transportHeight,
      heroTitleLetterSpacing:
          heroTitleLetterSpacing ?? this.heroTitleLetterSpacing,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      bottomNavHeight: bottomNavHeight ?? this.bottomNavHeight,
      desktopGutter: desktopGutter ?? this.desktopGutter,
      modalMaxWidth: modalMaxWidth ?? this.modalMaxWidth,
      modalMaxWidthLarge: modalMaxWidthLarge ?? this.modalMaxWidthLarge,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      radiusXs: radiusXs ?? this.radiusXs,
      radius2xl: radius2xl ?? this.radius2xl,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      popover: popover ?? this.popover,
      hairline: hairline ?? this.hairline,
      fill: fill ?? this.fill,
      textFaint: textFaint ?? this.textFaint,
      logoStart: logoStart ?? this.logoStart,
      logoEnd: logoEnd ?? this.logoEnd,
      topHighlight: topHighlight ?? this.topHighlight,
      shellInset: shellInset ?? this.shellInset,
      panelRadius: panelRadius ?? this.panelRadius,
      controlHeightSm: controlHeightSm ?? this.controlHeightSm,
      controlHeight: controlHeight ?? this.controlHeight,
      controlHeightLg: controlHeightLg ?? this.controlHeightLg,
      shadowLift: shadowLift ?? this.shadowLift,
      shadowFloat: shadowFloat ?? this.shadowFloat,
      shadowPopover: shadowPopover ?? this.shadowPopover,
      ground: ground ?? this.ground,
      paper: paper ?? this.paper,
      raised: raised ?? this.raised,
      sunk: sunk ?? this.sunk,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      original: original ?? this.original,
      originalInk: originalInk ?? this.originalInk,
      originalSoft: originalSoft ?? this.originalSoft,
      you: you ?? this.you,
      youInk: youInk ?? this.youInk,
      youSoft: youSoft ?? this.youSoft,
      youLine: youLine ?? this.youLine,
      onYou: onYou ?? this.onYou,
      brandInk: brandInk ?? this.brandInk,
      brandSoft: brandSoft ?? this.brandSoft,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      danger: danger ?? this.danger,
      shape: shape ?? this.shape,
      tick: tick ?? this.tick,
      scrim: scrim ?? this.scrim,
      video: video ?? this.video,
      vocabNew: vocabNew ?? this.vocabNew,
      vocabLearning: vocabLearning ?? this.vocabLearning,
      vocabReviewing: vocabReviewing ?? this.vocabReviewing,
      vocabMastered: vocabMastered ?? this.vocabMastered,
      radiusKeycap: radiusKeycap ?? this.radiusKeycap,
      radiusBadge: radiusBadge ?? this.radiusBadge,
      radiusSegmentThumb: radiusSegmentThumb ?? this.radiusSegmentThumb,
      radiusControl: radiusControl ?? this.radiusControl,
      radiusTile: radiusTile ?? this.radiusTile,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusCardLarge: radiusCardLarge ?? this.radiusCardLarge,
      radiusDialog: radiusDialog ?? this.radiusDialog,
      radiusSheet: radiusSheet ?? this.radiusSheet,
      touchTargetMin: touchTargetMin ?? this.touchTargetMin,
      iconButtonSize: iconButtonSize ?? this.iconButtonSize,
      iconButtonSizePhone: iconButtonSizePhone ?? this.iconButtonSizePhone,
      segmentHeight: segmentHeight ?? this.segmentHeight,
      chipHeight: chipHeight ?? this.chipHeight,
      takeChipHeight: takeChipHeight ?? this.takeChipHeight,
      playButtonSize: playButtonSize ?? this.playButtonSize,
      playButtonSizePhone: playButtonSizePhone ?? this.playButtonSizePhone,
      recordButtonSize: recordButtonSize ?? this.recordButtonSize,
      recordButtonSizePhone:
          recordButtonSizePhone ?? this.recordButtonSizePhone,
      originalPillWidth: originalPillWidth ?? this.originalPillWidth,
      originalPillHeight: originalPillHeight ?? this.originalPillHeight,
      originalButtonPhoneSize:
          originalButtonPhoneSize ?? this.originalButtonPhoneSize,
      tabBarHeight: tabBarHeight ?? this.tabBarHeight,
      tabBarSafeInset: tabBarSafeInset ?? this.tabBarSafeInset,
      playerTopBarHeight: playerTopBarHeight ?? this.playerTopBarHeight,
      subpageHeaderHeight: subpageHeaderHeight ?? this.subpageHeaderHeight,
      rulerHitHeight: rulerHitHeight ?? this.rulerHitHeight,
      marginWidth: marginWidth ?? this.marginWidth,
      transcriptMaxListen: transcriptMaxListen ?? this.transcriptMaxListen,
      transcriptMaxEcho: transcriptMaxEcho ?? this.transcriptMaxEcho,
      videoColumnMin: videoColumnMin ?? this.videoColumnMin,
      videoColumnMax: videoColumnMax ?? this.videoColumnMax,
      videoColumnShare: videoColumnShare ?? this.videoColumnShare,
      pageMaxBrowse: pageMaxBrowse ?? this.pageMaxBrowse,
      pageMaxCraft: pageMaxCraft ?? this.pageMaxCraft,
      pageMaxHub: pageMaxHub ?? this.pageMaxHub,
      pageMaxForm: pageMaxForm ?? this.pageMaxForm,
      gutter: gutter ?? this.gutter,
      gutterPhone: gutterPhone ?? this.gutterPhone,
      echoLensOpacity: echoLensOpacity ?? this.echoLensOpacity,
      referencePitchOpacity:
          referencePitchOpacity ?? this.referencePitchOpacity,
      strokeReferencePitch: strokeReferencePitch ?? this.strokeReferencePitch,
      strokeYourPitch: strokeYourPitch ?? this.strokeYourPitch,
      strokeLoopBracket: strokeLoopBracket ?? this.strokeLoopBracket,
      strokeRulerTrack: strokeRulerTrack ?? this.strokeRulerTrack,
      shadowBrandButton: shadowBrandButton ?? this.shadowBrandButton,
      shadowRecordButton: shadowRecordButton ?? this.shadowRecordButton,
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

    double ms(Duration a, Duration b) => lerpDouble(
      a.inMilliseconds.toDouble(),
      b.inMilliseconds.toDouble(),
      t,
    )!.roundToDouble();

    List<double> lerpDoubles(List<double> a, List<double> b) =>
        List.generate(a.length, (i) => lerpDouble(a[i], b[i], t)!);

    return EnjoyThemeTokens(
      space4: lerpDouble(space4, other.space4, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      space16: lerpDouble(space16, other.space16, t)!,
      space20: lerpDouble(space20, other.space20, t)!,
      space24: lerpDouble(space24, other.space24, t)!,
      space32: lerpDouble(space32, other.space32, t)!,
      space40: lerpDouble(space40, other.space40, t)!,
      space48: lerpDouble(space48, other.space48, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      radiusFull: lerpDouble(radiusFull, other.radiusFull, t)!,
      elevationNone: lerpDouble(elevationNone, other.elevationNone, t)!,
      elevationCard: lerpDouble(elevationCard, other.elevationCard, t)!,
      elevationSheet: lerpDouble(elevationSheet, other.elevationSheet, t)!,
      elevationModal: lerpDouble(elevationModal, other.elevationModal, t)!,
      elevationBar: lerpDouble(elevationBar, other.elevationBar, t)!,
      elevationSurface: lerpDouble(
        elevationSurface,
        other.elevationSurface,
        t,
      )!,
      breakpointCompact: lerpDouble(
        breakpointCompact,
        other.breakpointCompact,
        t,
      )!,
      breakpointRail: lerpDouble(breakpointRail, other.breakpointRail, t)!,
      breakpointTranscriptSideBySide: lerpDouble(
        breakpointTranscriptSideBySide,
        other.breakpointTranscriptSideBySide,
        t,
      )!,
      breakpointMarginDrawer: lerpDouble(
        breakpointMarginDrawer,
        other.breakpointMarginDrawer,
        t,
      )!,
      motionFast: Duration(
        milliseconds: ms(motionFast, other.motionFast).round(),
      ),
      motionStandard: Duration(
        milliseconds: ms(motionStandard, other.motionStandard).round(),
      ),
      motionEnter: Duration(
        milliseconds: ms(motionEnter, other.motionEnter).round(),
      ),
      motionExit: Duration(
        milliseconds: ms(motionExit, other.motionExit).round(),
      ),
      motionMedium: Duration(
        milliseconds: ms(motionMedium, other.motionMedium).round(),
      ),
      motionLens: Duration(
        milliseconds: ms(motionLens, other.motionLens).round(),
      ),
      motionMargin: Duration(
        milliseconds: ms(motionMargin, other.motionMargin).round(),
      ),
      echoActive: Color.lerp(echoActive, other.echoActive, t)!,
      blurActive: Color.lerp(blurActive, other.blurActive, t)!,
      scoreGood: Color.lerp(scoreGood, other.scoreGood, t)!,
      scoreWarn: Color.lerp(scoreWarn, other.scoreWarn, t)!,
      scoreBad: Color.lerp(scoreBad, other.scoreBad, t)!,
      scoreGoodContainer: Color.lerp(
        scoreGoodContainer,
        other.scoreGoodContainer,
        t,
      )!,
      scoreWarnContainer: Color.lerp(
        scoreWarnContainer,
        other.scoreWarnContainer,
        t,
      )!,
      scoreBadContainer: Color.lerp(
        scoreBadContainer,
        other.scoreBadContainer,
        t,
      )!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      intelligenceInk: Color.lerp(intelligenceInk, other.intelligenceInk, t)!,
      echoInk: Color.lerp(echoInk, other.echoInk, t)!,
      ccBadge: Color.lerp(ccBadge, other.ccBadge, t)!,
      transcriptLinePadding: EdgeInsets.lerp(
        transcriptLinePadding,
        other.transcriptLinePadding,
        t,
      )!,
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!,
      formMaxWidth: lerpDouble(formMaxWidth, other.formMaxWidth, t)!,
      hubMaxWidth: lerpDouble(hubMaxWidth, other.hubMaxWidth, t)!,
      pageGutterCompact: lerpDouble(
        pageGutterCompact,
        other.pageGutterCompact,
        t,
      )!,
      pageGutter: lerpDouble(pageGutter, other.pageGutter, t)!,
      miniBarBlurSigma: lerpDouble(
        miniBarBlurSigma,
        other.miniBarBlurSigma,
        t,
      )!,
      sidebarWidth: lerpDouble(sidebarWidth, other.sidebarWidth, t)!,
      sidebarBrandHeight: lerpDouble(
        sidebarBrandHeight,
        other.sidebarBrandHeight,
        t,
      )!,
      transportHeight: lerpDouble(transportHeight, other.transportHeight, t)!,
      heroTitleLetterSpacing: lerpDouble(
        heroTitleLetterSpacing,
        other.heroTitleLetterSpacing,
        t,
      )!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      bottomNavHeight: lerpDouble(bottomNavHeight, other.bottomNavHeight, t)!,
      desktopGutter: lerpDouble(desktopGutter, other.desktopGutter, t)!,
      modalMaxWidth: lerpDouble(modalMaxWidth, other.modalMaxWidth, t)!,
      modalMaxWidthLarge: lerpDouble(
        modalMaxWidthLarge,
        other.modalMaxWidthLarge,
        t,
      )!,
      focusRingWidth: lerpDouble(focusRingWidth, other.focusRingWidth, t)!,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t)!,
      radius2xl: lerpDouble(radius2xl, other.radius2xl, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      logoStart: Color.lerp(logoStart, other.logoStart, t)!,
      logoEnd: Color.lerp(logoEnd, other.logoEnd, t)!,
      topHighlight: Color.lerp(topHighlight, other.topHighlight, t)!,
      shellInset: lerpDouble(shellInset, other.shellInset, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      controlHeightSm: lerpDouble(controlHeightSm, other.controlHeightSm, t)!,
      controlHeight: lerpDouble(controlHeight, other.controlHeight, t)!,
      controlHeightLg: lerpDouble(controlHeightLg, other.controlHeightLg, t)!,
      shadowLift: BoxShadow.lerpList(shadowLift, other.shadowLift, t)!,
      shadowFloat: BoxShadow.lerpList(shadowFloat, other.shadowFloat, t)!,
      shadowPopover: BoxShadow.lerpList(shadowPopover, other.shadowPopover, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      sunk: Color.lerp(sunk, other.sunk, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      original: Color.lerp(original, other.original, t)!,
      originalInk: Color.lerp(originalInk, other.originalInk, t)!,
      originalSoft: Color.lerp(originalSoft, other.originalSoft, t)!,
      you: Color.lerp(you, other.you, t)!,
      youInk: Color.lerp(youInk, other.youInk, t)!,
      youSoft: Color.lerp(youSoft, other.youSoft, t)!,
      youLine: Color.lerp(youLine, other.youLine, t)!,
      onYou: Color.lerp(onYou, other.onYou, t)!,
      brandInk: Color.lerp(brandInk, other.brandInk, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shape: Color.lerp(shape, other.shape, t)!,
      tick: Color.lerp(tick, other.tick, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      video: Color.lerp(video, other.video, t)!,
      vocabNew: Color.lerp(vocabNew, other.vocabNew, t)!,
      vocabLearning: Color.lerp(vocabLearning, other.vocabLearning, t)!,
      vocabReviewing: Color.lerp(vocabReviewing, other.vocabReviewing, t)!,
      vocabMastered: Color.lerp(vocabMastered, other.vocabMastered, t)!,
      radiusKeycap: lerpDouble(radiusKeycap, other.radiusKeycap, t)!,
      radiusBadge: lerpDouble(radiusBadge, other.radiusBadge, t)!,
      radiusSegmentThumb: lerpDouble(
        radiusSegmentThumb,
        other.radiusSegmentThumb,
        t,
      )!,
      radiusControl: lerpDouble(radiusControl, other.radiusControl, t)!,
      radiusTile: lerpDouble(radiusTile, other.radiusTile, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t)!,
      radiusCardLarge: lerpDouble(radiusCardLarge, other.radiusCardLarge, t)!,
      radiusDialog: lerpDouble(radiusDialog, other.radiusDialog, t)!,
      radiusSheet: lerpDouble(radiusSheet, other.radiusSheet, t)!,
      touchTargetMin: lerpDouble(touchTargetMin, other.touchTargetMin, t)!,
      iconButtonSize: lerpDouble(iconButtonSize, other.iconButtonSize, t)!,
      iconButtonSizePhone: lerpDouble(
        iconButtonSizePhone,
        other.iconButtonSizePhone,
        t,
      )!,
      segmentHeight: lerpDouble(segmentHeight, other.segmentHeight, t)!,
      chipHeight: lerpDouble(chipHeight, other.chipHeight, t)!,
      takeChipHeight: lerpDouble(takeChipHeight, other.takeChipHeight, t)!,
      playButtonSize: lerpDouble(playButtonSize, other.playButtonSize, t)!,
      playButtonSizePhone: lerpDouble(
        playButtonSizePhone,
        other.playButtonSizePhone,
        t,
      )!,
      recordButtonSize: lerpDouble(
        recordButtonSize,
        other.recordButtonSize,
        t,
      )!,
      recordButtonSizePhone: lerpDouble(
        recordButtonSizePhone,
        other.recordButtonSizePhone,
        t,
      )!,
      originalPillWidth: lerpDouble(
        originalPillWidth,
        other.originalPillWidth,
        t,
      )!,
      originalPillHeight: lerpDouble(
        originalPillHeight,
        other.originalPillHeight,
        t,
      )!,
      originalButtonPhoneSize: lerpDouble(
        originalButtonPhoneSize,
        other.originalButtonPhoneSize,
        t,
      )!,
      tabBarHeight: lerpDouble(tabBarHeight, other.tabBarHeight, t)!,
      tabBarSafeInset: lerpDouble(tabBarSafeInset, other.tabBarSafeInset, t)!,
      playerTopBarHeight: lerpDouble(
        playerTopBarHeight,
        other.playerTopBarHeight,
        t,
      )!,
      subpageHeaderHeight: lerpDouble(
        subpageHeaderHeight,
        other.subpageHeaderHeight,
        t,
      )!,
      rulerHitHeight: lerpDouble(rulerHitHeight, other.rulerHitHeight, t)!,
      marginWidth: lerpDouble(marginWidth, other.marginWidth, t)!,
      transcriptMaxListen: lerpDouble(
        transcriptMaxListen,
        other.transcriptMaxListen,
        t,
      )!,
      transcriptMaxEcho: lerpDouble(
        transcriptMaxEcho,
        other.transcriptMaxEcho,
        t,
      )!,
      videoColumnMin: lerpDouble(videoColumnMin, other.videoColumnMin, t)!,
      videoColumnMax: lerpDouble(videoColumnMax, other.videoColumnMax, t)!,
      videoColumnShare: lerpDouble(
        videoColumnShare,
        other.videoColumnShare,
        t,
      )!,
      pageMaxBrowse: lerpDouble(pageMaxBrowse, other.pageMaxBrowse, t)!,
      pageMaxCraft: lerpDouble(pageMaxCraft, other.pageMaxCraft, t)!,
      pageMaxHub: lerpDouble(pageMaxHub, other.pageMaxHub, t)!,
      pageMaxForm: lerpDouble(pageMaxForm, other.pageMaxForm, t)!,
      gutter: lerpDouble(gutter, other.gutter, t)!,
      gutterPhone: lerpDouble(gutterPhone, other.gutterPhone, t)!,
      echoLensOpacity: lerpDoubles(echoLensOpacity, other.echoLensOpacity),
      referencePitchOpacity: lerpDouble(
        referencePitchOpacity,
        other.referencePitchOpacity,
        t,
      )!,
      strokeReferencePitch: lerpDouble(
        strokeReferencePitch,
        other.strokeReferencePitch,
        t,
      )!,
      strokeYourPitch: lerpDouble(strokeYourPitch, other.strokeYourPitch, t)!,
      strokeLoopBracket: lerpDouble(
        strokeLoopBracket,
        other.strokeLoopBracket,
        t,
      )!,
      strokeRulerTrack: lerpDouble(
        strokeRulerTrack,
        other.strokeRulerTrack,
        t,
      )!,
      shadowBrandButton: BoxShadow.lerpList(
        shadowBrandButton,
        other.shadowBrandButton,
        t,
      )!,
      shadowRecordButton: BoxShadow.lerpList(
        shadowRecordButton,
        other.shadowRecordButton,
        t,
      )!,
    );
  }
}

List<BoxShadow> _shadowLift(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(18, 20, 26, 0.08),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(color: Color.fromRGBO(18, 20, 26, 0.05), spreadRadius: 1),
      ]
    : const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.5),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(color: Color.fromRGBO(255, 255, 255, 0.06), spreadRadius: 1),
      ];

List<BoxShadow> _shadowFloat(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(18, 20, 26, 0.05),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color.fromRGBO(18, 20, 26, 0.12),
          blurRadius: 44,
          offset: Offset(0, 14),
        ),
      ]
    : const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.4),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.55),
          blurRadius: 52,
          offset: Offset(0, 18),
        ),
      ];

List<BoxShadow> _shadowBrandButton(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(79, 70, 229, 0.26),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ]
    : const [];

List<BoxShadow> _shadowRecordButton(bool light) => light
    ? const [
        BoxShadow(
          color: Color.fromRGBO(124, 58, 237, 0.32),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ]
    : const [];
