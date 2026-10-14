/// D3.8 (ADR-0093): pronunciation assessment in the player's side margin —
/// docked beside the content on wide player windows, a drawer below that
/// (see `player_margin.dart`), replacing the centered dialog. It hosts the same [AssessmentResultBody]
/// as the narrow sheet, so replay, re-assess and per-word analysis stay
/// available on every window size.
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/player/application/player_margin_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_margin.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_body.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Opens [assessment] in the side margin (wide player windows).
Future<void> showAssessmentMargin({
  required BuildContext context,
  required AzurePronunciationAssessmentResult assessment,
  String? localeTag,
  String? recordingPath,
}) {
  return openPlayerMargin(
    context,
    PlayerMarginEntry(
      id: 'assessment:${recordingPath ?? assessment.hashCode}',
      label: AppLocalizations.of(context)!.assessmentTitle,
      echoOnly: true,
      builder: (context, close) => AssessmentMarginPanel(
        assessment: assessment,
        localeTag: localeTag ?? kDefaultLearningLanguageTag,
        recordingPath: recordingPath,
        onClose: close,
      ),
    ),
  );
}

class AssessmentMarginPanel extends ConsumerWidget {
  const AssessmentMarginPanel({
    super.key,
    required this.assessment,
    required this.localeTag,
    this.recordingPath,
    this.onClose,
  });

  final AzurePronunciationAssessmentResult assessment;
  final String localeTag;
  final String? recordingPath;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final nBest = assessment.nBest.isEmpty ? null : assessment.nBest.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerMarginHeader(
          title: l10n.assessmentMarginOverline,
          youVoice: true,
          onClose: onClose ?? () {},
        ),
        Divider(height: 1, thickness: 1, color: t.line),
        Expanded(
          child: nBest == null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.assessmentNoResultSummary),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    AssessmentResultBody(
                      nBest: nBest,
                      localeTag: localeTag,
                      recordingPath: recordingPath,
                      layoutCompact: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
