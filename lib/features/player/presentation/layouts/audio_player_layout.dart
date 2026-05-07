/// Audio-only layout: transcript-first reading experience.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class AudioPlayerLayout extends StatelessWidget {
  const AudioPlayerLayout({required this.transcript, super.key});

  final Widget transcript;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(t.space16),
          child: transcript,
        ),
      ),
    );
  }
}
