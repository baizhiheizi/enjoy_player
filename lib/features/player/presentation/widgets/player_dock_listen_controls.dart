/// Listen-mode controls row for the Duet player dock (ADR-0093).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_cc_fullscreen.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Replay/skip/play cluster with speed, volume, and fullscreen on the right;
/// the phone layout drops to replay + center cluster + speed.
class DockListenControls extends StatelessWidget {
  const DockListenControls({
    super.key,
    required this.mediaId,
    required this.phone,
    required this.recording,
    required this.showLineMeta,
    required this.echoAvailable,
    required this.playing,
    required this.buffering,
    required this.playbackRate,
    required this.showFullscreen,
    required this.onPrev,
    required this.onNext,
    required this.onReplay,
    required this.onTogglePlay,
    required this.onSpeed,
  });

  final String mediaId;
  final bool phone;
  final bool recording;
  final bool showLineMeta;
  final bool echoAvailable;
  final bool playing;
  final bool buffering;
  final double playbackRate;
  final bool showFullscreen;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onReplay;
  final VoidCallback onTogglePlay;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final left = Row(
      children: [
        Flexible(
          child: DockReadout(
            mediaId: mediaId,
            recording: recording,
            showHint: showLineMeta,
          ),
        ),
      ],
    );
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!phone)
          DockIconButton(
            icon: EnjoyIcons.replay,
            tooltip: l10n.replayLine,
            enabled: !buffering,
            onTap: onReplay,
          ),
        DockIconButton(
          icon: EnjoyIcons.skipBack,
          tooltip: l10n.previousLine,
          enabled: !buffering,
          onTap: onPrev,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DockPlayButton(
            playing: playing,
            buffering: buffering,
            phone: phone,
            onToggle: onTogglePlay,
          ),
        ),
        DockIconButton(
          icon: EnjoyIcons.skipForward,
          tooltip: l10n.nextLine,
          enabled: !buffering,
          onTap: onNext,
        ),
        if (!phone) const DockRepeatButton(),
      ],
    );
    final right = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
        if (!phone) ...[
          const SizedBox(width: 6),
          const TransportVolumeButton(),
        ],
        if (showFullscreen) ...[
          const SizedBox(width: 6),
          const TransportFullscreenButton(isVideo: true),
        ],
      ],
    );

    if (phone) {
      return Row(
        children: [
          DockIconButton(
            icon: EnjoyIcons.replay,
            tooltip: l10n.replayLine,
            enabled: !buffering,
            onTap: onReplay,
          ),
          const Spacer(),
          center,
          const Spacer(),
          DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
        ],
      );
    }

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(child: left),
          center,
          Expanded(child: right),
        ],
      ),
    );
  }
}
