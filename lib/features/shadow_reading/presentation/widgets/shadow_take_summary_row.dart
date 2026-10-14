/// The one takes row under the Echo loop (canvas v30, D6.3): play the
/// selected take, its name and score or “Not scored yet”, and “3 takes ›”
/// to open the list.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_assessment_controller.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_button.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/score_level.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'shadow_take_bits.dart';

const double _kSummaryMaxWidth = 520;

class ShadowTakeSummaryRow extends ConsumerWidget {
  const ShadowTakeSummaryRow({
    required this.takes,
    required this.selected,
    required this.onPlayOrPause,
    required this.onOpenList,
    super.key,
  });

  /// Newest first.
  final List<RecordingRow> takes;
  final RecordingRow? selected;
  final void Function(RecordingRow row) onPlayOrPause;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final row = selected;

    if (row == null && isMobilePlatform) {
      return Text(
        l10n.shadowRecordingEmpty,
        key: const ValueKey('takes-summary-empty'),
        style: tt.bodyMedium?.copyWith(fontSize: 13.5, color: t.ink3),
      );
    }
    if (row == null) {
      return Wrap(
        key: const ValueKey('takes-summary-empty'),
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            l10n.shadowTakesEmptyPrefix,
            style: tt.bodyMedium?.copyWith(fontSize: 13.5, color: t.ink3),
          ),
          const EnjoyKeycap(label: 'R'),
          Text(
            l10n.shadowTakesEmptySuffix,
            style: tt.bodyMedium?.copyWith(fontSize: 13.5, color: t.ink3),
          ),
        ],
      );
    }

    final number = takeNumberOf(takes, row);
    final score = pronunciationScoreFromRecording(row);
    final scoring = ref
        .watch(recordingAssessmentControllerProvider(row.id))
        .isRunning;
    final canScore = takeCanBeScored(ref, row);
    final note = scoring
        ? l10n.assessmentScoring
        : score != null
        ? assessmentScoreLevelLabel(l10n, assessmentScoreLevel(score))
        : canScore
        ? (isMobilePlatform ? l10n.takeNotScoredTap : l10n.takeNotScoredClick)
        : '';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kSummaryMaxWidth),
      child: Container(
        key: const ValueKey('takes-summary'),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: ShapeDecoration(
          color: t.paper,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.line),
          ),
        ),
        child: Row(
          children: [
            Tooltip(
              message: l10n.shadowRecordingPlay,
              child: EnjoyPressable(
                key: const ValueKey('takes-summary-play'),
                onTap: takeIsPlayable(row) ? () => onPlayOrPause(row) : null,
                shape: const CircleBorder(),
                pressedScale: 0.94,
                semanticsLabel: l10n.takeNumbered(number),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: t.you,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TakePlayGlyph(row: row, color: t.onYou),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EnjoyPressable(
                key: const ValueKey('takes-summary-score'),
                onTap: canScore && !scoring
                    ? () => unawaited(
                        triggerRecordingAssessment(
                          context: context,
                          ref: ref,
                          l10n: l10n,
                          row: row,
                          marginWhenWide: true,
                        ),
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
                pressedScale: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: l10n.takeNumbered(number),
                        children: [
                          if (score != null)
                            TextSpan(
                              text: ' · ${score.round()}',
                              style: enjoyMonoStyle(
                                context,
                                size: 14,
                                weight: FontWeight.w600,
                                color: t.ink,
                              ),
                            ),
                        ],
                      ),
                      style: tt.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: t.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            EnjoyPressable(
              key: const ValueKey('takes-summary-open-list'),
              onTap: onOpenList,
              borderRadius: BorderRadius.circular(10),
              washColor: t.sunk,
              semanticsLabel: l10n.takesCount(takes.length),
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.takesCount(takes.length),
                        style: tt.labelMedium?.copyWith(
                          fontSize: 13,
                          color: t.ink2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(EnjoyIcons.chevronRight, size: 14, color: t.ink2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
