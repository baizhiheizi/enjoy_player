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
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
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
  int? takeNumber,
}) {
  final l10n = AppLocalizations.of(context)!;
  final heading = takeNumber == null
      ? l10n.assessmentTitle
      : l10n.takeAssessmentTitle(takeNumber);
  return openPlayerMargin(
    context,
    PlayerMarginEntry(
      id: 'assessment:${recordingPath ?? assessment.hashCode}',
      label: heading,
      echoOnly: true,
      builder: (context, close) => AssessmentMarginPanel(
        assessment: assessment,
        localeTag: localeTag ?? kDefaultLearningLanguageTag,
        recordingPath: recordingPath,
        takeNumber: takeNumber,
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
    this.takeNumber,
    this.onClose,
  });

  final AzurePronunciationAssessmentResult assessment;
  final String localeTag;
  final String? recordingPath;

  /// Shows the board's `Take 3 · Assessment` heading when known.
  final int? takeNumber;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nBest = assessment.primaryNBest;
    final number = takeNumber;
    return _MarginFrame(
      title: number == null
          ? l10n.assessmentMarginOverline
          : l10n.takeAssessmentTitle(number),
      onClose: onClose,
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
    );
  }
}

class _MarginFrame extends StatelessWidget {
  const _MarginFrame({required this.child, required this.title, this.onClose});

  final Widget child;
  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
                child: EnjoyOverline(title),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: EnjoyIconButton(
                icon: EnjoyIcons.close,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
              ),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: t.line),
        Expanded(child: child),
      ],
    );
  }
}
