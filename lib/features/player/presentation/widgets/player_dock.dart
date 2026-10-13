/// Duet player dock (ADR-0093) — a solid paper bar under the player: the
/// sentence ruler row over a controls row, in Listen / Echo / Recording
/// variants.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
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
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_cc_fullscreen.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate.dart'
    show kPlaybackRatePresets, playbackRatesEqual;
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'player_dock_primitives.dart';

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
    final t = EnjoyThemeTokens.of(context);
    unawaited(
      showEnjoySheet<void>(
        context: context,
        builder: (sheetCtx) {
          final rate = ref.read(
            playerPreferencesCtrlProvider.select((p) => p.playbackRate),
          );
          final l10n = AppLocalizations.of(sheetCtx)!;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaddedSheetDragHandle(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      t.space20,
                      t.space4,
                      t.space20,
                      t.space8,
                    ),
                    child: Text(
                      l10n.speed,
                      style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final option in kPlaybackRatePresets)
                    ListTile(
                      title: Text(
                        l10n.playbackRateTimes(formatRateCore(option)),
                      ),
                      trailing: playbackRatesEqual(option, rate)
                          ? Icon(EnjoyIcons.check, color: t.brandInk)
                          : null,
                      onTap: () {
                        unawaited(
                          ref
                              .read(playerPreferencesCtrlProvider.notifier)
                              .setPlaybackRate(option),
                        );
                        Navigator.pop(sheetCtx);
                      },
                    ),
                  SizedBox(height: t.space16),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : t.motionMedium,
                    child: recording
                        ? _RecordingControls(
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
                        ? _EchoControls(
                            key: ValueKey<bool>(echo.active),
                            mediaId: chrome.mediaId,
                            phone: phone,
                            showLineMeta: showLineMeta,
                            playbackRate: playbackRate,
                            playing: playing,
                            onPrev: interactions.prevLine,
                            onNext: interactions.nextLine,
                            onTogglePlay: () => ref
                                .read(playerControllerProvider.notifier)
                                .togglePlay(),
                            onRecord: () => ref
                                .read(shadowReadingHotkeyBusProvider.notifier)
                                .pulseRecording(),
                            onSpeed: _openPlaybackRateSheet,
                          )
                        : _ListenControls(
                            key: ValueKey<bool>(echo.active),
                            mediaId: chrome.mediaId,
                            phone: phone,
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

class _ListenControls extends StatelessWidget {
  const _ListenControls({
    super.key,
    required this.mediaId,
    required this.phone,
    required this.showLineMeta,
    required this.echoAvailable,
    required this.playing,
    required this.buffering,
    required this.playbackRate,
    required this.showFullscreen,
    required this.onPrev,
    required this.onNext,
    required this.onReplay,
    required this.onTogglePlay,
    required this.onSpeed,
  });

  final String mediaId;
  final bool phone;
  final bool showLineMeta;
  final bool echoAvailable;
  final bool playing;
  final bool buffering;
  final double playbackRate;
  final bool showFullscreen;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onReplay;
  final VoidCallback onTogglePlay;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final left = Row(
      children: [
        Flexible(
          child: DockReadout(mediaId: mediaId, showHint: showLineMeta),
        ),
      ],
    );
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!phone)
          DockIconButton(
            icon: EnjoyIcons.replay,
            tooltip: l10n.replayLine,
            enabled: !buffering,
            onTap: onReplay,
          ),
        DockIconButton(
          icon: EnjoyIcons.skipBack,
          tooltip: l10n.previousLine,
          enabled: !buffering,
          onTap: onPrev,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DockPlayButton(
            playing: playing,
            buffering: buffering,
            phone: phone,
            onToggle: onTogglePlay,
          ),
        ),
        DockIconButton(
          icon: EnjoyIcons.skipForward,
          tooltip: l10n.nextLine,
          enabled: !buffering,
          onTap: onNext,
        ),
        if (!phone) const DockRepeatButton(),
      ],
    );
    final right = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
        if (!phone) ...[
          const SizedBox(width: 6),
          const TransportVolumeButton(),
        ],
        if (showFullscreen) ...[
          const SizedBox(width: 6),
          const TransportFullscreenButton(isVideo: true),
        ],
      ],
    );

    if (phone) {
      return Row(
        children: [
          DockIconButton(
            icon: EnjoyIcons.replay,
            tooltip: l10n.replayLine,
            enabled: !buffering,
            onTap: onReplay,
          ),
          const Spacer(),
          center,
          const Spacer(),
          DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
        ],
      );
    }

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(child: left),
          center,
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _EchoControls extends StatelessWidget {
  const _EchoControls({
    super.key,
    required this.mediaId,
    required this.phone,
    required this.showLineMeta,
    required this.playbackRate,
    required this.playing,
    required this.onPrev,
    required this.onNext,
    required this.onTogglePlay,
    required this.onRecord,
    required this.onSpeed,
  });

  final String mediaId;
  final bool phone;
  final bool showLineMeta;
  final double playbackRate;
  final bool playing;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final VoidCallback onTogglePlay;
  final VoidCallback onRecord;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final left = Row(
      children: [
        Flexible(
          child: DockReadout(mediaId: mediaId, showHint: showLineMeta),
        ),
      ],
    );
    final playPause = DockPlayPausePill(
      phone: phone,
      playing: playing,
      onToggle: onTogglePlay,
    );
    final record = DockRecordButton(phone: phone, onToggle: onRecord);
    final skipBack = DockIconButton(
      icon: EnjoyIcons.skipBack,
      tooltip: l10n.previousLine,
      onTap: onPrev,
    );
    final skipForward = DockIconButton(
      icon: EnjoyIcons.skipForward,
      tooltip: l10n.nextLine,
      onTap: onNext,
    );
    final Widget center;
    if (phone) {
      final zone = t.recordButtonSizePhone;
      Widget zoneBox(Widget child) => SizedBox(
        height: zone,
        child: Center(child: child),
      );
      center = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          zoneBox(skipBack),
          const SizedBox(width: 10),
          DockLabeledControl(
            zoneHeight: zone,
            label: playing ? l10n.pause : l10n.play,
            color: t.originalInk,
            child: playPause,
          ),
          const SizedBox(width: 16),
          DockLabeledControl(
            zoneHeight: zone,
            label: l10n.playerDockRecord,
            color: t.youInk,
            child: record,
          ),
          const SizedBox(width: 10),
          zoneBox(skipForward),
        ],
      );
    } else {
      center = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          skipBack,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: ShapeDecoration(
                color: t.sunk,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [playPause, const SizedBox(width: 6), record],
              ),
            ),
          ),
          skipForward,
        ],
      );
    }
    final right = !phone
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
              const SizedBox(width: 6),
              const TransportVolumeButton(),
            ],
          )
        : const SizedBox.shrink();

    if (phone) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [center],
        ),
      );
    }

    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(child: left),
          center,
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _RecordingControls extends StatelessWidget {
  const _RecordingControls({
    super.key,
    required this.mediaId,
    required this.phone,
    required this.showLineMeta,
    required this.playbackRate,
    required this.onSpeed,
    required this.onCancel,
    required this.onStop,
  });

  final String mediaId;
  final bool phone;
  final bool showLineMeta;
  final double playbackRate;
  final VoidCallback onSpeed;
  final VoidCallback onCancel;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final group = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 40),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: ShapeDecoration(
            color: t.sunk,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: l10n.asrLongMediaConfirmCancel,
                child: EnjoyPressable(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(t.radiusFull),
                  pressedScale: 0.96,
                  child: Container(
                    width: isDesktop ? 150 : null,
                    height: 52,
                    padding: const EdgeInsets.only(left: 8, right: 12),
                    decoration: ShapeDecoration(
                      color: t.paper,
                      shape: const StadiumBorder(),
                      shadows: t.shadowLift,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: t.sunk,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            EnjoyIcons.close,
                            size: 14,
                            color: t.ink2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            l10n.asrLongMediaConfirmCancel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: t.ink2,
                                ),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 6),
                          const EnjoyKeycap(label: 'Esc'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.shadowRecordingStop,
                child: Semantics(
                  label: l10n.shadowRecordingStop,
                  button: true,
                  child: EnjoyPressable(
                    onTap: onStop,
                    borderRadius: BorderRadius.circular(31),
                    pressedScale: 0.94,
                    child: const SizedBox(
                      width: 62,
                      height: 62,
                      child: Center(
                        child: DockRecordRing(
                          diskSize: 50,
                          dotShape: DockRecordDotShape.stopSquare,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
    if (phone) {
      return SizedBox(height: 76, child: Center(child: group));
    }
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: DockReadout(mediaId: mediaId, showHint: showLineMeta),
                ),
              ],
            ),
          ),
          group,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
                const SizedBox(width: 6),
                const TransportVolumeButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
