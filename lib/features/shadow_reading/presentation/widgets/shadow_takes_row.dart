/// Takes strip under the echo loop: one chip per take plus the Pitch pill.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_assessment_controller.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_button.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ShadowTakesRow extends ConsumerWidget {
  const ShadowTakesRow({
    required this.takes,
    required this.selectedId,
    required this.echoActive,
    required this.pitchExpanded,
    required this.hasMediaPath,
    required this.onPlayOrPause,
    required this.onChooseTake,
    required this.onTogglePitch,
    super.key,
  });

  final List<RecordingRow> takes;
  final String? selectedId;
  final bool echoActive;

  /// Whether the pitch contour below the row is expanded.
  final bool pitchExpanded;

  /// Pitch needs the reference audio to compute the contour.
  final bool hasMediaPath;

  final void Function(RecordingRow row) onPlayOrPause;
  final void Function(RecordingRow row) onChooseTake;
  final VoidCallback onTogglePitch;

  int _takeNumber(RecordingRow row) {
    final i = takes.indexWhere((e) => e.id == row.id);
    if (i < 0) return takes.length;
    return takes.length - i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final learningLanguage = ref
        .watch(appPreferencesCtrlProvider)
        .valueOrNull
        ?.effectiveLearningLanguage;

    final chips = [
      for (final row in takes)
        _TakeChip(
          key: ValueKey('shadow-take-${row.id}'),
          row: row,
          takeNumber: _takeNumber(row),
          selected: row.id == selectedId,
          echoActive: echoActive,
          learningLanguage: learningLanguage,
          onPlayOrPause: () => onPlayOrPause(row),
          onChoose: () => onChooseTake(row),
        ),
    ];

    final pitchTooltip = hotkeyTooltipLabel(
      ref,
      'player.togglePitchContour',
      l10n.pitchContourTitle,
    );
    final pitchEnabled = takes.isNotEmpty && hasMediaPath && echoActive;
    final pitchPill = Tooltip(
      message: pitchTooltip,
      child: Opacity(
        opacity: pitchEnabled ? 1 : 0.38,
        child: IgnorePointer(
          ignoring: !pitchEnabled,
          child: EnjoyPressable(
            onTap: onTogglePitch,
            borderRadius: BorderRadius.circular(tok.radiusControl),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: ShapeDecoration(
                color: pitchExpanded ? tok.sunk : Colors.transparent,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(tok.radiusControl),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(EnjoyIcons.waveform, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.pitchContourTitle,
                    style: tt.labelMedium?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: pitchExpanded ? tok.ink : tok.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (takes.isEmpty) {
      return Row(
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                text: l10n.shadowTakesEmptyPrefix,
                style: tt.bodyMedium?.copyWith(fontSize: 13.5, color: tok.ink3),
                children: [
                  const WidgetSpan(child: SizedBox(width: 6)),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: EnjoyKeycap(label: 'R'),
                  ),
                  const WidgetSpan(child: SizedBox(width: 6)),
                  TextSpan(text: l10n.shadowTakesEmptySuffix),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          pitchPill,
        ],
      );
    }

    final overlineStyle = tt.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.08,
      color: tok.ink3,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(l10n.shadowTakesLabel.toUpperCase(), style: overlineStyle),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, chip) in chips.indexed)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: chip,
                  ),
              ],
            ),
          ),
        ),
        pitchPill,
      ],
    );
  }
}

class _TakeChip extends ConsumerWidget {
  const _TakeChip({
    required this.row,
    required this.takeNumber,
    required this.selected,
    required this.echoActive,
    required this.learningLanguage,
    required this.onPlayOrPause,
    required this.onChoose,
    super.key,
  });

  final RecordingRow row;
  final int takeNumber;
  final bool selected;
  final bool echoActive;
  final String? learningLanguage;
  final VoidCallback onPlayOrPause;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final preview = ref.watch(recordingPreviewPlayerProvider);
    final lp = row.localPath;
    final canPlay = echoActive && lp != null && lp.isNotEmpty;
    final assessmentSupported =
        isAzurePronunciationAssessmentSupportedForPractice(
          row.language,
          learningLanguage: learningLanguage,
        );
    final canScore = echoActive && canPlay && assessmentSupported;
    final assessing = ref
        .watch(recordingAssessmentControllerProvider(row.id))
        .isRunning;
    final score = pronunciationScoreFromRecording(row);
    final duration = (row.duration / 1000).toStringAsFixed(1);

    final playCircle = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? tok.you : tok.sunk,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: StreamBuilder<bool>(
          stream: preview.playing,
          initialData: false,
          builder: (context, snap) {
            final playingThis =
                (snap.data ?? false) &&
                lp != null &&
                lp.isNotEmpty &&
                preview.loadedPath == File(lp).absolute.path;
            return Icon(
              playingThis ? EnjoyIcons.pause : EnjoyIcons.play,
              size: 12,
              color: selected ? tok.onYou : tok.ink2,
            );
          },
        ),
      ),
    );

    return Container(
      height: 42,
      padding: const EdgeInsets.only(right: 5),
      decoration: ShapeDecoration(
        color: selected ? tok.youSoft : tok.paper,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? tok.youLine : tok.line),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '${l10n.shadowRecordingTake} $takeNumber · $duration s',
            child: EnjoyPressable(
              onTap: canPlay
                  ? () {
                      onChoose();
                      onPlayOrPause();
                    }
                  : null,
              borderRadius: BorderRadius.circular(tok.radiusFull),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    playCircle,
                    const SizedBox(width: 9),
                    Text(
                      '${l10n.shadowRecordingTake} $takeNumber',
                      style: tt.labelMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: tok.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$duration s',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tok.ink3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (assessing)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                l10n.assessmentScoring,
                style: tt.labelSmall?.copyWith(fontSize: 12.5, color: tok.ink3),
              ),
            )
          else if (score != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: l10n.assessmentView,
                child: EnjoyPressable(
                  onTap: canScore
                      ? () => unawaited(
                          triggerRecordingAssessment(
                            context: context,
                            ref: ref,
                            l10n: l10n,
                            row: row,
                          ),
                        )
                      : null,
                  borderRadius: BorderRadius.circular(tok.radiusFull),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: tok.paper,
                      shape: StadiumBorder(side: BorderSide(color: tok.line)),
                    ),
                    child: Text(
                      '$score',
                      style: tt.labelMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tok.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (canScore)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: hotkeyTooltipLabel(
                  ref,
                  'player.toggleAssessment',
                  l10n.assessmentRun,
                ),
                child: EnjoyPressable(
                  onTap: () => unawaited(
                    triggerRecordingAssessment(
                      context: context,
                      ref: ref,
                      l10n: l10n,
                      row: row,
                      forceRun: true,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(tok.radiusFull),
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(EnjoyIcons.sparkleFill, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          l10n.assessmentScoreAction,
                          style: tt.labelSmall?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: tok.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
