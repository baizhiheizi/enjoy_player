/// Progress slider + elapsed / total times for the transport bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';

class TransportProgressStrip extends ConsumerWidget {
  const TransportProgressStrip({
    super.key,
    required this.chrome,
    required this.hovered,
    required this.onHoverChanged,
  });

  final PlaybackChrome chrome;
  final bool hovered;
  final ValueChanged<bool> onHoverChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final durationSec =
        chrome.durationSeconds > 0 ? chrome.durationSeconds : 1.0;

    final posAsync = ref.watch(displayPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };
    final fraction =
        durationSec > 0 ? pos.inMilliseconds / 1000 / durationSec : 0.0;

    final timeStyle = tt.labelSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: cs.onSurfaceVariant,
    );

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Row(
        children: [
          Text(formatDurationHms(pos), style: timeStyle),
          const SizedBox(width: 8),
          Expanded(
            child: ExcludeSemantics(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: hovered ? 6 : 1,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: cs.primary,
                  inactiveTrackColor: cs.onSurface.withValues(alpha: 0.12),
                  thumbColor: cs.primary,
                ),
                child: Slider(
                  value: fraction.clamp(0, 1),
                  onChanged:
                      (v) => ref
                          .read(playerInteractionsProvider.notifier)
                          .seekToProgressFraction(v),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDurationHms(
              Duration(milliseconds: (durationSec * 1000).round()),
            ),
            style: timeStyle,
          ),
        ],
      ),
    );
  }
}
