/// Echo-mode controls row for the Duet player dock (ADR-0093).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_dock_primitives.dart';
import 'package:enjoy_player/features/player/presentation/widgets/transport/transport_volume_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Phone row and a desktop layout with the sunk stadium pill grouping
/// play/pause + record.
class DockEchoControls extends StatelessWidget {
  const DockEchoControls({
    super.key,
    required this.mediaId,
    required this.phone,
    required this.recording,
    required this.showLineMeta,
    required this.playbackRate,
    required this.playing,
    required this.onPrev,
    required this.onNext,
    required this.onReplay,
    required this.onTogglePlay,
    required this.onRecord,
    required this.onSpeed,
  });

  final String mediaId;
  final bool phone;
  final bool recording;
  final bool showLineMeta;
  final double playbackRate;
  final bool playing;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onReplay;
  final VoidCallback onTogglePlay;
  final VoidCallback onRecord;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
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
    final playPause = DockPlayPausePill(
      phone: phone,
      playing: playing,
      onToggle: onTogglePlay,
    );
    final record = DockRecordButton(phone: phone, onToggle: onRecord);
    final skipBack = DockIconButton(
      icon: EnjoyIcons.skipBack,
      tooltip: l10n.previousLine,
      onTap: onPrev,
    );
    final skipForward = DockIconButton(
      icon: EnjoyIcons.skipForward,
      tooltip: l10n.nextLine,
      onTap: onNext,
    );
    if (phone) {
      return Row(
        children: [
          DockIconButton(
            icon: EnjoyIcons.replay,
            tooltip: l10n.replayLine,
            onTap: onReplay,
          ),
          const Spacer(),
          skipBack,
          const SizedBox(width: 4),
          playPause,
          const SizedBox(width: 10),
          record,
          const SizedBox(width: 4),
          skipForward,
          const Spacer(),
          DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
        ],
      );
    }
    final center = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        skipBack,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: ShapeDecoration(
              color: t.sunk,
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [playPause, const SizedBox(width: 6), record],
            ),
          ),
        ),
        skipForward,
      ],
    );
    final right = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DockSpeedButton(rate: playbackRate, onOpen: onSpeed),
        const SizedBox(width: 6),
        const TransportVolumeButton(),
      ],
    );

    return SizedBox(
      height: 76,
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
