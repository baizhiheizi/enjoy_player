/// Placeholder when a medium has no transcript cues yet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TranscriptEmptyState extends StatelessWidget {
  const TranscriptEmptyState({
    required this.onImport,
    this.onExtract,
    this.showImportButton = true,
    this.showExtractButton = false,
    super.key,
  });

  final VoidCallback onImport;

  /// Embedded subtitle extract (local video only).
  final VoidCallback? onExtract;

  /// When false, only cloud/hint copy (e.g. YouTube — no local file to import).
  final bool showImportButton;

  /// When true with [onExtract], shows an Extract control next to import.
  final bool showExtractButton;

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
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
                    if (showExtractButton || showImportButton) ...[
                      SizedBox(height: t.space24),
                      Wrap(
                        spacing: t.space8,
                        runSpacing: t.space8,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (showExtractButton && onExtract != null)
                            OutlinedButton.icon(
                              onPressed: onExtract,
                              icon: const Icon(Icons.subtitles_outlined),
                              label: Text(l10n.transcriptEmptyExtract),
                            ),
                          if (showImportButton)
                            FilledButton.icon(
                              onPressed: onImport,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(l10n.transcriptEmptyAddSubtitle),
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
