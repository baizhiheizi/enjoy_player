/// Orchestrates [PlayerController.openMedia] resolve → engine → session publish.
///
/// The choreography runs over ONE seam (issue #750): a [PlayerOpenScope]
/// carrying open state, the two engine-swap operations it uses, and a single
/// [PlayerOpenDeps] dependency channel — never a raw `Ref`. Every async step
/// goes through [OpenSteps] so stale-generation handling cannot be omitted.
library;

import 'dart:async';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/platform/linux_platform_availability.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';
import 'package:enjoy_player/features/player/application/playback_open_resolver.dart';
import 'package:enjoy_player/features/player/application/playback_session_persister.dart';
import 'package:enjoy_player/features/player/application/player_position_tracker.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/video_poster_capture_service.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/open_media_options.dart';
import 'package:enjoy_player/features/player/domain/playable_source.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';

final _openLog = logNamed('PlayerOpenCoordinator');

/// Thrown by [OpenSteps.run] / [OpenSteps.runBounded] when the open
/// generation they guard has moved on: pure control flow for unwinding a
/// superseded open. [runPlayerOpen] catches it (EngineSwapCoordinator's own
/// guarded steps catch it too) so it must never surface as an open failure.
class OpenSupersededException implements Exception {
  const OpenSupersededException(this.step);

  /// The guarded step that observed the stale generation.
  final String step;

  @override
  String toString() => 'OpenSupersededException($step)';
}

/// One guarded-step mechanism for the open choreography (issue #750).
///
/// Generalizes the old `runBoundedEngineStep` — which bounded a step's time
/// but inserted no stale check — with the generation guard that used to be
/// nine hand-placed `isOpenStale(gen)` returns in the choreography body. Every
/// async step runs through [run] (unbounded) or [runBounded] (time-bounded,
/// wedge swallowed with a warning, exactly the old contract), and the guard is
/// applied *by the mechanism*: checked before the step so a superseded open
/// does no more work, and again after it so a superseded open cannot act on
/// the result. A step added to the choreography cannot forget the check —
/// there is nothing to remember beyond calling this.
///
/// Failures raised *by* a step (the typed open failures, retry-ladder
/// timeouts) propagate untouched; only [runBounded]'s own timeout is
/// swallowed. When the generation moved on during a step, [onSuperseded] runs
/// (best-effort cleanup) and [OpenSupersededException] unwinds the
/// choreography to [runPlayerOpen]'s quiet catch.
class OpenSteps {
  OpenSteps({required this.isStale, this.logWarning});

  /// Whether the guarded open generation has moved on (a newer open / clear /
  /// abandon). Sync sections query this instead of hand-rolling the check.
  final bool Function() isStale;

  /// Where [runBounded] reports a swallowed wedge timeout; defaults to the
  /// open coordinator's log.
  final void Function(String message)? logWarning;

  /// Runs [step] as one guarded unit and returns its result. Skips the step
  /// when the generation already moved on; when it moves on while [step]
  /// awaits, runs [onSuperseded] and throws [OpenSupersededException].
  Future<T> run<T>(
    String what,
    Future<T> Function() step, {
    Future<void> Function()? onSuperseded,
  }) async {
    if (isStale()) throw OpenSupersededException(what);
    final result = await step();
    if (isStale()) {
      if (onSuperseded != null) await onSuperseded();
      throw OpenSupersededException(what);
    }
    return result;
  }

  /// [run] bounded by [limit]: a wedged engine command is logged and
  /// swallowed so it cannot hold the open (and the loading screen) hostage —
  /// the old `runBoundedEngineStep` contract, now generation-guarded too.
  Future<void> runBounded(
    String what,
    Future<void> Function() step, {
    Duration limit = kEngineCommandTimeout,
    Future<void> Function()? onSuperseded,
  }) {
    return run<void>(what, () async {
      try {
        await step().timeout(limit);
      } on TimeoutException {
        (logWarning ?? _openLog.warning)(
          '$what timed out after $limit (engine event pump wedged?); '
          'continuing without it',
        );
      }
    }, onSuperseded: onSuperseded);
  }
}

/// The single dependency channel for [runPlayerOpen] (issue #750): every
/// collaborator that used to arrive as an interleaved raw `ref.read` inside
/// the choreography. Every provider-backed member is a **resolver** — the
/// open reads through it at use time — so nothing captured here can outlive
/// the provider it came from: `appDatabaseProvider` closes and replaces the
/// per-user database on a session switch, and the notifiers/services may
/// change scoping without this channel silently pinning a stale instance.
/// The two fire-and-forget schedulers close over the controller's own `Ref`,
/// so no `Ref` ever reaches the choreography body.
final class PlayerOpenDeps {
  PlayerOpenDeps({
    required this.persister,
    required this.db,
    required this.preferences,
    required this.echoMode,
    required this.blurMode,
    required this.posterService,
    required this.scheduleOpenSideEffects,
    required this.scheduleYoutubeMetadata,
  });

  /// Previous-session flush / cancel before the new media's restore (#653).
  final PlaybackSessionPersister Function() persister;

  /// Library rows + echo-session reads for the open.
  final AppDatabase Function() db;

  /// Applies persisted volume/rate to the freshly opened engine.
  final PlayerPreferencesCtrl Function() preferences;

  /// Echo / transcript-blur restore for the media being opened.
  final EchoMode Function() echoMode;
  final TranscriptBlurMode Function() blurMode;

  /// Frame capture for stored video thumbnails (capability-gated by caller).
  final VideoPosterCaptureService Function() posterService;

  /// Fire-and-forget transcript resolve + recording pull, bound to the
  /// controller's `Ref` and the per-open staleness check.
  final void Function({
    required int openGeneration,
    required String mediaId,
    required String dexieTargetType,
  })
  scheduleOpenSideEffects;

  /// Lazy oEmbed refresh after a YouTube open, with freshness callbacks
  /// bound to the controller's live generation/session.
  final void Function({
    required int openGeneration,
    required String mediaId,
    required PlayerEngine engine,
  })
  scheduleYoutubeMetadata;
}

/// The one open-scope seam [runPlayerOpen] receives from [PlayerController]
/// (issue #750): open state, the two engine-swap operations the choreography
/// actually uses (EngineSwapCoordinator stays the sole swap owner, issue
/// #720), the side-effect schedulers, and the [deps] channel — no mutable
/// setters, no raw `Ref`.
abstract interface class PlayerOpenScope {
  /// The open generation captured at entry; feeds every guard and freshness
  /// callback.
  int get openGeneration;

  /// Whether [gen] has been superseded by a newer open / clear / abandon.
  bool isOpenStale(int gen);

  PlayerEngine get activeEngine;

  /// The current session: the previous media's at flush time, the newly
  /// published one afterwards.
  PlaybackSession? get session;

  /// The sole session-publication point for the open choreography.
  void publishSession(PlaybackSession? next);

  PlayerPositionTracker get positionTracker;

  /// Ensures the owned engine matches [playable] — the first of the two
  /// engine-swap operations the open uses (issue #720 owns the swap).
  Future<bool> ensureEngineForPlayableSource({
    required PlayableSource playable,
    required int openGeneration,
  });

  /// Drives `engine.open` with the wedged-open retry ladder — the second of
  /// the two engine-swap operations the open uses (issue #720 owns the swap).
  Future<void> openEngineWithRetry({
    required PlayerEngine engine,
    required PlayableSource playable,
    required int openGeneration,
    required bool swappedAfterInstall,
    required Duration openTimeout,
    required Duration engineCommandTimeout,
  });

  /// The single dependency channel: everything the choreography used to pull
  /// through raw `Ref.read`.
  PlayerOpenDeps get deps;
}

Future<void> runPlayerOpen(
  PlayerOpenScope scope,
  String mediaId, {
  OpenMediaOptions options = OpenMediaOptions.defaults,
  Duration openTimeout = kEngineOpenTimeout,
  Duration engineCommandTimeout = kEngineCommandTimeout,
}) async {
  final gen = scope.openGeneration;
  final deps = scope.deps;
  final steps = OpenSteps(isStale: () => scope.isOpenStale(gen));

  try {
    await steps.run('flush previous playback session', () async {
      final previous = scope.session;
      if (previous == null) {
        deps.persister().cancel();
        return;
      }
      try {
        await deps.persister().flush(
          mediaId: previous.mediaId,
          dexieTargetType: previous.dexieTargetType,
          session: previous,
        );
      } catch (e, st) {
        _openLog.warning('flushing previous playback session failed', e, st);
      }
    });

    final resolved = await steps.run('resolve playback open', () async {
      final open = await resolvePlaybackOpen(deps.db(), mediaId);
      if (open == null) {
        throw StateError('No playable source for media $mediaId');
      }
      return open;
    });

    final video = resolved.video;
    final kind = resolved.kind;
    final dexie = resolved.dexieTargetType;
    final title = resolved.title;
    final playable = resolved.playable;
    final thumb = resolved.thumbnailUrl;
    final language = resolved.language;
    final durationSec = resolved.durationSeconds;

    await steps.run('gate YouTube availability (specs/047)', () async {
      if (playable is! YoutubePlayableSource) return;
      final availability = await resolveYouTubeAvailability();
      if (availability.canPlay) return;
      throw YouTubePlaybackUnavailableException.fromAvailability(
        availability as YouTubeUnavailable,
        videoId: playable.videoId,
      );
    });

    deps.scheduleOpenSideEffects(
      openGeneration: gen,
      mediaId: mediaId,
      dexieTargetType: dexie,
    );

    await steps.run(
      'cancel position tracker',
      () => scope.positionTracker.cancel(),
    );

    final swapped = await steps.run(
      'ensure engine for playable source',
      () => scope.ensureEngineForPlayableSource(
        playable: playable,
        openGeneration: gen,
      ),
    );

    final engine = scope.activeEngine;

    String? openPosterUrl;
    if (playable is YoutubePlayableSource) {
      openPosterUrl = remoteThumbnailForCard(
        thumb,
        youtubeVideoId: playable.videoId,
        mediaUrl: video?.mediaUrl,
      );
    }
    final metadata = engine.metadata;
    if (metadata != null) {
      metadata.markOpenTimingStart();
      metadata.setPosterUrl(openPosterUrl);
    }
    engine.warmVideoSurface();

    final persistedFuture = deps.db().echoSessionDao.getLatestForTarget(
      dexie,
      mediaId,
    )..ignore();

    await steps.run(
      'open engine with retry',
      () => scope.openEngineWithRetry(
        engine: engine,
        playable: playable,
        openGeneration: gen,
        swappedAfterInstall: swapped,
        openTimeout: openTimeout,
        engineCommandTimeout: engineCommandTimeout,
      ),
      onSuperseded: () async {
        try {
          await engine.stop();
        } catch (_) {}
      },
    );

    final SubtitleTrackControl? subtitles = switch (engine) {
      SubtitleTrackControl control => control,
      _ => null,
    };
    if (subtitles != null) {
      await steps.runBounded(
        'disableRenderedSubtitles',
        subtitles.disableRenderedSubtitles,
        limit: engineCommandTimeout,
      );
    }

    await steps.runBounded(
      'applyCurrentToEngine',
      () => deps.preferences().applyCurrentToEngine(),
      limit: engineCommandTimeout,
    );

    final persisted = await steps.run(
      'read persisted echo session',
      () => persistedFuture,
    );

    final posMs = options.restorePosition ? (persisted?.currentTimeMs ?? 0) : 0;
    if (posMs > 0) {
      await steps.runBounded(
        'position restore seek',
        () => engine.seek(Duration(milliseconds: posMs)),
        limit: engineCommandTimeout,
      );
    }

    if (options.restoreEcho && persisted != null && persisted.echoActive) {
      deps.echoMode().restoreFromSession(
        startLine: persisted.echoStartLine,
        endLine: persisted.echoEndLine,
        echoStartMs: persisted.echoStartMs ?? 0,
        echoEndMs: persisted.echoEndMs ?? 0,
      );
    } else {
      deps.echoMode().deactivate();
    }
    deps.blurMode().restoreFromSession(
      options.restoreEcho ? (persisted?.blurActive ?? false) : false,
    );

    final now = DateTime.now();
    scope.publishSession(
      PlaybackSession(
        mediaId: mediaId,
        dexieTargetType: dexie,
        mediaType: kind.storageValue,
        mediaTitle: title,
        thumbnailUrl: thumb,
        durationSeconds: durationSec > 0
            ? durationSec.toDouble()
            : posMs / 1000.0,
        currentTimeSeconds: posMs / 1000.0,
        currentSegmentIndex: options.restorePosition
            ? (persisted?.currentSegmentIndex ?? -1)
            : -1,
        language: language,
        startedAt: now,
        lastActiveAt: now,
      ),
    );

    scope.positionTracker.subscribe(
      openGeneration: gen,
      mediaId: mediaId,
      dexieTargetType: dexie,
    );

    if (playable is YoutubePlayableSource) {
      deps.scheduleYoutubeMetadata(
        openGeneration: gen,
        mediaId: mediaId,
        engine: engine,
      );
    }

    if (kind == MediaKind.video && video != null && engine is PosterCapture) {
      deps.posterService().scheduleCapture(
        mediaId: mediaId,
        video: video,
        restoredPositionMs: posMs,
        gen: gen,
        currentOpenGeneration: () => scope.openGeneration,
        currentSessionMediaId: () => scope.session?.mediaId,
        sessionDurationSeconds: () => scope.session?.durationSeconds,
        activeEngine: engine,
        onSessionThumbnail: (path) {
          final live = scope.session;
          if (live == null || live.mediaId != mediaId) {
            _openLog.fine(
              'dropping late poster thumbnail for $mediaId: live session is '
              '${live?.mediaId ?? 'null'}',
            );
            return;
          }
          scope.publishSession(live.copyWith(thumbnailUrl: path));
        },
      );
    }
  } on OpenSupersededException {
    return;
  }
}

Future<void> runPlayerOpenGuarded(
  PlayerOpenScope scope,
  String mediaId, {
  required void Function() onFailureResetSession,
  OpenMediaOptions options = OpenMediaOptions.defaults,
}) async {
  try {
    await runPlayerOpen(scope, mediaId, options: options);
  } on MediaNeedsRelocateException catch (e, st) {
    onFailureResetSession();
    _openLog.info('openMedia needs relocate for $mediaId', e, st);
    rethrow;
  } on Object catch (e, st) {
    onFailureResetSession();
    _openLog.severe('openMedia failed for $mediaId', e, st);
    rethrow;
  }
}
