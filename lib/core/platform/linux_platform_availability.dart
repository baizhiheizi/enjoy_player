/// Centralized Linux-platform predicates and the runtime YouTube
/// availability decision (specs/047).
///
/// Every call site that branches on [resolveYouTubeAvailability],
/// [resolvedYouTubeAvailability], or [googleSignInAvailableOnLinux] should
/// import this module instead of scattering `Platform.isLinux` checks.
library;

import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, visibleForTesting;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/webview/linux_webview_environment.dart';

part 'linux_platform_availability.g.dart';

final _log = logNamed('YouTubeAvailability');

/// Build-time kill switch for Linux YouTube playback.
///
/// ANDed into every [resolveYouTubeAvailability] result so the documented
/// rollback posture is a one-line change shipping as a normal release
/// (specs/047 SC-008). Flip to `true` only when the runtime decision itself
/// must be overridden on all devices.
const youtubeEngineKillSwitchOn = false;

/// Why Linux YouTube playback is unavailable; UI maps each value to a
/// localized message variant (data-model Entity 1).
enum YouTubeUnavailableReason {
  runtimeMissing,
  runtimeInitFailed,
  disabledByBuild,
}

/// The single runtime answer to "can this device play YouTube right now?".
sealed class YouTubeAvailability {
  const YouTubeAvailability();

  bool get canPlay;
}

final class YouTubeAvailable extends YouTubeAvailability {
  const YouTubeAvailable();

  @override
  bool get canPlay => true;
}

final class YouTubeUnavailable extends YouTubeAvailability {
  const YouTubeUnavailable(this.reason);

  final YouTubeUnavailableReason reason;

  @override
  bool get canPlay => false;
}

YouTubeAvailability? _resolved;

/// Resolved decision snapshot for synchronous callers (engine construction).
///
/// Null until the first [resolveYouTubeAvailability] completes; synchronous
/// call sites must treat null as "unknown, ask asynchronously".
YouTubeAvailability? get resolvedYouTubeAvailability => _resolved;

final Future<YouTubeAvailability> _availableDecision =
    Future<YouTubeAvailability>.value(const YouTubeAvailable());

Future<YouTubeAvailability>? _decisionFuture;

/// Test seam: replaces the runtime probe entirely. Null in production.
@visibleForTesting
typedef YouTubeAvailabilityProbe = Future<YouTubeAvailability> Function();

/// Test seam: forces the next [resolveYouTubeAvailability] to use [probe].
@visibleForTesting
YouTubeAvailabilityProbe? debugYouTubeAvailabilityProbe;

/// Test seam: clears the cached decision so a later call re-probes.
@visibleForTesting
void debugResetYouTubeAvailability() {
  _decisionFuture = null;
  _resolved = null;
}

/// Resolves (once per process, cached) whether this device can play YouTube.
///
/// Non-Linux targets short-circuit to available without probing. The Linux
/// probe is bounded (5 s overall; inner awaits are strictly tighter) and its
/// failures map to [YouTubeUnavailable], never to a thrown error.
Future<YouTubeAvailability> resolveYouTubeAvailability() {
  if (defaultTargetPlatform != TargetPlatform.linux) return _availableDecision;
  return _decisionFuture ??= _resolve();
}

Future<YouTubeAvailability> _resolve() async {
  final availability = await _probeBounded();
  _resolved = availability;
  final reason = availability is YouTubeUnavailable
      ? availability.reason.name
      : 'none';
  _log.info('youtube availability=${availability.canPlay} reason=$reason');
  return availability;
}

Future<YouTubeAvailability> _probeBounded() async {
  if (youtubeEngineKillSwitchOn) {
    return const YouTubeUnavailable(YouTubeUnavailableReason.disabledByBuild);
  }
  final probe = debugYouTubeAvailabilityProbe;
  if (probe != null) {
    try {
      return await probe();
    } on Object catch (e, st) {
      _log.warning('youtube availability probe failed', e, st);
      return const YouTubeUnavailable(
        YouTubeUnavailableReason.runtimeInitFailed,
      );
    }
  }
  try {
    return await _probeLinuxYouTubeRuntime().timeout(
      const Duration(seconds: 5),
      onTimeout: () =>
          const YouTubeUnavailable(YouTubeUnavailableReason.runtimeInitFailed),
    );
  } on Object catch (e, st) {
    _log.warning('youtube availability probe failed', e, st);
    return const YouTubeUnavailable(YouTubeUnavailableReason.runtimeInitFailed);
  }
}

Future<YouTubeAvailability> _probeLinuxYouTubeRuntime() async {
  final environment = await ensureLinuxWebViewEnvironment();
  if (environment == null) {
    return const YouTubeUnavailable(YouTubeUnavailableReason.runtimeMissing);
  }
  final loadStop = Completer<void>();
  final headless = HeadlessInAppWebView(
    webViewEnvironment: environment,
    initialData: InAppWebViewInitialData(
      data: '<!doctype html><html><body></body></html>',
    ),
    onLoadStop: (controller, url) {
      if (!loadStop.isCompleted) loadStop.complete();
    },
  );
  try {
    await headless.run();
    await loadStop.future.timeout(const Duration(seconds: 3));
    return const YouTubeAvailable();
  } finally {
    await headless.dispose();
  }
}

@Riverpod(keepAlive: true)
Future<YouTubeAvailability> youtubeAvailability(Ref ref) =>
    resolveYouTubeAvailability();

/// Google native sign-in is **not available** on Linux.
///
/// First smoke on real Linux installs showed the `google_sign_in`
/// browser-based OAuth flow failing (ADR-0048, R10 kill switch). Linux users
/// sign in with email OTP or the web PKCE fallback instead (ADR-0084). Flip
/// back to `true` only after the provider flow is verified end-to-end.
const googleSignInAvailableOnLinux = false;
