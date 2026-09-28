/// When a visible cue should be auto-translated (issue #764 candidate 4).
///
/// The policy used to live in the two item builders, and they had drifted:
/// the scrollable list gated on a viewport window *and* re-checked that window
/// after the frame, while the echo card treated its own block as the viewport
/// and fired with no re-check at all. Two copies of "request an empty,
/// non-failed cue near the user" is how the stale request below survives.
///
/// Pure decision + the one frame-deferred call, so both builders share one
/// owner and the staleness re-check cannot be dropped from one of them.
library;

import 'package:flutter/widgets.dart';

import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

/// How wide the "worth translating" window is for a given surface.
enum AutoTranslateRequestScope {
  /// The scrollable list: only cues near the playback highlight or the
  /// estimated scroll position are worth a request.
  viewport,

  /// The echo card: the rendered block *is* the viewport, so every cue in it
  /// qualifies.
  block,
}

/// Whether the cue at [lineIndex] should be auto-translated now.
///
/// The shared conditions are checked **first** and the anchors only after, so a
/// list of already-translated cues (the common case while scrolling a long
/// transcript) never pays for anchor resolution — the scrollable list's
/// `_scrollFocusLineIndex` reads the `ScrollController`, and the builder calls
/// this once per row.
///
/// [anchorLineIndex] is the playback highlight and [alternateAnchorLineIndex]
/// the estimated scroll position; either one counts, and both are ignored for
/// [AutoTranslateRequestScope.block]. A negative highlight means "nothing is
/// playing yet" and collapses to line 0, matching the old inline check.
///
/// [alternateAnchorLineIndex] is a **resolver, not a value**, so it is only
/// called once the row is eligible. The scrollable list resolves it by reading
/// the `ScrollController`, and its item builder calls this for every row — pass
/// a value and that read happens on every row whether or not it is needed.
bool shouldRequestAutoTranslateLine({
  required int lineIndex,
  required int anchorLineIndex,
  int? Function()? alternateAnchorLineIndex,
  required AutoTranslateRequestScope scope,
  int viewportWindow = kAutoTranslateViewportWindow,
  required bool isAutoTranslateActive,
  required bool hasSecondaryText,
  required bool isLineFailed,
}) {
  if (!isAutoTranslateActive) return false;
  if (hasSecondaryText) return false;
  if (isLineFailed) return false;
  if (scope == AutoTranslateRequestScope.block) return true;
  if (_withinWindow(lineIndex, anchorLineIndex, viewportWindow)) return true;
  final alternate = alternateAnchorLineIndex?.call();
  return alternate != null &&
      _withinWindow(lineIndex, alternate, viewportWindow);
}

bool _withinWindow(int lineIndex, int anchor, int viewportWindow) {
  final resolved = anchor >= 0 ? anchor : 0;
  return (lineIndex - resolved).abs() <= viewportWindow;
}

/// Requests a translate one frame later, re-running [shouldRequest] first.
///
/// The frame gap is where the request goes stale: the user scrolls on, the
/// cue leaves the window, or a translation lands from the controller's own
/// queue. Re-checking is what keeps a scrolling list from firing requests for
/// cues it has already scrolled past. [isMounted] guards the element the
/// callback would otherwise touch after teardown.
///
/// [shouldRequest] is **optional and defaults to "still wanted"**, because a
/// caller whose surface *is* the viewport has nothing to re-check: the rendered
/// echo block cannot scroll out from under itself between scheduling and the
/// next frame. Forcing such a caller to pass `() => true` would be a tautology
/// dressed up as a decision.
void scheduleAutoTranslateLineRequest({
  required bool Function() isMounted,
  required void Function() request,
  bool Function()? shouldRequest,
}) {
  final stillWanted = shouldRequest ?? () => true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isMounted()) return;
    if (!stillWanted()) return;
    request();
  });
}
