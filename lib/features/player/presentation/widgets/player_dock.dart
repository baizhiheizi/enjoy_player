/// Duet player dock (ADR-0091) — a solid paper bar under the player: the
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
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_cc_fullscreen.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_playback_rate.dart'
    show kPlaybackRatePresets, playbackRatesEqual;
import 'package:enjoy_player/features/player/presentation/widgets/transport/sentence_ruler.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String _formatRateCore(double rate) {
  final x = (rate * 100).round() / 100;
  return x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

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
                      title: Text(_formatRateCore(option)),
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
    final blurEnabled = ref.watch(transcriptBlurModeProvider);
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
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: RepaintBoundary(child: SentenceRuler(chrome: chrome)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : t.motionMedium,
                    child: recording
                        ? _RecordingControls(
                            key: ValueKey<bool>(recording),
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
                            blurEnabled: blurEnabled,
                            onToggleHideText: interactions.toggleBlur,
                            onPrev: interactions.prevLine,
                            onNext: interactions.nextLine,
                            onOriginal: interactions.replayLine,
                            onRecord: () => ref
                                .read(shadowReadingHotkeyBusProvider.notifier)
                                .pulseRecording(),
                          )
                        : _ListenControls(
                            key: ValueKey<bool>(echo.active),
                            mediaId: chrome.mediaId,
                            phone: phone,
                            blurEnabled: blurEnabled,
                            echoAvailable: hasLines || echo.active,
                            playing: playing,
                            buffering: buffering,
                            playbackRate: playbackRate,
                            showFullscreen: showFullscreen,
                            onToggleHideText: interactions.toggleBlur,
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

class _HideTextPill extends StatelessWidget {
  const _HideTextPill({
    required this.active,
    required this.onToggle,
    this.iconOnly = false,
  });

  final bool active;
  final Future<void> Function() onToggle;

  /// Phone widths render the glyph only; the label + keycap stay on desktop.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.transcriptBlurToggleTooltip,
      child: EnjoyPressable(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(t.radiusFull),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: ShapeDecoration(
            color: active ? t.ink : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(color: active ? t.ink : t.line),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? EnjoyIcons.eyeOff : EnjoyIcons.eye,
                size: 16,
                color: active ? t.ground : t.ink2,
              ),
              if (!iconOnly) ...[
                const SizedBox(width: 6),
                Text(
                  l10n.playerDockHideText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? t.ground : t.ink2,
                  ),
                ),
                const SizedBox(width: 6),
                const EnjoyKeycap(label: 'H'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LineCounter extends ConsumerWidget {
  const _LineCounter({required this.mediaId, required this.looping});

  final String mediaId;
  final bool looping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = ref
        .watch(transcriptLinesForMediaProvider(mediaId))
        .value
        ?.length;
    final cue = ref
        .watch(transcriptPlaybackHighlightProvider(mediaId))
        .cueIndex;
    if (total == null || total == 0 || cue < 0) return const SizedBox.shrink();
    return Text(
      looping
          ? '${l10n.playerDockLinePosition(cue + 1, total)} ${l10n.playerDockLooping}'
          : l10n.playerDockLinePosition(cue + 1, total),
      maxLines: 1,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12.5,
        color: t.ink3,
        fontFeatures: const [],
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? () => unawaited(onTap()) : null,
      icon: Icon(icon, size: 22),
      color: t.ink2,
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.buffering,
    required this.phone,
    required this.onToggle,
  });

  final bool playing;
  final bool buffering;
  final bool phone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final size = phone ? t.playButtonSizePhone : t.playButtonSize;
    return EnjoyPressable(
      onTap: buffering ? null : onToggle,
      borderRadius: BorderRadius.circular(size / 2),
      pressedScale: 0.94,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          gradient: t.brand,
          shape: const CircleBorder(),
          shadows: t.shadowBrandButton,
        ),
        child: Icon(
          playing ? EnjoyIcons.pause : EnjoyIcons.play,
          size: size * 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.phone, required this.onToggle});

  final bool phone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final size = phone ? t.recordButtonSizePhone : t.recordButtonSize;
    return OnboardingTarget(
      tipId: OnboardingTipId.playerRecord,
      onTargetAction: onToggle,
      child: Tooltip(
        message: l10n.hotkeysDescToggleRecording,
        child: EnjoyPressable(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(size / 2),
          pressedScale: 0.94,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.you,
              shape: const CircleBorder(),
              shadows: t.shadowRecordButton,
            ),
            child: Icon(EnjoyIcons.micFill, size: size * 0.36, color: t.onYou),
          ),
        ),
      ),
    );
  }
}

class _OriginalPill extends StatelessWidget {
  const _OriginalPill({required this.phone, required this.onPlay});

  final bool phone;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final width = phone ? t.originalButtonPhoneSize : t.originalPillWidth;
    final height = phone ? 48.0 : t.originalPillHeight;
    return Tooltip(
      message: l10n.hotkeysDescReplayLine,
      child: EnjoyPressable(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(height / 2),
        pressedScale: 0.96,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: t.originalSoft,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(EnjoyIcons.play, size: 18, color: t.originalInk),
              if (!phone) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.playerDockOriginal,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.originalInk,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  const _SpeedPill({required this.rate, required this.onOpen});

  final double rate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.playbackRateTimes(_formatRateCore(rate));
    return Tooltip(
      message: l10n.speed,
      child: EnjoyPressable(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(t.radiusFull),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: ShapeDecoration(
            shape: StadiumBorder(side: BorderSide(color: t.line)),
          ),
          child: Center(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.ink2,
              ),
            ),
          ),
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
    required this.blurEnabled,
    required this.echoAvailable,
    required this.playing,
    required this.buffering,
    required this.playbackRate,
    required this.showFullscreen,
    required this.onToggleHideText,
    required this.onPrev,
    required this.onNext,
    required this.onReplay,
    required this.onTogglePlay,
    required this.onSpeed,
  });

  final String mediaId;
  final bool phone;
  final bool blurEnabled;
  final bool echoAvailable;
  final bool playing;
  final bool buffering;
  final double playbackRate;
  final bool showFullscreen;
  final Future<void> Function() onToggleHideText;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onReplay;
  final VoidCallback onTogglePlay;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final left = LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _HideTextPill(
              active: blurEnabled,
              onToggle: onToggleHideText,
              iconOnly: phone,
            ),
            const SizedBox(width: 10),
            Flexible(child: _LineCounter(mediaId: mediaId, looping: false)),
          ],
        );
      },
    );
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DockIconButton(
          icon: EnjoyIcons.replay,
          tooltip: l10n.replayLine,
          enabled: !buffering,
          onTap: onReplay,
        ),
        _DockIconButton(
          icon: EnjoyIcons.skipBackLine,
          tooltip: l10n.previousLine,
          enabled: !buffering,
          onTap: onPrev,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _PlayButton(
            playing: playing,
            buffering: buffering,
            phone: phone,
            onToggle: onTogglePlay,
          ),
        ),
        _DockIconButton(
          icon: EnjoyIcons.skipForwardLine,
          tooltip: l10n.nextLine,
          enabled: !buffering,
          onTap: onNext,
        ),
      ],
    );
    final right = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _SpeedPill(rate: playbackRate, onOpen: onSpeed),
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
      return SizedBox(
        height: 108,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: left),
                const SizedBox(width: 10),
                right,
              ],
            ),
            const SizedBox(height: 4),
            center,
          ],
        ),
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
    required this.blurEnabled,
    required this.onToggleHideText,
    required this.onPrev,
    required this.onNext,
    required this.onOriginal,
    required this.onRecord,
  });

  final String mediaId;
  final bool phone;
  final bool blurEnabled;
  final Future<void> Function() onToggleHideText;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onOriginal;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final left = Row(
      children: [
        _HideTextPill(
          active: blurEnabled,
          onToggle: onToggleHideText,
          iconOnly: phone,
        ),
        const SizedBox(width: 10),
        Flexible(child: _LineCounter(mediaId: mediaId, looping: true)),
      ],
    );
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DockIconButton(
          icon: EnjoyIcons.skipBackLine,
          tooltip: l10n.previousLine,
          onTap: onPrev,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _OriginalPill(phone: phone, onPlay: onOriginal),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _RecordButton(phone: phone, onToggle: onRecord),
        ),
        _DockIconButton(
          icon: EnjoyIcons.skipForwardLine,
          tooltip: l10n.nextLine,
          onTap: onNext,
        ),
      ],
    );
    final right = !phone
        ? const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [TransportVolumeButton()],
          )
        : const SizedBox.shrink();

    if (phone) {
      return SizedBox(
        height: 112,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Expanded(child: left)]),
            const SizedBox(height: 4),
            center,
          ],
        ),
      );
    }

    return SizedBox(
      height: 64,
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
    required this.onCancel,
    required this.onStop,
  });

  final VoidCallback onCancel;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnjoyPressable(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(t.radiusFull),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: t.line)),
              ),
              child: Text(
                l10n.asrLongMediaConfirmCancel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.ink2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          EnjoyPressable(
            onTap: onStop,
            borderRadius: BorderRadius.circular(31),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: t.you,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(EnjoyIcons.stop, size: 18, color: t.onYou),
                  const SizedBox(width: 8),
                  Text(
                    l10n.shadowRecordingStop,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.onYou,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
