/// Duet player dock shared visual primitives (ADR-0093).
///
/// Library-private widgets used by every mode-specific controls row in
/// `player_dock.dart` (Listen / Echo / Recording). Extracted to keep
/// `player_dock.dart` small and let each mode variant be edited in isolation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String formatRateCore(double rate) {
  final x = (rate * 100).round() / 100;
  return x.toStringAsFixed(2).replaceFirst(RegExp(r'(?<=\.\d)0$'), '');
}

class DockLineCounter extends ConsumerWidget {
  const DockLineCounter({
    required this.mediaId,
    this.loopStartLine,
    this.loopEndLine,
    super.key,
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

/// Column that centers a control in a shared button zone with a caption
/// beneath it (Echo dock phone row).
class DockLabeledControl extends StatelessWidget {
  const DockLabeledControl({
    required this.zoneHeight,
    required this.label,
    required this.color,
    required this.child,
    super.key,
  });

  final double zoneHeight;
  final String label;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: zoneHeight,
          child: Center(child: child),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.3,
          ),
        ),
      ],
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
                diskSize: size - 12,
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

/// Compact "1.0×" pill that opens the playback-rate sheet.
class DockSpeedPill extends StatelessWidget {
  const DockSpeedPill({required this.rate, required this.onOpen, super.key});

  final double rate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.playbackRateTimes(formatRateCore(rate));
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
