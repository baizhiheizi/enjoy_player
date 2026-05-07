/// Audio-only layout: optional hero artwork + transcript-first reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';

import '../../application/player_controller.dart';

class AudioPlayerLayout extends ConsumerWidget {
  const AudioPlayerLayout({
    required this.transcript,
    super.key,
  });

  final Widget transcript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final session = ref.watch(playerControllerProvider);
    final cs = Theme.of(context).colorScheme;

    final thumbFile = localThumbnailFile(session?.thumbnailUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final hero = Padding(
          padding: EdgeInsets.only(bottom: t.space24),
          child: Center(
            child: Material(
              elevation: t.elevationSurface,
              borderRadius: BorderRadius.circular(t.radiusXl),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: wide ? 256 : 200,
                height: wide ? 256 : 200,
                child:
                    thumbFile != null
                        ? Image.file(
                          thumbFile,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder:
                              (_, _, _) => _AudioArtFallback(cs: cs),
                        )
                        : _AudioArtFallback(cs: cs),
              ),
            ),
          ),
        );

        final body = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.all(t.space16),
            child: transcript,
          ),
        );

        return Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                hero,
                body,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AudioArtFallback extends StatelessWidget {
  const _AudioArtFallback({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest,
            cs.primary.withValues(alpha: 0.35),
            cs.surfaceContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.audiotrack_rounded,
          size: 88,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
