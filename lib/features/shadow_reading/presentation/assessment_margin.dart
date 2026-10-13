/// D3.8 (ADR-0093): pronunciation assessment in the player's side margin —
/// a `marginWidth` raised panel sliding from the right edge, replacing the centered
/// dialog on wide player windows. It hosts the same [AssessmentResultBody]
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
import 'package:enjoy_player/features/shadow_reading/presentation/assessment_result_body.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Opens [assessment] in the side margin (wide player windows).
Future<void> showAssessmentMargin({
  required BuildContext context,
  required AzurePronunciationAssessmentResult assessment,
  String? localeTag,
  String? recordingPath,
}) {
  final route = _AssessmentMarginRoute(
    assessment: assessment,
    localeTag: localeTag ?? kDefaultLearningLanguageTag,
    recordingPath: recordingPath,
  );
  return Navigator.of(context, rootNavigator: true).push(route);
}

class _AssessmentMarginRoute extends PopupRoute<void> {
  _AssessmentMarginRoute({
    required this.assessment,
    required this.localeTag,
    this.recordingPath,
  });

  final AzurePronunciationAssessmentResult assessment;
  final String localeTag;
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
            child: Material(
              type: MaterialType.transparency,
              child: AssessmentMarginPanel(
                assessment: assessment,
                localeTag: localeTag,
                recordingPath: recordingPath,
                onClose: () => Navigator.of(context).maybePop(),
              ),
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
    final nBest = assessment.nBest.isEmpty ? null : assessment.nBest.first;
    return _MarginFrame(
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
