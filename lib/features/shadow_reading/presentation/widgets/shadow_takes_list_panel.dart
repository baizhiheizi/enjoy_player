/// The full list of the loop's takes (canvas v30, D6.3): the player margin
/// on desktop, a bottom sheet on phones. Play, score or open the assessment,
/// delete (decision R2), and the pitch contour toggle.
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
import 'package:enjoy_player/features/player/presentation/widgets/player_margin.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_assessment_controller.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_takes_ui_state.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_button.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'shadow_take_bits.dart';
import 'shadow_takes_toolbar_actions.dart';

class ShadowTakesListPanel extends ConsumerWidget {
  const ShadowTakesListPanel({
    required this.query,
    required this.onClose,
    required this.onPlayOrPause,
    required this.onDelete,
    this.showPitchToggle = true,
    super.key,
  });

  final EchoRegionRecordingsQuery query;
  final VoidCallback onClose;
  final void Function(RecordingRow row) onPlayOrPause;
  final Future<void> Function(RecordingRow row) onDelete;
  final bool showPitchToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedId = ref.watch(selectedTakeProvider);
    final pitchOn = ref.watch(loopPitchVisibleProvider);

    return Column(
      key: const ValueKey('takes-list-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerMarginHeader(
          title: isMobilePlatform
              ? l10n.takesMarginTitleTap
              : l10n.takesMarginTitleClick,
          youVoice: true,
          onClose: onClose,
        ),
        Flexible(
          child: StreamBuilder<List<RecordingRow>>(
            stream: ref.watch(echoRegionRecordingsProvider(query)),
            builder: (context, snap) {
              final takes = snap.data ?? const <RecordingRow>[];
              final selected = resolveSelectedTake(takes, selectedId);
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                children: [
                  for (final row in takes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _TakeListRow(
                        row: row,
                        number: takeNumberOf(takes, row),
                        selected: row.id == selected?.id,
                        onPlay: () {
                          ref
                              .read(selectedTakeProvider.notifier)
                              .select(row.id);
                          onPlayOrPause(row);
                        },
                        onDelete: () => onDelete(row),
                      ),
                    ),
                  if (showPitchToggle) ...[
                    const SizedBox(height: 12),
                    _PitchToggle(
                      on: pitchOn,
                      onTap: () =>
                          ref.read(loopPitchVisibleProvider.notifier).toggle(),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        SizedBox(height: t.space4),
      ],
    );
  }
}

class _TakeListRow extends ConsumerWidget {
  const _TakeListRow({
    required this.row,
    required this.number,
    required this.selected,
    required this.onPlay,
    required this.onDelete,
  });

  final RecordingRow row;
  final int number;
  final bool selected;
  final VoidCallback onPlay;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final score = pronunciationScoreFromRecording(row);
    final scoring = ref
        .watch(recordingAssessmentControllerProvider(row.id))
        .isRunning;
    final canScore = takeCanBeScored(ref, row);
    final duration = '${(row.duration / 1000).toStringAsFixed(1)} s';

    void assess() => unawaited(
      triggerRecordingAssessment(
        context: context,
        ref: ref,
        l10n: l10n,
        row: row,
        marginWhenWide: true,
      ),
    );

    final Widget trailing;
    if (scoring) {
      trailing = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          l10n.assessmentScoring,
          style: tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink3),
        ),
      );
    } else if (score != null) {
      trailing = Tooltip(
        message: l10n.assessmentView,
        child: EnjoyPressable(
          key: ValueKey('take-score-${row.id}'),
          onTap: canScore ? assess : null,
          borderRadius: BorderRadius.circular(8),
          pressedScale: 0.96,
          child: Container(
            height: 28,
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.sunk,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '${score.round()}',
              style: enjoyMonoStyle(
                context,
                size: 13,
                weight: FontWeight.w600,
                color: t.ink,
              ),
            ),
          ),
        ),
      );
    } else if (canScore) {
      trailing = Tooltip(
        message: l10n.assessmentRun,
        child: EnjoyPressable(
          key: ValueKey('take-run-score-${row.id}'),
          onTap: assess,
          borderRadius: BorderRadius.circular(8),
          pressedScale: 0.96,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.sunk,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.assessmentScoreAction,
              style: tt.labelMedium?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.ink2,
              ),
            ),
          ),
        ),
      );
    } else {
      trailing = const SizedBox.shrink();
    }

    return Container(
      key: ValueKey('take-row-${row.id}'),
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
      decoration: ShapeDecoration(
        color: selected ? t.youSoft : Colors.transparent,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? t.youLine : Colors.transparent),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: EnjoyPressable(
              key: ValueKey('take-play-${row.id}'),
              onTap: takeIsPlayable(row) ? onPlay : null,
              borderRadius: BorderRadius.circular(10),
              pressedScale: 1,
              semanticsLabel: l10n.takeNumbered(number),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selected ? t.you : t.sunk,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: TakePlayGlyph(
                          row: row,
                          color: selected ? t.onYou : t.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        l10n.takeNumbered(number),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelLarge?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        duration,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: enjoyMonoStyle(context, size: 12, color: t.ink3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          trailing,
          IconButton(
            key: ValueKey('take-delete-${row.id}'),
            tooltip: l10n.shadowRecordingDelete,
            iconSize: 16,
            color: t.ink3,
            icon: const Icon(EnjoyIcons.delete),
            onPressed: () => confirmShadowDeleteTake(
              context: context,
              scheme: Theme.of(context).colorScheme,
              l10n: l10n,
              takeSummary: '${l10n.takeNumbered(number)} · $duration',
              onConfirmed: () => unawaited(onDelete()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchToggle extends StatelessWidget {
  const _PitchToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fg = on ? t.youInk : t.ink2;
    return EnjoyPressable(
      key: const ValueKey('takes-pitch-toggle'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      pressedScale: 0.99,
      selected: on,
      semanticsLabel: l10n.takesPitchOnLoop,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: ShapeDecoration(
          color: on ? t.youSoft : Colors.transparent,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: t.line),
          ),
        ),
        child: Row(
          children: [
            Icon(EnjoyIcons.waveform, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.takesPitchOnLoop,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (!isMobilePlatform) const EnjoyKeycap(label: 'P'),
          ],
        ),
      ),
    );
  }
}
