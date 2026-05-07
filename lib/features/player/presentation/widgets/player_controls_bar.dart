/// Progress + transport controls (maps web expanded controls row).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
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
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

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
      elevation: t.elevationBar,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: Padding(
        padding: EdgeInsets.fromLTRB(t.space16, t.space12, t.space16, t.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    _fmtDuration(pos),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
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
                SizedBox(
                  width: 52,
                  child: Text(
                    _fmtDuration(
                      Duration(milliseconds: (durationSec * 1000).round()),
                    ),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.only(top: t.space4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.previousLine,
                          onPressed:
                              ui.isBuffering
                                  ? null
                                  : () => ref
                                      .read(playerInteractionsProvider.notifier)
                                      .prevLine(),
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        IconButton.filled(
                          tooltip: ui.isPlaying ? l10n.pause : l10n.play,
                          iconSize: 32,
                          style: IconButton.styleFrom(
                            foregroundColor: cs.onPrimary,
                            backgroundColor: cs.primary,
                            disabledForegroundColor: cs.onSurface.withValues(
                              alpha: 0.38,
                            ),
                            disabledBackgroundColor: cs.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          onPressed:
                              ui.isBuffering
                                  ? null
                                  : () => ref
                                      .read(playerControllerProvider.notifier)
                                      .togglePlay(),
                          icon: Icon(
                            ui.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: cs.onPrimary,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.nextLine,
                          onPressed:
                              ui.isBuffering
                                  ? null
                                  : () => ref
                                      .read(playerInteractionsProvider.notifier)
                                      .nextLine(),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        IconButton(
                          tooltip: l10n.replayLine,
                          onPressed:
                              ui.isBuffering
                                  ? null
                                  : () => ref
                                      .read(playerInteractionsProvider.notifier)
                                      .replayLine(),
                          icon: const Icon(Icons.replay_rounded),
                        ),
                      ],
                    ),
                    SizedBox(width: t.space24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.echoMode,
                          color: echo.active ? t.echoActive : null,
                          onPressed: () => ref
                              .read(playerInteractionsProvider.notifier)
                              .toggleEcho(),
                          icon: const Icon(Icons.mic_none_rounded),
                        ),
                        _CcButton(mediaId: session.mediaId),
                        PopupMenuButton<double>(
                          tooltip: l10n.speed,
                          onSelected: (rate) => ref
                              .read(playerPreferencesCtrlProvider.notifier)
                              .setPlaybackRate(rate),
                          itemBuilder:
                              (ctx) => [
                                for (final r in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                                  PopupMenuItem(value: r, child: Text('${r}x')),
                              ],
                          child: Padding(
                            padding: EdgeInsets.all(t.space12),
                            child: const Icon(Icons.speed_rounded),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200, minWidth: 120),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_down_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              Expanded(
                                child: Slider(
                                  value: prefs.volume,
                                  onChanged: (v) => ref
                                      .read(playerPreferencesCtrlProvider.notifier)
                                      .setVolume(v),
                                ),
                              ),
                              Icon(
                                Icons.volume_up_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    final t = EnjoyThemeTokens.of(context);

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
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.ccBadge,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
