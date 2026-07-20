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

  /// When false, only remote/cloud hint copy (e.g. YouTube — no local file).
  final bool showImportButton;

  /// When true with [onExtract], shows an Extract control.
  final bool showExtractButton;

  /// When true with [onGenerate], shows an AI transcript control.
  final bool showGenerateButton;

  bool get _hasLocalActions =>
      showImportButton || showExtractButton || showGenerateButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hint = _hasLocalActions
        ? l10n.noTranscriptHint
        : l10n.noTranscriptHintRemote;

    return LayoutBuilder(
      builder: (context, viewport) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      EnjoyIllustrations.emptyTranscript,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: t.space20),
                    Text(
                      l10n.noTranscript,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space8),
                    Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    if (_hasLocalActions) ...[
                      SizedBox(height: t.space24),
                      _EmptyActionColumn(
                        children: [
                          if (showGenerateButton && onGenerate != null)
                            TranscriptBusyButton(
                              icon: Icons.auto_awesome_rounded,
                              label: l10n.transcriptEmptyGenerate,
                              onPressed: onGenerate!,
                              filled: true,
                            ),
                          if (showImportButton)
                            TranscriptBusyButton(
                              icon: Icons.upload_file_rounded,
                              label: l10n.transcriptEmptyAddSubtitle,
                              onPressed: onImport,
                              filled: !showGenerateButton,
                            ),
                          if (showExtractButton && onExtract != null)
                            TranscriptBusyButton(
                              icon: Icons.subtitles_outlined,
                              label: l10n.transcriptEmptyExtract,
                              onPressed: onExtract!,
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

class _EmptyActionColumn extends StatelessWidget {
  const _EmptyActionColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: t.space8),
          children[i],
        ],
      ],
    );
  }
}
