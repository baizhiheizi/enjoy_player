import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';

class AudioStagePreviewPlayer extends StatelessWidget {
  const AudioStagePreviewPlayer({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
    required this.fmt,
    required this.theme,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;
  final String Function(Duration) fmt;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final timeStyle = enjoyMonoStyle(
      context,
      size: 12,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final clampedPosition = position > duration && duration > Duration.zero
        ? duration
        : position;
    final maxMs = duration.inMilliseconds.toDouble().clamp(
      1.0,
      double.infinity,
    );
    final valueMs = clampedPosition.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return EnjoyCard(
      elevated: false,
      padding: EdgeInsets.symmetric(horizontal: t.space12, vertical: t.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          EnjoyPressable(
            onTap: onToggle,
            shape: const CircleBorder(),
            pressedScale: 0.95,
            child: AnimatedContainer(
              duration: t.motionFast,
              width: 56,
              height: 56,
              decoration: ShapeDecoration(
                gradient: t.brand,
                shape: const CircleBorder(),
                shadows: t.shadowBrandButton,
              ),
              child: Icon(
                isPlaying ? EnjoyIcons.pause : EnjoyIcons.play,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: t.space12),
          Text(fmt(clampedPosition), style: timeStyle),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: valueMs,
                max: maxMs,
                onChanged: duration > Duration.zero
                    ? (v) => onSeek(Duration(milliseconds: v.round()))
                    : null,
              ),
            ),
          ),
          Text(fmt(duration), style: timeStyle),
        ],
      ),
    );
  }
}
