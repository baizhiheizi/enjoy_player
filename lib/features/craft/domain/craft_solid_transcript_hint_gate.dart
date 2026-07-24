/// Once-per-app-session gate for the Craft solid-transcript STT hint.
///
/// After a Craft save that wrote solid synthesis cues, UI may show a snackbar
/// pointing learners at regenerate-via-STT. [consume] returns `true` only the
/// first time in the process lifetime.
library;

import 'package:flutter/foundation.dart';

/// Session-scoped gate for [craftSolidTranscriptSttHint].
abstract final class CraftSolidTranscriptHintGate {
  static bool _shownThisSession = false;

  /// Returns `true` once, then `false` until process restart (or [resetForTests]).
  static bool consume() {
    if (_shownThisSession) return false;
    _shownThisSession = true;
    return true;
  }

  /// Whether the hint has already been consumed this session.
  @visibleForTesting
  static bool get shownThisSession => _shownThisSession;

  @visibleForTesting
  static void resetForTests() {
    _shownThisSession = false;
  }
}
