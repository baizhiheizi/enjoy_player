/// Duet player dock shared visual primitives (ADR-0093).
///
/// Library-private widgets used by every mode-specific controls row in
/// `player_dock.dart` (Listen / Echo / Recording). Extracted to keep
/// `player_dock.dart` small and let each mode variant be edited in isolation.
library;

import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_lens_provider.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/player_lens.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart';
import 'package:enjoy_player/features/transcript/application/transcript_line_recording_counts_provider.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String formatRateCore(double rate) {
  final x = (rate * 100).round() / 100;
  return x.toStringAsFixed(2).replaceFirst(RegExp(r'(?<=\.\d)0$'), '');
}

/// The dock's left readout: where you are (line, loop, dictation) over a
/// one-line hint (practised lines, loop length, recording progress, peek).
class DockReadout extends ConsumerWidget {
  const DockReadout({
    required this.mediaId,
    required this.recording,
    this.showHint = true,
    super.key,
  });

  final String mediaId;

  /// Watched once by the dock and passed down, so the controls row and this
  /// readout can never disagree about whether a take is being recorded.
  final bool recording;
  final bool showHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final total = ref
        .watch(transcriptLinesForMediaProvider(mediaId))
        .value
        ?.length;
    final lens = ref.watch(playerLensProvider);
    final hasLines = total != null && total > 0;
    if (!hasLines) return const SizedBox.shrink();
    final echo = ref.watch(echoModeProvider);
    final cue = ref
        .watch(transcriptPlaybackHighlightProvider(mediaId))
        .cueIndex;
    final line = cue >= 0 ? cue + 1 : 1;

    final String meta;
    Widget? hint;
    switch (lens) {
      case PlayerLens.echo:
        final loopSeconds = (echo.endTimeSeconds - echo.startTimeSeconds).clamp(
          0.0,
          double.infinity,
        );
        meta = echo.endLineIndex > echo.startLineIndex
            ? l10n.playerDockLoopingLines(
                echo.startLineIndex + 1,
                echo.endLineIndex + 1,
              )
            : l10n.playerDockLoopingLine(echo.startLineIndex + 1);
        hint = recording
            ? const DockRecordingProgress()
            : Text(l10n.playerDockLoopHint(loopSeconds.toStringAsFixed(1)));
      case PlayerLens.dictate:
        meta = l10n.playerDockDictatingLine(line);
        hint = Text(
          isDesktop ? l10n.playerDockDictateHover : l10n.playerDockDictateHold,
        );
      case PlayerLens.listen:
        meta = l10n.playerDockLinePosition(line, total);
        final practised =
            (ref.watch(transcriptLineRecordingCountsProvider(mediaId)) ??
                    const <int, int>{})
                .values
                .where((count) => count > 0)
                .length;
        hint = Text(l10n.playerDockPractisedLines(practised));
    }

    return Column(
      key: const ValueKey('dock-readout'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.labelLarge?.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: t.ink,
          ),
        ),
        if (showHint) ...[
          const SizedBox(height: 4),
          DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink3),
            child: hint,
          ),
        ],
      ],
    );
  }
}

/// `Recording · 2.4s of 4.2s`, counted from when the take started.
class DockRecordingProgress extends ConsumerStatefulWidget {
  const DockRecordingProgress({super.key});

  @override
  ConsumerState<DockRecordingProgress> createState() =>
      _DockRecordingProgressState();
}

class _DockRecordingProgressState extends ConsumerState<DockRecordingProgress>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _tenths = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final tenths = elapsed.inMilliseconds ~/ 100;
      if (tenths != _tenths) setState(() => _tenths = tenths);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final echo = ref.watch(echoModeProvider);
    final target = (echo.endTimeSeconds - echo.startTimeSeconds).clamp(
      0.0,
      double.infinity,
    );
    if (target <= 0) {
      return Text((_tenths / 10).toStringAsFixed(1));
    }
    final elapsed = (_tenths / 10).clamp(0.0, target);
    return Text(
      l10n.playerDockRecordingProgress(
        elapsed.toStringAsFixed(1),
        target.toStringAsFixed(1),
      ),
    );
  }
}

/// Cycles the repeat setting: off → this item → the echo loop → off (R1).
class DockRepeatButton extends ConsumerWidget {
  const DockRepeatButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(
      playerPreferencesCtrlProvider.select((p) => p.repeatMode),
    );
    final on = mode != RepeatMode.none;
    final label = switch (mode) {
      RepeatMode.none => l10n.playerRepeatOff,
      RepeatMode.single => l10n.playerRepeatItem,
      RepeatMode.segment => l10n.playerRepeatLoop,
    };
    return Tooltip(
      message: label,
      child: EnjoyPressable(
        key: const ValueKey('dock-repeat'),
        onTap: () => ref
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(switch (mode) {
              RepeatMode.none => RepeatMode.single,
              RepeatMode.single => RepeatMode.segment,
              RepeatMode.segment => RepeatMode.none,
            }),
        borderRadius: BorderRadius.circular(t.radiusControl),
        washColor: t.sunk,
        selected: on,
        semanticsLabel: label,
        child: Container(
          width: 40,
          height: 40,
          decoration: ShapeDecoration(
            color: on ? t.originalSoft : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
          ),
          child: Icon(
            EnjoyIcons.repeat,
            size: 20,
            color: on ? t.originalInk : t.ink2,
          ),
        ),
      ),
    );
  }
}

/// Plain icon button used by the Listen and Echo transport rows.
class DockIconButton extends StatelessWidget {
  const DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
    super.key,
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

/// Brand-gradient play / pause button.
class DockPlayButton extends StatelessWidget {
  const DockPlayButton({
    required this.playing,
    required this.buffering,
    required this.phone,
    required this.onToggle,
    super.key,
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

/// Inner dot glyph drawn at the center of a [`DockRecordRing`].
enum DockRecordDotShape {
  /// Circular dot: the Echo record toggle.
  circle,

  /// Rounded-square dot: the recording-mode Stop button.
  stopSquare,
}

/// Colored "you" disk with a centered [dotShape] glyph. The caller supplies
/// the larger hit target that wraps this ring.
class DockRecordRing extends StatelessWidget {
  const DockRecordRing({
    required this.diskSize,
    required this.dotShape,
    super.key,
  });

  static const double dotSize = 16;
  static const double stopDotCornerRadius = 4;

  /// Diameter of the colored disk, in logical pixels.
  final double diskSize;

  final DockRecordDotShape dotShape;

  BoxDecoration _dotDecoration(Color color) => switch (dotShape) {
    DockRecordDotShape.circle => BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
    DockRecordDotShape.stopSquare => BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.all(
        Radius.circular(stopDotCornerRadius),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      width: diskSize,
      height: diskSize,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: t.you,
        shape: const CircleBorder(),
        shadows: t.shadowRecordButton,
      ),
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: _dotDecoration(t.onYou),
      ),
    );
  }
}

/// Round "you" record button (Echo mode).
class DockRecordButton extends StatelessWidget {
  const DockRecordButton({
    required this.phone,
    required this.onToggle,
    super.key,
  });

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
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: DockRecordRing(
                diskSize: size - (phone ? 4 : 12),
                dotShape: DockRecordDotShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Echo dock play / pause control: soft-blue circle on phones, paper pill in
/// the desktop sunk group.
class DockPlayPausePill extends StatelessWidget {
  const DockPlayPausePill({
    required this.phone,
    required this.playing,
    required this.onToggle,
    super.key,
  });

  final bool phone;
  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.hotkeysDescTogglePlay,
      child: EnjoyPressable(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(
          phone ? t.originalButtonPhoneSize / 2 : t.originalPillHeight / 2,
        ),
        pressedScale: 0.96,
        child: phone
            ? Container(
                width: t.originalButtonPhoneSize,
                height: t.originalButtonPhoneSize,
                decoration: BoxDecoration(
                  color: t.originalSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? EnjoyIcons.pause : EnjoyIcons.play,
                  size: 20,
                  color: t.originalInk,
                ),
              )
            : Container(
                width: t.originalPillWidth,
                height: t.originalPillHeight,
                padding: const EdgeInsets.only(left: 8),
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
                        color: t.originalSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playing ? EnjoyIcons.pause : EnjoyIcons.play,
                        size: 14,
                        color: t.originalInk,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        playing ? l10n.pause : l10n.play,
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
                    const SizedBox(width: 12),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The `1.0×` speed control: a 54 px mono icon button that opens the
/// playback-rate sheet.
class DockSpeedButton extends StatelessWidget {
  const DockSpeedButton({required this.rate, required this.onOpen, super.key});

  final double rate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.speed,
      child: EnjoyPressable(
        key: const ValueKey('dock-speed'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(t.radiusControl),
        washColor: t.sunk,
        child: SizedBox(
          width: 54,
          height: 40,
          child: Center(
            child: Text(
              l10n.playbackRateTimes(formatRateCore(rate)),
              style: enjoyMonoStyle(
                context,
                size: 13,
                weight: FontWeight.w600,
                color: t.ink2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
