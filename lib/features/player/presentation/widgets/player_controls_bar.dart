/// Progress + transport controls (maps web expanded controls row).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';
import '../../../transcript/application/all_transcripts_provider.dart';
import '../../../transcript/presentation/subtitle_track_picker_sheet.dart';
import '../../application/display_position_provider.dart';
import '../../application/echo_mode_provider.dart';
import '../../application/player_controller.dart';
import '../../application/player_interactions.dart';
import '../../application/player_preferences_provider.dart';
import '../../application/player_ui_provider.dart';

class PlayerControlsBar extends ConsumerWidget {
  const PlayerControlsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerControllerProvider);
    final ui = ref.watch(playerUiProvider);
    final prefs = ref.watch(playerPreferencesCtrlProvider);
    final echo = ref.watch(echoModeProvider);
    final l10n = AppLocalizations.of(context)!;

    if (session == null) return const SizedBox.shrink();

    final durationSec =
        session.durationSeconds > 0 ? session.durationSeconds : 1.0;

    final posAsync = ref.watch(displayPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };

    final value =
        durationSec > 0 ? pos.inMilliseconds / 1000 / durationSec : 0.0;

    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(_fmtDuration(pos)),
                Expanded(
                  child: Slider(
                    value: value.clamp(0, 1),
                    onChanged: (v) {
                      ref
                          .read(playerInteractionsProvider.notifier)
                          .seekToProgressFraction(v);
                    },
                  ),
                ),
                Text(
                  _fmtDuration(
                    Duration(milliseconds: (durationSec * 1000).round()),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.previousLine,
                      onPressed:
                          ui.isBuffering
                              ? null
                              : () =>
                                  ref
                                      .read(playerInteractionsProvider.notifier)
                                      .prevLine(),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    IconButton.filled(
                      tooltip: ui.isPlaying ? l10n.pause : l10n.play,
                      onPressed:
                          ui.isBuffering
                              ? null
                              : () =>
                                  ref
                                      .read(playerControllerProvider.notifier)
                                      .togglePlay(),
                      icon: Icon(ui.isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    IconButton(
                      tooltip: l10n.nextLine,
                      onPressed:
                          ui.isBuffering
                              ? null
                              : () =>
                                  ref
                                      .read(playerInteractionsProvider.notifier)
                                      .nextLine(),
                      icon: const Icon(Icons.skip_next),
                    ),
                    IconButton(
                      tooltip: l10n.replayLine,
                      onPressed:
                          ui.isBuffering
                              ? null
                              : () =>
                                  ref
                                      .read(playerInteractionsProvider.notifier)
                                      .replayLine(),
                      icon: const Icon(Icons.replay),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.echoMode,
                      color:
                          echo.active
                              ? Theme.of(context).colorScheme.primary
                              : null,
                      onPressed:
                          () =>
                              ref
                                  .read(playerInteractionsProvider.notifier)
                                  .toggleEcho(),
                      icon: const Icon(Icons.mic_none),
                    ),
                    _CcButton(mediaId: session.mediaId),
                    PopupMenuButton<double>(
                      tooltip: l10n.speed,
                      onSelected:
                          (rate) => ref
                              .read(playerPreferencesCtrlProvider.notifier)
                              .setPlaybackRate(rate),
                      itemBuilder:
                          (ctx) => [
                            for (final r in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                              PopupMenuItem(value: r, child: Text('${r}x')),
                          ],
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.speed),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          const Icon(Icons.volume_down, size: 20),
                          Expanded(
                            child: Slider(
                              value: prefs.volume,
                              onChanged:
                                  (v) => ref
                                      .read(
                                        playerPreferencesCtrlProvider.notifier,
                                      )
                                      .setVolume(v),
                            ),
                          ),
                          const Icon(Icons.volume_up, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '${two(m)}:${two(s)}';
}

/// CC (closed-caption) button with a badge dot when tracks are available.
class _CcButton extends ConsumerWidget {
  const _CcButton({required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(allTranscriptsForMediaProvider(mediaId));
    final hasTrack = (tracksAsync.value ?? []).isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: l10n.subtitles,
          icon: const Icon(Icons.closed_caption_outlined),
          onPressed: () => showSubtitleTrackPicker(context, ref, mediaId),
        ),
        if (hasTrack)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
