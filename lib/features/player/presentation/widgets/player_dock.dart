/// Duet player dock (ADR-0093) — a solid paper bar under the player: the
/// sentence ruler row over a controls row, in Listen / Echo / Recording
/// variants.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/onboarding/application/practice_tip_trigger.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_echo_controls.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_listen_controls.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_recording_controls.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate_sheet.dart';

/// The Duet dock. Mounted by [RootShell] on `/player/:id` while a session is
/// active.
class PlayerDock extends ConsumerStatefulWidget {
  const PlayerDock({required this.chrome, super.key});

  final PlaybackChrome chrome;

  @override
  ConsumerState<PlayerDock> createState() => _PlayerDockState();
}

class _PlayerDockState extends ConsumerState<PlayerDock> {
  late final TransportPracticeTips _practiceTips;

  @override
  void initState() {
    super.initState();
    _practiceTips = ref.read(practiceTipTriggerProvider).transportBar();
  }

  void _openPlaybackRateSheet() {
    unawaited(showPlaybackRateSheet(context: context, ref: ref));
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final chrome = widget.chrome;
    final echo = ref.watch(echoModeProvider);
    final bus = ref.watch(shadowReadingHotkeyBusProvider);
    final recording = bus.isRecordingActive;
    final playing = ref.watch(playerIsPlayingProvider).value ?? false;
    final buffering = ref.watch(playerIsBufferingProvider).value ?? false;
    final hasLines =
        ref.watch(transcriptHasLinesForMediaProvider(chrome.mediaId)).value ??
        false;
    final playbackRate = ref.watch(
      playerPreferencesCtrlProvider.select((p) => p.playbackRate),
    );

    final routePath = GoRouterState.of(context).uri.path;
    if (hasLines && chrome.mediaId.isNotEmpty) {
      _practiceTips.schedule(
        routePath: routePath,
        mediaId: chrome.mediaId,
        echoActive: echo.active,
      );
    }

    final interactions = ref.read(playerInteractionsProvider);
    final showFullscreen = isDesktop && chrome.mediaType == 'video';

    return Container(
      decoration: BoxDecoration(
        color: t.paper,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final phone = constraints.maxWidth < t.breakpointCompact;
            final showLineMeta = constraints.maxWidth >= 980;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: RepaintBoundary(child: SentenceRuler(chrome: chrome)),
                ),
                Padding(
                  padding: phone
                      ? const EdgeInsets.fromLTRB(12, 4, 12, 8)
                      : const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : t.motionMedium,
                    child: recording
                        ? DockRecordingControls(
                            key: ValueKey<bool>(recording),
                            mediaId: chrome.mediaId,
                            phone: phone,
                            showLineMeta: showLineMeta,
                            playbackRate: playbackRate,
                            onSpeed: _openPlaybackRateSheet,
                            onCancel: () => ref
                                .read(shadowReadingHotkeyBusProvider.notifier)
                                .pulseRecordingCancel(),
                            onStop: () => ref
                                .read(shadowReadingHotkeyBusProvider.notifier)
                                .pulseRecording(),
                          )
                        : echo.active
                        ? DockEchoControls(
                            key: ValueKey<bool>(echo.active),
                            mediaId: chrome.mediaId,
                            phone: phone,
                            recording: recording,
                            showLineMeta: showLineMeta,
                            playbackRate: playbackRate,
                            playing: playing,
                            onPrev: interactions.prevLine,
                            onNext: interactions.nextLine,
                            onReplay: interactions.replayLine,
                            onTogglePlay: () => ref
                                .read(playerControllerProvider.notifier)
                                .togglePlay(),
                            onRecord: () => ref
                                .read(shadowReadingHotkeyBusProvider.notifier)
                                .pulseRecording(),
                            onSpeed: _openPlaybackRateSheet,
                          )
                        : DockListenControls(
                            key: ValueKey<bool>(echo.active),
                            mediaId: chrome.mediaId,
                            phone: phone,
                            recording: recording,
                            showLineMeta: showLineMeta,
                            echoAvailable: hasLines || echo.active,
                            playing: playing,
                            buffering: buffering,
                            playbackRate: playbackRate,
                            showFullscreen: showFullscreen,
                            onPrev: interactions.prevLine,
                            onNext: interactions.nextLine,
                            onReplay: interactions.replayLine,
                            onTogglePlay: () => ref
                                .read(playerControllerProvider.notifier)
                                .togglePlay(),
                            onSpeed: _openPlaybackRateSheet,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
