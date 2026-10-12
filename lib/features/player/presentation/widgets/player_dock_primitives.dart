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
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/features/onboarding/domain/onboarding_tip_id.dart';
import 'package:enjoy_player/features/onboarding/presentation/onboarding_target.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String formatRateCore(double rate) {
  final x = (rate * 100).round() / 100;
  return x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Toggles the transcript blur (hide text) state.
class DockHideTextPill extends StatelessWidget {
  const DockHideTextPill({
    required this.active,
    required this.onToggle,
    this.iconOnly = false,
    super.key,
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

/// "3 / 12" loop / cue position chip.
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

/// Column that pairs a control with a small caption beneath it (Echo only).
class DockLabeledControl extends StatelessWidget {
  const DockLabeledControl({
    required this.label,
    required this.color,
    required this.child,
    super.key,
  });

  final String label;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
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

/// 36x36 circular icon slot shared by [DockActionPill] and the icon-only
/// phone branch of [DockOriginalPill].
class _DockPillIconSlot extends StatelessWidget {
  const _DockPillIconSlot({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}

/// Stadium-pill action button: paper pill with a 36x36 circular icon slot,
/// a flexible label, and a trailing [EnjoyKeycap]. Used by the
/// Recording-mode Cancel button and the Echo-mode Original pill.
class DockActionPill extends StatelessWidget {
  const DockActionPill({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    required this.slotColor,
    required this.inkColor,
    required this.label,
    required this.keycap,
    this.width,
    this.height,
    this.padding = const EdgeInsets.only(left: 8, right: 12),
    super.key,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;
  final Color slotColor;
  final Color inkColor;
  final String label;
  final String keycap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: EnjoyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusFull),
        pressedScale: 0.96,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: ShapeDecoration(
            color: t.paper,
            shape: const StadiumBorder(),
            shadows: t.shadowLift,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DockPillIconSlot(
                color: slotColor,
                child: Icon(icon, size: 14, color: inkColor),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              EnjoyKeycap(label: keycap),
            ],
          ),
        ),
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
                      painter: DockRecordRingPainter(color: t.youLine),
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

/// Stroke ring that backs [DockRecordButton] and the Recording-mode stop button.
class DockRecordRingPainter extends CustomPainter {
  const DockRecordRingPainter({required this.color, super.repaint});

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
  bool shouldRepaint(DockRecordRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Replay-original pill (Echo mode).
class DockOriginalPill extends StatelessWidget {
  const DockOriginalPill({
    required this.phone,
    required this.onPlay,
    super.key,
  });

  final bool phone;
  final Future<void> Function() onPlay;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (phone) {
      return Tooltip(
        message: l10n.hotkeysDescReplayLine,
        child: EnjoyPressable(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(24),
          pressedScale: 0.96,
          child: Container(
            width: t.originalButtonPhoneSize,
            height: 48,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.paper,
              shape: const StadiumBorder(),
              shadows: t.shadowLift,
            ),
            child: _DockPillIconSlot(
              color: t.originalSoft,
              child: Icon(EnjoyIcons.play, size: 14, color: t.originalInk),
            ),
          ),
        ),
      );
    }
    return DockActionPill(
      tooltip: l10n.hotkeysDescReplayLine,
      onTap: onPlay,
      icon: EnjoyIcons.play,
      slotColor: t.originalSoft,
      inkColor: t.originalInk,
      label: l10n.playerDockOriginal,
      keycap: 'S',
      width: t.originalPillWidth,
      height: t.originalPillHeight,
      padding: const EdgeInsets.only(left: 8),
    );
  }
}

/// Compact "1.00×" pill that opens the playback-rate sheet.
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
