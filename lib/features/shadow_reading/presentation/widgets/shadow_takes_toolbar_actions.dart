import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/audio/recording_preview_player_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_button.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/recording_assessment_flow.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/score_level.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// `PopupMenuButton` value tokens for the takes menu — kept library-private.
const kShadowDeleteTakeToken = '__shadow_delete_current_take__';
const kShadowReassessTakeToken = '__shadow_reassess_current_take__';

/// Shared alert-dialog helper confirming deletion of the current take.
Future<void> confirmShadowDeleteTake({
  required BuildContext context,
  required ColorScheme scheme,
  required AppLocalizations l10n,
  required String takeSummary,
  required VoidCallback onConfirmed,
}) async {
  if (!context.mounted) return;
  final cancelLabel = MaterialLocalizations.of(context).cancelButtonLabel;
  final confirmed = await showEnjoyAlertDialog<bool>(
    context: context,
    title: Text(l10n.shadowRecordingDeleteConfirmTitle),
    content: Text(l10n.shadowRecordingDeleteConfirmMessage(takeSummary)),
    actionsBuilder: (ctx) => [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(false),
        child: Text(cancelLabel),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onError,
          backgroundColor: scheme.error,
        ),
        onPressed: () => Navigator.of(ctx).pop(true),
        child: Text(l10n.shadowRecordingDelete),
      ),
    ],
  );
  if (confirmed == true && context.mounted) {
    onConfirmed();
  }
}

/// Takes toolbar: play/pause + assess + popup menu (take list, reassess,
/// delete). Extracted from `shadow_reading_panel.dart` — see issue #180.
class ShadowTakesToolbarActions extends ConsumerWidget {
  const ShadowTakesToolbarActions({
    required this.row,
    required this.list,
    required this.echoActive,
    required this.scheme,
    required this.tok,
    required this.l10n,
    required this.onPlayOrPause,
    required this.onDeleteCurrent,
    required this.onChooseTake,
    super.key,
  });

  final RecordingRow row;
  final List<RecordingRow> list;
  final bool echoActive;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;
  final AppLocalizations l10n;
  final VoidCallback onPlayOrPause;
  final VoidCallback onDeleteCurrent;
  final Future<void> Function(String id) onChooseTake;

  int _takeNumber(RecordingRow r) {
    final i = list.indexWhere((e) => e.id == r.id);
    if (i < 0) return list.length;
    return list.length - i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(recordingPreviewPlayerProvider);
    final lp = row.localPath;
    final canPlay = echoActive && lp != null && lp.isNotEmpty;

    final takeSummary =
        '${l10n.shadowRecordingTake} ${_takeNumber(row)} · '
        '${(row.duration / 1000).toStringAsFixed(1)} s';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        lp != null && lp.isNotEmpty
            ? StreamBuilder<bool>(
                stream: preview.playing,
                initialData: false,
                builder: (context, playSnap) {
                  final abs = File(lp).absolute.path;
                  final playingThis =
                      (playSnap.data ?? false) && preview.loadedPath == abs;
                  return IconButton(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(44, 44),
                    ),
                    tooltip: takeSummary,
                    icon: Icon(
                      playingThis
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: canPlay ? onPlayOrPause : null,
                  );
                },
              )
            : IconButton(
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(44, 44),
                ),
                tooltip: takeSummary,
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: null,
              ),
        RecordingAssessmentButton(row: row, echoActive: echoActive),
        PopupMenuButton<String>(
          tooltip: l10n.shadowRecordingChooseTake,
          onSelected: (value) {
            if (!echoActive) return;
            if (value == kShadowDeleteTakeToken) {
              unawaited(
                confirmShadowDeleteTake(
                  context: context,
                  scheme: scheme,
                  l10n: l10n,
                  takeSummary: takeSummary,
                  onConfirmed: onDeleteCurrent,
                ),
              );
              return;
            }
            if (value == kShadowReassessTakeToken) {
              unawaited(
                triggerRecordingAssessment(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  row: row,
                  forceRun: true,
                ),
              );
              return;
            }
            unawaited(onChooseTake(value));
          },
          itemBuilder: (context) {
            return [
              for (var i = 0; i < list.length; i++)
                PopupMenuItem<String>(
                  value: list[i].id,
                  child: Builder(
                    builder: (ctx) {
                      final r = list[i];
                      final score = pronunciationScoreFromRecording(r);
                      return Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: r.id == row.id
                                ? Icon(
                                    Icons.check,
                                    size: 20,
                                    color: scheme.primary,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Expanded(
                            child: Text(
                              '${l10n.shadowRecordingTake} ${list.length - i} · '
                              '${(r.duration / 1000).toStringAsFixed(1)} s',
                            ),
                          ),
                          if (score != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: assessmentScoreBackground(
                                    scheme,
                                    assessmentScoreLevel(score),
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '$score',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: assessmentScoreColor(
                                        scheme,
                                        assessmentScoreLevel(score),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              PopupMenuItem<String>(
                value: kShadowReassessTakeToken,
                enabled:
                    echoActive &&
                    row.assessmentJson != null &&
                    row.assessmentJson!.trim().isNotEmpty,
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    Expanded(child: Text(l10n.assessmentReassess)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: kShadowDeleteTakeToken,
                enabled: echoActive,
                child: Builder(
                  builder: (ctx) {
                    final baseStyle = DefaultTextStyle.of(ctx).style;
                    final color = echoActive
                        ? scheme.error
                        : scheme.onSurface.withValues(alpha: 0.38);
                    return Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.shadowRecordingDelete,
                            style: baseStyle.copyWith(color: color),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ];
          },
          child: Padding(
            padding: EdgeInsets.all(tok.space4),
            child: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
