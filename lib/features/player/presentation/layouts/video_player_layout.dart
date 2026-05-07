/// Video surface + transcript side panel (desktop-friendly split).
library;

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class VideoPlayerLayout extends StatelessWidget {
  const VideoPlayerLayout({
    required this.controller,
    required this.transcript,
    super.key,
  });

  final VideoController controller;
  final Widget transcript;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth > t.breakpointTranscriptSideBySide;
        if (wide) {
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Video(
                      controller: controller,
                      controls: AdaptiveVideoControls,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: transcript,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Video(
                  controller: controller,
                  controls: AdaptiveVideoControls,
                ),
              ),
            ),
            Expanded(flex: 3, child: transcript),
          ],
        );
      },
    );
  }
}
