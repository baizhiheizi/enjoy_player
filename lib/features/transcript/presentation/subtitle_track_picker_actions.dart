/// The transcript actions at the foot of the phone Subtitles & display sheet
/// (desktop puts the same actions in the player's ⋯ More menu).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'transcript_actions.dart';
import 'transcript_busy_action.dart';

class TranscriptActionsList extends StatelessWidget {
  const TranscriptActionsList({required this.actions, super.key});

  final List<TranscriptAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: EnjoyOverline(l10n.playerMoreTranscriptSection),
        ),
        for (final action in actions)
          TranscriptBusyListTile(
            key: action.key,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            icon: action.icon,
            title: action.label,
            onTap: () => action.run(context),
          ),
      ],
    );
  }
}
