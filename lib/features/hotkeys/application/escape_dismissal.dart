/// Pure Escape (`modal.close`) priority resolution for unit tests and dispatch.
library;

import 'package:flutter/widgets.dart';

/// Whether [navigator]'s top route is a [PopupRoute] (sheet, dialog, menu).
///
/// Uses [NavigatorState.popUntil] with an immediate `true` predicate so the
/// stack is inspected without popping.
bool navigatorHasTopPopupRoute(NavigatorState? navigator) {
  if (navigator == null) return false;
  var isPopup = false;
  navigator.popUntil((route) {
    isPopup = route is PopupRoute<dynamic>;
    return true;
  });
  return isPopup;
}

/// Snapshot of overlay/navigation state for [resolveEscapeDismissal].
class EscapeDismissalContext {
  const EscapeDismissalContext({
    required this.cheatsheetOpen,
    required this.windowFullscreen,
    required this.isRecordingActive,
    required this.shellHasPopupRoute,
    required this.rootHasPopupRoute,
    required this.vocabularyPracticeOpen,
    required this.goRouterCanPop,
    required this.path,
    required this.isDesktop,
  });

  final bool cheatsheetOpen;
  final bool windowFullscreen;
  final bool isRecordingActive;

  /// Top route on the [ShellRoute] nested navigator is a [PopupRoute].
  final bool shellHasPopupRoute;

  /// Top route on GoRouter's root navigator is a [PopupRoute].
  final bool rootHasPopupRoute;

  /// In-tree vocabulary review practice overlay (not a [PopupRoute]).
  final bool vocabularyPracticeOpen;
  final bool goRouterCanPop;
  final String path;
  final bool isDesktop;

  bool get onPlayerRoute => path.startsWith('/player/');
}

enum EscapeDismissalAction {
  closeCheatsheet,
  exitFullscreen,
  cancelRecording,
  popShellPopup,
  popRootPopup,
  clearVocabularyPractice,
  popGoRouter,
  noopOnPlayer,
}

EscapeDismissalAction? resolveEscapeDismissal(EscapeDismissalContext ctx) {
  if (ctx.cheatsheetOpen) return EscapeDismissalAction.closeCheatsheet;
  if (ctx.isDesktop && ctx.windowFullscreen) {
    return EscapeDismissalAction.exitFullscreen;
  }
  if (ctx.isRecordingActive) return EscapeDismissalAction.cancelRecording;
  if (ctx.shellHasPopupRoute) return EscapeDismissalAction.popShellPopup;
  if (ctx.rootHasPopupRoute) return EscapeDismissalAction.popRootPopup;
  if (ctx.vocabularyPracticeOpen) {
    return EscapeDismissalAction.clearVocabularyPractice;
  }
  if (ctx.onPlayerRoute) return EscapeDismissalAction.noopOnPlayer;
  if (ctx.goRouterCanPop) return EscapeDismissalAction.popGoRouter;
  return null;
}
