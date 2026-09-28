/// The subtitle picker action list (extract embedded, refresh cloud, import
/// file) shown below the track sections.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'subtitle_track_picker_primitives.dart';
import 'transcript_busy_action.dart';

class SubtitleActionsSection extends StatelessWidget {
  const SubtitleActionsSection({
    super.key,
    required this.horizontalPadding,
    required this.showExtractEmbedded,
    required this.showImportFile,
    required this.onExtractEmbedded,
    required this.onRefreshCloud,
    required this.onImportFile,
    this.onGenerate,
    this.showGenerate = false,
    this.hasGeneratedTrack = false,
  });

  final double horizontalPadding;
  final bool showExtractEmbedded;
  final bool showImportFile;
  final Future<void> Function() onExtractEmbedded;
  final Future<void> Function() onRefreshCloud;
  final Future<void> Function() onImportFile;
  final Future<void> Function()? onGenerate;
  final bool showGenerate;
  final bool hasGeneratedTrack;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final tiles = <Widget>[
      if (showGenerate && onGenerate != null)
        TranscriptBusyListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space4,
          ),
          icon: EnjoyIcons.waveform,
          title: hasGeneratedTrack
              ? l10n.subtitlesRegenerate
              : l10n.subtitlesGenerate,
          onTap: onGenerate!,
        ),
      if (showExtractEmbedded)
        TranscriptBusyListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space4,
          ),
          icon: EnjoyIcons.subtitles,
          title: l10n.subtitlesExtractEmbedded,
          onTap: onExtractEmbedded,
        ),
      TranscriptBusyListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space4,
        ),
        icon: EnjoyIcons.cloudDownload,
        title: l10n.subtitlesRefreshCloud,
        onTap: onRefreshCloud,
      ),
      if (showImportFile)
        TranscriptBusyListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space4,
          ),
          icon: EnjoyIcons.fileUpload,
          title: l10n.subtitlesImportFile,
          onTap: onImportFile,
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SubtitlePickerCard(
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: t.space16 + 24 + t.space16,
                  endIndent: t.space16,
                  color: cs.outlineVariant.withValues(alpha: 0.14),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.space4),
                child: tiles[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
