part of '../enjoy_tokens.dart';

final class _LayoutTokens {
  const _LayoutTokens({
    required this.breakpointCompact,
    required this.breakpointRail,
    required this.breakpointTranscriptSideBySide,
    required this.breakpointMarginDrawer,
    required this.contentMaxWidth,
    required this.formMaxWidth,
    required this.hubMaxWidth,
    required this.sidebarWidth,
    required this.sidebarBrandHeight,
    required this.transportHeight,
    required this.bottomNavHeight,
    required this.modalMaxWidth,
    required this.modalMaxWidthLarge,
    required this.shellInset,
    required this.tabBarHeight,
    required this.tabBarSafeInset,
    required this.playerTopBarHeight,
    required this.subpageHeaderHeight,
    required this.rulerHitHeight,
    required this.transcriptMaxListen,
    required this.transcriptMaxEcho,
    required this.videoColumnMin,
    required this.videoColumnMax,
    required this.videoColumnShare,
    required this.pageMaxBrowse,
    required this.pageMaxCraft,
    required this.pageMaxHub,
    required this.pageMaxForm,
  });

  factory _LayoutTokens.build() => const _LayoutTokens(
    breakpointCompact: 600,
    breakpointRail: 900,
    breakpointTranscriptSideBySide: 720,
    breakpointMarginDrawer: 1100,
    contentMaxWidth: 700,
    formMaxWidth: 680,
    hubMaxWidth: 840,
    sidebarWidth: 244,
    sidebarBrandHeight: 52,
    transportHeight: 88,
    bottomNavHeight: 64,
    modalMaxWidth: 400,
    modalMaxWidthLarge: 560,
    shellInset: 0,
    tabBarHeight: 84,
    tabBarSafeInset: 26,
    playerTopBarHeight: 60,
    subpageHeaderHeight: 64,
    rulerHitHeight: 34,
    transcriptMaxListen: 700,
    transcriptMaxEcho: 760,
    videoColumnMin: 300,
    videoColumnMax: 380,
    videoColumnShare: 0.28,
    pageMaxBrowse: 1180,
    pageMaxCraft: 1080,
    pageMaxHub: 840,
    pageMaxForm: 680,
  );

  /// Pane width below which [pageGutterCompact] applies.
  final double breakpointCompact;

  /// Width at which shell switches from bottom nav to extended sidebar.
  final double breakpointRail;

  /// Width at which player shows transcript side-by-side vs stacked.
  final double breakpointTranscriptSideBySide;

  /// Player width below which the side margin opens as a drawer.
  final double breakpointMarginDrawer;

  /// Listen transcript column cap.
  final double contentMaxWidth;

  /// Centered max width for form pages (Preferences, Edit Profile, …).
  final double formMaxWidth;

  /// Centered max width for hub pages (Profile, Settings, Subscription, …).
  final double hubMaxWidth;
  final double sidebarWidth;
  final double sidebarBrandHeight;
  final double transportHeight;

  /// Mobile bottom nav content height (excluding system home-indicator inset).
  final double bottomNavHeight;

  /// Typical alert / form dialog max width.
  final double modalMaxWidth;

  /// Wide modals (e.g. assessment summary).
  final double modalMaxWidthLarge;

  /// Legacy gap between the canvas and the floating content panel; 0 in Duet.
  final double shellInset;
  final double tabBarHeight;
  final double tabBarSafeInset;
  final double playerTopBarHeight;
  final double subpageHeaderHeight;
  final double rulerHitHeight;
  final double transcriptMaxListen;
  final double transcriptMaxEcho;
  final double videoColumnMin;
  final double videoColumnMax;
  final double videoColumnShare;
  final double pageMaxBrowse;
  final double pageMaxCraft;
  final double pageMaxHub;
  final double pageMaxForm;

  _LayoutTokens copyWith({
    double? breakpointCompact,
    double? breakpointRail,
    double? breakpointTranscriptSideBySide,
    double? breakpointMarginDrawer,
    double? contentMaxWidth,
    double? formMaxWidth,
    double? hubMaxWidth,
    double? sidebarWidth,
    double? sidebarBrandHeight,
    double? transportHeight,
    double? bottomNavHeight,
    double? modalMaxWidth,
    double? modalMaxWidthLarge,
    double? shellInset,
    double? tabBarHeight,
    double? tabBarSafeInset,
    double? playerTopBarHeight,
    double? subpageHeaderHeight,
    double? rulerHitHeight,
    double? transcriptMaxListen,
    double? transcriptMaxEcho,
    double? videoColumnMin,
    double? videoColumnMax,
    double? videoColumnShare,
    double? pageMaxBrowse,
    double? pageMaxCraft,
    double? pageMaxHub,
    double? pageMaxForm,
  }) {
    return _LayoutTokens(
      breakpointCompact: breakpointCompact ?? this.breakpointCompact,
      breakpointRail: breakpointRail ?? this.breakpointRail,
      breakpointTranscriptSideBySide:
          breakpointTranscriptSideBySide ?? this.breakpointTranscriptSideBySide,
      breakpointMarginDrawer:
          breakpointMarginDrawer ?? this.breakpointMarginDrawer,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      formMaxWidth: formMaxWidth ?? this.formMaxWidth,
      hubMaxWidth: hubMaxWidth ?? this.hubMaxWidth,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      sidebarBrandHeight: sidebarBrandHeight ?? this.sidebarBrandHeight,
      transportHeight: transportHeight ?? this.transportHeight,
      bottomNavHeight: bottomNavHeight ?? this.bottomNavHeight,
      modalMaxWidth: modalMaxWidth ?? this.modalMaxWidth,
      modalMaxWidthLarge: modalMaxWidthLarge ?? this.modalMaxWidthLarge,
      shellInset: shellInset ?? this.shellInset,
      tabBarHeight: tabBarHeight ?? this.tabBarHeight,
      tabBarSafeInset: tabBarSafeInset ?? this.tabBarSafeInset,
      playerTopBarHeight: playerTopBarHeight ?? this.playerTopBarHeight,
      subpageHeaderHeight: subpageHeaderHeight ?? this.subpageHeaderHeight,
      rulerHitHeight: rulerHitHeight ?? this.rulerHitHeight,
      transcriptMaxListen: transcriptMaxListen ?? this.transcriptMaxListen,
      transcriptMaxEcho: transcriptMaxEcho ?? this.transcriptMaxEcho,
      videoColumnMin: videoColumnMin ?? this.videoColumnMin,
      videoColumnMax: videoColumnMax ?? this.videoColumnMax,
      videoColumnShare: videoColumnShare ?? this.videoColumnShare,
      pageMaxBrowse: pageMaxBrowse ?? this.pageMaxBrowse,
      pageMaxCraft: pageMaxCraft ?? this.pageMaxCraft,
      pageMaxHub: pageMaxHub ?? this.pageMaxHub,
      pageMaxForm: pageMaxForm ?? this.pageMaxForm,
    );
  }

  _LayoutTokens lerp(_LayoutTokens other, double t) {
    return _LayoutTokens(
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
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!,
      formMaxWidth: lerpDouble(formMaxWidth, other.formMaxWidth, t)!,
      hubMaxWidth: lerpDouble(hubMaxWidth, other.hubMaxWidth, t)!,
      sidebarWidth: lerpDouble(sidebarWidth, other.sidebarWidth, t)!,
      sidebarBrandHeight: lerpDouble(
        sidebarBrandHeight,
        other.sidebarBrandHeight,
        t,
      )!,
      transportHeight: lerpDouble(transportHeight, other.transportHeight, t)!,
      bottomNavHeight: lerpDouble(bottomNavHeight, other.bottomNavHeight, t)!,
      modalMaxWidth: lerpDouble(modalMaxWidth, other.modalMaxWidth, t)!,
      modalMaxWidthLarge: lerpDouble(
        modalMaxWidthLarge,
        other.modalMaxWidthLarge,
        t,
      )!,
      shellInset: lerpDouble(shellInset, other.shellInset, t)!,
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
    );
  }
}
