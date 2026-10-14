/// Shared dialog: pick SRT or VTT before downloading the transcript.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/data/subtitle/subtitle_serializer.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Returns the chosen format, or null when the dialog is dismissed.
Future<SubtitleExportFormat?> showTranscriptExportFormatDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  return showEnjoyAlertDialog<SubtitleExportFormat>(
    context: context,
    title: Text(l10n.transcriptDownloadDialogTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, format) in SubtitleExportFormat.values.indexed) ...[
          if (i > 0) SizedBox(height: EnjoyThemeTokens.of(context).space8),
          _FormatOptionRow(format: format, autofocus: i == 0),
        ],
      ],
    ),
  );
}

class _FormatOptionRow extends StatelessWidget {
  const _FormatOptionRow({required this.format, required this.autofocus});

  final SubtitleExportFormat format;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final (label, hint) = switch (format) {
      SubtitleExportFormat.srt => (
        l10n.transcriptDownloadFormatSrtLabel,
        l10n.transcriptDownloadFormatSrtHint,
      ),
      SubtitleExportFormat.vtt => (
        l10n.transcriptDownloadFormatVttLabel,
        l10n.transcriptDownloadFormatVttHint,
      ),
    };
    return EnjoyPressable(
      onTap: () => Navigator.pop(context, format),
      autofocus: autofocus,
      borderRadius: BorderRadius.circular(10),
      pressedScale: 1,
      washColor: t.sunk,
      semanticsLabel: hint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: t.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: t.space4),
            Text(
              hint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.ink3),
            ),
          ],
        ),
      ),
    );
  }
}
