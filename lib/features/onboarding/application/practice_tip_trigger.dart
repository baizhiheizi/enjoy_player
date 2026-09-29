/// One trigger-eligibility module for onboarding tips (issue #794, c4).
///
/// "When an onboarding tip may auto-start" was implemented three times in
/// presentation against the same [OnboardingController] `tryStart*` interface,
/// each surface with its own memo / race rules:
///
/// * `GlobalTransportBar` kept a `mediaId|echo=` dedupe key in its widget
///   State and scheduled `tryStartPracticeChain` post-frame from two
///   `ref.listen`s plus a build-time call;
/// * `TranscriptPanel` waited for the transcript lines query to resolve and
///   re-checked the fetch status before calling `tryStartEmptyTranscript`;
/// * `HomeScreen` fired `tryStartHomeEntries` once post-mount.
///
/// This module owns that WHEN policy once: the memo/dedupe key, the
/// query-resolution and fetch-status gates, the post-frame scheduling, and
/// the unawaited fire. Surface-specific [TriggerContext] fields (route path,
/// media id, echo / youtube state) stay at the call sites and are passed in —
/// the widgets shrink to constructing / calling this module.
///
/// Every fire is deliberately fire-and-forget via `Future.ignore()` — the
/// same error-swallowing semantics the previous call sites got from the
/// controller's own `unawaited` helper, so a failed progress read can never
/// surface an unhandled async error from a widget.
///
/// Memo scoping is deliberately not one session-wide key: the transport
/// bar's dedupe used to live in its State, so it reset on every player-route
/// remount and a tip deferred for unmounted targets could retry on the next
/// visit. [TransportPracticeTips] reproduces that mount scope, while the
/// panel / home entries keep no module-side memo (their dedupe is the
/// controller's own progress check, as before).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/onboarding/application/onboarding_controller.dart'
    show OnboardingController, onboardingControllerProvider;
import 'package:enjoy_player/features/onboarding/domain/tip_eligibility.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/video_row_for_media_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';

/// Manual provider — same rationale as `mediaRegistryProvider` /
/// `libraryMediaProvider` (riverpod_generator is not used for hand-written
/// seam classes here); a bare [Provider] in this repo's flutter_riverpod is
/// keep-alive, so every surface shares ONE module instance for the app
/// session and the module never outlives the container.
final practiceTipTriggerProvider = Provider<PracticeTipTrigger>((ref) {
  return PracticeTipTrigger(ref);
});

/// Centralizes when onboarding tips may auto-start; see the library doc.
class PracticeTipTrigger {
  PracticeTipTrigger(this._ref);

  final Ref _ref;

  OnboardingController get _controller =>
      _ref.read(onboardingControllerProvider.notifier);

  /// Per-mount practice-chain scheduler for the transport bar.
  ///
  /// Create once per widget State (the bar remounts on every player-route
  /// visit on mobile, and that remount must re-arm attempts exactly like the
  /// previous per-State memo field did).
  TransportPracticeTips transportBar() => TransportPracticeTips._(this);

  /// Fires [OnboardingController.tryStartPracticeChain] post-frame.
  ///
  /// Shared fire path for [TransportPracticeTips.schedule]; the echo-keyed
  /// practice context mirrors the previous transport-bar call: record / assess
  /// tip targets only mount while echo mode is on.
  void _firePracticeChain({
    required String routePath,
    required String mediaId,
    required bool echoActive,
  }) {
    _controller
        .tryStartPracticeChain(
          TriggerContext(
            routePath: routePath,
            mediaId: mediaId,
            hasTranscript: true,
            echoActive: echoActive,
            recordUiReady: echoActive,
            assessUiReady: echoActive,
          ),
        )
        .ignore();
  }

  /// Transcript-panel entry: one settled attempt for [mediaId].
  ///
  /// Reproduces the panel's previous race guard exactly:
  ///
  /// * an unresolved lines query gives up (the empty-state Showcase is not
  ///   mounted while loading, and starting then would complete the tip
  ///   instantly and poison progress);
  /// * non-empty lines mark the transcript available
  ///   ([OnboardingController.onTranscriptAvailable]) instead of starting a
  ///   tip;
  /// * a loading / error fetch status aborts (those empty states mount no
  ///   tip targets);
  /// * otherwise the empty-transcript tip starts, with the youtube variant
  ///   resolved from the media's video row.
  void startEmptyTranscriptIfSettled({
    required String mediaId,
    required String routePath,
  }) {
    final lines = _ref
        .read(transcriptLinesForMediaProvider(mediaId))
        .asData
        ?.value;
    // Wait until the transcript query resolves — starting while loading
    // races the empty-state Showcase mount.
    if (lines == null) return;
    if (lines.isNotEmpty) {
      _controller.onTranscriptAvailable(mediaId).ignore();
      return;
    }
    final fetchState = _ref.read(transcriptFetchStatusProvider(mediaId));
    // Loading/error empty UIs do not mount tip targets.
    if (fetchState.status == TranscriptFetchStatus.loading ||
        fetchState.status == TranscriptFetchStatus.error) {
      return;
    }
    final videoRow = _ref.read(videoRowForMediaProvider(mediaId)).asData?.value;
    _controller
        .tryStartEmptyTranscript(
          TriggerContext(
            routePath: routePath,
            mediaId: mediaId,
            isYoutube: videoRow?.provider == 'youtube',
            hasTranscript: false,
          ),
        )
        .ignore();
  }

  /// Home entry: starts the home-entries sequence for [routePath].
  ///
  /// Deduping stays in the controller (its progress check resolves pending
  /// tips), exactly like HomeScreen's previous post-mount attempt.
  void startHomeEntries({required String routePath}) {
    _controller
        .tryStartHomeEntries(
          TriggerContext(routePath: routePath.isEmpty ? '/' : routePath),
        )
        .ignore();
  }

  /// Marks [mediaId]'s transcript available — resolves the per-media
  /// empty-transcript tip and dismisses it if currently showing.
  ///
  /// Pass-through seam so the transcript panel talks only to this module;
  /// fires immediately (no post-frame), matching the panel's previous direct
  /// `onTranscriptAvailable` call from its lines listener.
  void markTranscriptAvailable({required String mediaId}) {
    _controller.onTranscriptAvailable(mediaId).ignore();
  }
}

/// Mount-scoped practice-chain scheduler for the transport bar.
///
/// Mirrors the previous `_practiceScheduleKey` State field: the dedupe key
/// `mediaId|echo=` lives exactly as long as the owning widget State, so a
/// remounted transport bar re-arms and may re-attempt a tip that the
/// controller deferred for unmounted targets.
class TransportPracticeTips {
  TransportPracticeTips._(this._trigger);

  final PracticeTipTrigger _trigger;

  String? _lastScheduleKey;

  /// Schedules one practice-chain attempt for `(mediaId, echoActive)`.
  ///
  /// Redundant schedules for the same state are dropped (the bar calls this
  /// from two `ref.listen`s plus build on every rebuild); each new state
  /// fires post-frame via [PracticeTipTrigger]. An empty [mediaId] is ignored
  /// without consuming the memo.
  void schedule({
    required String routePath,
    required String mediaId,
    required bool echoActive,
  }) {
    if (mediaId.isEmpty) return;
    final key = '$mediaId|echo=$echoActive';
    if (_lastScheduleKey == key) return;
    _lastScheduleKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trigger._firePracticeChain(
        routePath: routePath,
        mediaId: mediaId,
        echoActive: echoActive,
      );
    });
  }
}
