/// Title + position line for the transport bar (wide layout).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';

class TransportMetaRow extends ConsumerWidget {
  const TransportMetaRow({super.key, required this.chrome});

  final PlaybackChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final posAsync = ref.watch(displayPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };

    return AnimatedSwitcher(
      duration: t.motionStandard,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Column(
        key: ValueKey<String>(chrome.mediaId),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chrome.mediaTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '${formatDurationHms(pos)} / ${formatDurationHms(Duration(milliseconds: (chrome.durationSeconds * 1000).round()))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
