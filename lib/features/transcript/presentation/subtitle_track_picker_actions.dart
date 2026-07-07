/// The subtitle picker action list (extract embedded, refresh cloud, import
/// file) shown below the track sections.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
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
  });

  final double horizontalPadding;
  final bool showExtractEmbedded;
  final bool showImportFile;
  final Future<void> Function() onExtractEmbedded;
  final Future<void> Function() onRefreshCloud;
  final Future<void> Function() onImportFile;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final tiles = <Widget>[
      if (showExtractEmbedded)
        TranscriptBusyListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space4,
          ),
          icon: Icons.subtitles_outlined,
          title: l10n.subtitlesExtractEmbedded,
          onTap: onExtractEmbedded,
        ),
      TranscriptBusyListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space4,
        ),
        icon: Icons.cloud_download_outlined,
        title: l10n.subtitlesRefreshCloud,
        onTap: onRefreshCloud,
      ),
      if (showImportFile)
        TranscriptBusyListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: t.space12,
            vertical: t.space4,
          ),
          icon: Icons.upload_file_rounded,
          title: l10n.subtitlesImportFile,
          onTap: onImportFile,
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(t.radiusLg),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.16)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(t.radiusLg),
          child: Material(
            type: MaterialType.transparency,
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
        ),
      ),
    );
  }
}
