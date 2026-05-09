/// Audio-only expanded player: transcript fills the body.
///
/// Unlike video, there is no separate media stage — playback chrome lives in the
/// global transport bar and (when visible) the AppBar title.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

import '../../application/player_state_providers.dart';

class AudioPlayerLayout extends ConsumerWidget {
  const AudioPlayerLayout({
    required this.transcript,
    super.key,
  });

  final Widget transcript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final isPlaying = ref.watch(playerIsPlayingProvider).value ?? false;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  t.space12,
                  t.space8,
                  t.space12,
                  t.space16,
                ),
                child: transcript,
              ),
            ),
          ),
        ),
      ],
    );

    // When playing, the AppBar is hidden — keep content out of the status bar.
    if (isPlaying) {
      return SafeArea(top: true, bottom: false, child: body);
    }
    return body;
  }
}
