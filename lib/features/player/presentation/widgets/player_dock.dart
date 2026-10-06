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
import 'package:enjoy_player/core/theme/typography.dart';
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
            final showLineMeta = constraints.maxWidth >= 980;
            final hidePillIconOnly = constraints.maxWidth < 1100;
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
                            hidePillIconOnly: hidePillIconOnly,
                            blurEnabled: blurEnabled,
                            playbackRate: playbackRate,
                            loopStartLine: echo.startLineIndex,
                            loopEndLine: echo.endLineIndex,
                            onToggleHideText: interactions.toggleBlur,
                            onPrev: interactions.prevLine,
                            onNext: interactions.nextLine,
                            onOriginal: interactions.replayLine,
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
                            hidePillIconOnly: hidePillIconOnly,
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
        borderRadius: BorderRadius.circular(t.radiusControl),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: ShapeDecoration(
            color: active ? t.ink : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? EnjoyIcons.eyeOff : EnjoyIcons.eye,
                size: 18,
                color: active ? t.paper : t.ink2,
              ),
              if (!iconOnly) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.playerDockHideText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: active ? t.paper : t.ink2,
                  ),
                ),
                const SizedBox(width: 8),
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
  const _LineCounter({
    required this.mediaId,
    this.loopStartLine,
    this.loopEndLine,
  });

  final String mediaId;

  /// Echo loop bounds; null in Listen (follows the playing cue instead).
  final int? loopStartLine;
  final int? loopEndLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final total = ref
        .watch(transcriptLinesForMediaProvider(mediaId))
        .value
        ?.length;
    final loopStart = loopStartLine;
    final loopEnd = loopEndLine;
    final looping = loopStart != null && loopEnd != null;
    String? positionText;
    if (loopStart != null && loopEnd != null) {
      positionText = loopEnd > loopStart
          ? l10n.playerDockLinesSpanPosition(
              loopStart + 1,
              loopEnd + 1,
              total ?? 0,
            )
          : l10n.playerDockLinePosition(loopStart + 1, total ?? 0);
    } else {
      final cue = ref
          .watch(transcriptPlaybackHighlightProvider(mediaId))
          .cueIndex;
      if (total != null && total > 0 && cue >= 0) {
        positionText = l10n.playerDockLinePosition(cue + 1, total);
      }
    }
    if (positionText == null) return const SizedBox.shrink();
    return Text(
      looping ? '$positionText ${l10n.playerDockLooping}' : positionText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
    final inner = size - 12;
    return OnboardingTarget(
      tipId: OnboardingTipId.playerRecord,
      onTargetAction: onToggle,
      child: Tooltip(
        message: l10n.hotkeysDescToggleRecording,
        child: EnjoyPressable(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(size / 2),
          pressedScale: 0.94,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: CustomPaint(
                      painter: _RecordRingPainter(color: t.youLine),
                    ),
                  ),
                ),
                Container(
                  width: inner,
                  height: inner,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: t.you,
                    shape: const CircleBorder(),
                    shadows: t.shadowRecordButton,
                  ),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: t.onYou,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordRingPainter extends CustomPainter {
  const _RecordRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, 2 * 3.141592653589793, false, paint);
  }

  @override
  bool shouldRepaint(_RecordRingPainter oldDelegate) =>
      oldDelegate.color != color;
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
          padding: phone ? EdgeInsets.zero : const EdgeInsets.only(left: 8),
          decoration: ShapeDecoration(
            color: t.paper,
            shape: const StadiumBorder(),
            shadows: t.shadowLift,
          ),
          child: phone
              ? Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: t.originalSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      EnjoyIcons.play,
                      size: 14,
                      color: t.originalInk,
                    ),
                  ),
                )
              : Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: t.originalSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        EnjoyIcons.play,
                        size: 14,
                        color: t.originalInk,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        l10n.playerDockOriginal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.originalInk,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const EnjoyKeycap(label: 'S'),
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
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            text,
            style: enjoyMonoStyle(
              context,
              size: 13,
              weight: FontWeight.w500,
              color: t.ink2,
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
    required this.showLineMeta,
    required this.hidePillIconOnly,
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
  final bool showLineMeta;
  final bool hidePillIconOnly;
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
    final left = Row(
      children: [
        _HideTextPill(
          active: blurEnabled,
          onToggle: onToggleHideText,
          iconOnly: hidePillIconOnly,
        ),
        if (showLineMeta) ...[
          const SizedBox(width: 12),
          Flexible(child: _LineCounter(mediaId: mediaId)),
        ],
      ],
    );
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!phone)
          _DockIconButton(
            icon: EnjoyIcons.replay,
            tooltip: l10n.replayLine,
            enabled: !buffering,
            onTap: onReplay,
          ),
        _DockIconButton(
          icon: EnjoyIcons.skipBack,
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
          icon: EnjoyIcons.skipForward,
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
      return Row(
        children: [
          _HideTextPill(
            active: blurEnabled,
            onToggle: onToggleHideText,
            iconOnly: true,
          ),
          const Spacer(),
          center,
          const Spacer(),
          _SpeedPill(rate: playbackRate, onOpen: onSpeed),
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
    required this.hidePillIconOnly,
    required this.blurEnabled,
    required this.playbackRate,
    required this.loopStartLine,
    required this.loopEndLine,
    required this.onToggleHideText,
    required this.onPrev,
    required this.onNext,
    required this.onOriginal,
    required this.onRecord,
    required this.onSpeed,
  });

  final String mediaId;
  final bool phone;
  final bool showLineMeta;
  final bool hidePillIconOnly;
  final bool blurEnabled;
  final double playbackRate;
  final int loopStartLine;
  final int loopEndLine;
  final Future<void> Function() onToggleHideText;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onOriginal;
  final VoidCallback onRecord;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final left = Row(
      children: [
        _HideTextPill(
          active: blurEnabled,
          onToggle: onToggleHideText,
          iconOnly: hidePillIconOnly,
        ),
        if (showLineMeta) ...[
          const SizedBox(width: 12),
          Flexible(
            child: _LineCounter(
              mediaId: mediaId,
              loopStartLine: loopStartLine,
              loopEndLine: loopEndLine,
            ),
          ),
        ],
      ],
    );
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DockIconButton(
          icon: EnjoyIcons.skipBack,
          tooltip: l10n.previousLine,
          onTap: onPrev,
        ),
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
              children: [
                _OriginalPill(phone: phone, onPlay: onOriginal),
                const SizedBox(width: 6),
                _RecordButton(phone: phone, onToggle: onRecord),
              ],
            ),
          ),
        ),
        _DockIconButton(
          icon: EnjoyIcons.skipForward,
          tooltip: l10n.nextLine,
          onTap: onNext,
        ),
      ],
    );
    final right = !phone
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SpeedPill(rate: playbackRate, onOpen: onSpeed),
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
      height: 76,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
                      width: 150,
                      height: 52,
                      padding: const EdgeInsets.only(left: 8, right: 12),
                      decoration: ShapeDecoration(
                        color: t.paper,
                        shape: const StadiumBorder(),
                        shadows: t.shadowLift,
                      ),
                      child: Row(
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
                          const SizedBox(width: 6),
                          const EnjoyKeycap(label: 'Esc'),
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
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: Padding(
                                padding: const EdgeInsets.all(1.5),
                                child: CustomPaint(
                                  painter: _RecordRingPainter(color: t.youLine),
                                ),
                              ),
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: ShapeDecoration(
                                color: t.you,
                                shape: const CircleBorder(),
                                shadows: t.shadowRecordButton,
                              ),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: t.onYou,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
