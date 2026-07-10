/// Placeholder when a medium has no transcript cues yet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'transcript_busy_action.dart';

class TranscriptEmptyState extends StatelessWidget {
  const TranscriptEmptyState({
    required this.onImport,
    this.onExtract,
    this.onGenerate,
    this.showImportButton = true,
    this.showExtractButton = false,
    this.showGenerateButton = false,
    super.key,
  });

  final Future<void> Function() onImport;

  /// Embedded subtitle extract (local video only).
  final Future<void> Function()? onExtract;

  /// ASR transcript generation (local audio/video only).
  final Future<void> Function()? onGenerate;

  /// When false, only cloud/hint copy (e.g. YouTube — no local file to import).
  final bool showImportButton;

  /// When true with [onExtract], shows an Extract control next to import.
  final bool showExtractButton;

  /// When true with [onGenerate], shows a Generate transcript control.
  final bool showGenerateButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, viewport) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(t.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      EnjoyIllustrations.emptyTranscript,
                      height: 88,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: t.space16),
                    Text(
                      l10n.noTranscript,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space8),
                    Text(
                      l10n.noTranscriptHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    if (showExtractButton ||
                        showImportButton ||
                        showGenerateButton) ...[
                      SizedBox(height: t.space24),
                      Wrap(
                        spacing: t.space8,
                        runSpacing: t.space8,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (showGenerateButton && onGenerate != null)
                            TranscriptBusyButton(
                              icon: Icons.graphic_eq_rounded,
                              label: l10n.transcriptEmptyGenerate,
                              onPressed: onGenerate!,
                            ),
                          if (showExtractButton && onExtract != null)
                            TranscriptBusyButton(
                              icon: Icons.subtitles_outlined,
                              label: l10n.transcriptEmptyExtract,
                              onPressed: onExtract!,
                            ),
                          if (showImportButton)
                            TranscriptBusyButton(
                              icon: Icons.upload_file_rounded,
                              label: l10n.transcriptEmptyAddSubtitle,
                              onPressed: onImport,
                              filled: true,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
