/// Per-cue reveal provider for the transcript blur (practice /
/// listening-focus) feature.
///
/// Returns `true` when a given cue should be rendered WITHOUT the blur
/// filter. The cue widget (`TranscriptLineTile`) ORs this with its
/// own local hover state to decide whether to wrap the body text in
/// `_BlurText`.
///
/// This provider deliberately does NOT depend on
/// `transcriptPlaybackHighlightProvider` — the active playback cue is
/// NEVER auto-revealed. See `spec.md` § Clarifications (Session
/// 2026-07-08) for the rule and the user-facing rationale.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/tap_reveal_hold_provider.dart';

part 'transcript_cue_reveal_provider.g.dart';

/// Returns `true` when [cueId] should be rendered without the blur
/// filter given the current per-media toggle and tap-reveal hold.
///
/// Always returns `true` when blur practice mode is OFF — the toggle
/// off path is the no-blur default.
///
/// When blur practice mode is ON, the cue is revealed only if the
/// tap-reveal hold currently names this cue AND its expiry has not
/// passed. Hover state is intentionally NOT read here — it lives on
/// the tile widget so per-frame hover changes do not invalidate
/// unrelated cues.
@riverpod
bool transcriptCueReveal(Ref ref, String mediaId, String cueId) {
  final blurActive = ref.watch(transcriptBlurModeProvider);
  if (!blurActive) return true;

  final hold = ref.watch(tapRevealHoldProvider(mediaId));
  if (hold == null) return false;
  if (hold.cueId != cueId) return false;
  return hold.isActiveAt(DateTime.now());
}
