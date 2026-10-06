/// Audio-only expanded player: the centered Listen transcript column.
///
/// Unlike video, there is no separate media stage — playback chrome lives in
/// the top bar and the dock. The column caps at the Listen transcript width,
/// widening to the Echo width while a loop is active (ADR-0091 supersedes
/// ADR-0085).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

class AudioPlayerLayout extends ConsumerWidget {
  const AudioPlayerLayout({required this.transcript, super.key});

  final Widget transcript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final echoActive = ref.watch(echoModeProvider.select((e) => e.active));

    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: echoActive ? t.transcriptMaxEcho : t.transcriptMaxListen,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: transcript,
          ),
        ),
      ),
    );
  }
}
