/// D3.8 (ADR-0091): pronunciation assessment in the player's side margin —
/// a 340px raised panel sliding from the right edge, replacing the centered
/// dialog on wide player windows. The overall score reads in Literata, the
/// dimension rows are four-step meters, and mispronounced words get the
/// wavy you underline.
library;

import 'package:azure_speech/azure_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Opens [assessment] in the side margin (wide player windows).
Future<void> showAssessmentMargin({
  required BuildContext context,
  required AzurePronunciationAssessmentResult assessment,
  String? recordingPath,
}) {
  final route = _AssessmentMarginRoute(
    assessment: assessment,
    recordingPath: recordingPath,
  );
  return Navigator.of(context, rootNavigator: true).push(route);
}

class _AssessmentMarginRoute extends PopupRoute<void> {
  _AssessmentMarginRoute({required this.assessment, this.recordingPath});

  final AzurePronunciationAssessmentResult assessment;
  final String? recordingPath;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => 'Pronunciation assessment';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final t = EnjoyThemeTokens.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: t.marginWidth,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: t.raised,
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            shadows: t.shadowFloat,
          ),
          child: ClipRSuperellipse(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: AssessmentMarginPanel(
              assessment: assessment,
              recordingPath: recordingPath,
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

class AssessmentMarginPanel extends ConsumerWidget {
  const AssessmentMarginPanel({
    super.key,
    required this.assessment,
    this.recordingPath,
    this.onClose,
  });

  final AzurePronunciationAssessmentResult assessment;
  final String? recordingPath;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final nBest = assessment.nBest.isEmpty ? null : assessment.nBest.first;
    if (nBest == null) {
      return _MarginFrame(
        onClose: onClose,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.assessmentNoResultSummary),
        ),
      );
    }
    final scores = nBest.pronunciationAssessment;
    final overall = scores.pronScore.round();
    final words = nBest.words;

    return _MarginFrame(
      onClose: onClose,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        children: [
          Text(
            '${overall.clamp(0, 100)}',
            style: enjoyDisplayStyle(
              context,
              size: 56,
              color: t.ink,
              height: 0.86,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: 16),
          _ScoreRow(
            label: l10n.assessmentAccuracy,
            value: scores.accuracyScore,
          ),
          _ScoreRow(label: l10n.assessmentFluency, value: scores.fluencyScore),
          _ScoreRow(
            label: l10n.assessmentCompleteness,
            value: scores.completenessScore,
          ),
          _ScoreRow(
            label: l10n.assessmentProsody,
            value: scores.prosodyScore ?? 0,
          ),
          const SizedBox(height: 24),
          EnjoyOverline(l10n.assessmentWordsSection),
          const SizedBox(height: 10),
          for (final w in words)
            _WordRow(
              word: w.word,
              score: w.pronunciationAssessment.accuracyScore,
              errorType: w.pronunciationAssessment.errorType,
            ),
        ],
      ),
    );
  }
}

class _MarginFrame extends StatelessWidget {
  const _MarginFrame({required this.child, this.onClose});

  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
                child: EnjoyOverline(l10n.assessmentMarginOverline),
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final clamped = value.clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: tt.bodyMedium)),
          Text(
            clamped.round().toString(),
            style: enjoyMonoStyle(context, size: 13, color: t.ink2),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: clamped / 100,
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word, required this.score, this.errorType});

  final String word;
  final double score;
  final String? errorType;

  bool get _mispronounced =>
      errorType != null && errorType != 'None' && errorType != 'Omission';

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final text = Text(
      word,
      style: tt.bodyMedium?.copyWith(
        color: _mispronounced ? t.ink : t.ink2,
        decoration: _mispronounced ? TextDecoration.underline : null,
        decorationStyle: TextDecorationStyle.wavy,
        decorationColor: t.you,
        decorationThickness: 1.5,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: text),
          Text(
            score.round().toString(),
            style: enjoyMonoStyle(context, size: 12.5, color: t.ink3),
          ),
        ],
      ),
    );
  }
}
