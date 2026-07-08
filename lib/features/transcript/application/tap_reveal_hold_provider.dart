/// Tap-reveal hold controller for the transcript blur feature.
///
/// Per-mediaId ephemeral state holding the single cue that the user
/// most recently tapped to reveal, plus the wall-clock instant at
/// which the hold expires. Owns one `Timer` per open `mediaId` that
/// fires `null` (no cue on hold) when the duration elapses.
///
/// At most ONE cue can be on hold per media at any time. Tapping a
/// different cue replaces the hold — the prior cue re-blurs on the
/// next frame because the per-cue reveal provider compares against
/// this single record.
///
/// `autoDispose` — disposed when no tile is reading the provider; the
/// Timer is cancelled on disposal so no late callbacks fire into a
/// disposed provider.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';

part 'tap_reveal_hold_provider.g.dart';

/// Injectable wall-clock function. Default uses [DateTime.now].
/// Tests override via [TapRevealHoldCtrl.withClock].
typedef TapRevealClock = DateTime Function();

DateTime _defaultClock() => DateTime.now();

@riverpod
class TapRevealHoldCtrl extends _$TapRevealHoldCtrl {
  Timer? _timer;

  @override
  TapRevealHold? build(String mediaId) {
    ref.onDispose(_cancelTimer);
    return null;
  }

  /// Starts (or replaces) the hold for [cueId]. Cancels any previous
  /// hold and any pending Timer. [holdSeconds] <= 0 is treated as
  /// [clear].
  void setHold({required String cueId, required int holdSeconds}) {
    if (holdSeconds <= 0) {
      clear();
      return;
    }
    _cancelTimer();
    final now = _defaultClock();
    final expires = now.add(Duration(seconds: holdSeconds));
    state = TapRevealHold(cueId: cueId, expiresAt: expires);
    _timer = Timer(Duration(seconds: holdSeconds), _onTimerFire);
  }

  /// Cancels the hold immediately. Safe to call when no hold is set.
  void clear() {
    if (state == null) return;
    _cancelTimer();
    state = null;
  }

  void _onTimerFire() {
    if (!ref.mounted) return;
    state = null;
    _timer = null;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Read-only projection of the current hold. Widgets use this; the
/// notifier is reserved for the tile's tap handler.
@riverpod
TapRevealHold? tapRevealHold(Ref ref, String mediaId) {
  final ctrl = ref.watch(tapRevealHoldCtrlProvider(mediaId));
  return ctrl;
}
