import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_pitch_contour_tile.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_record_fab.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_reading_toolbar_row.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_takes_toolbar_actions.dart';
import 'package:enjoy_player/features/share_poster/presentation/share_practice_poster_button.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Vocabulary-embed idle layout: toolbar row (share, takes actions, record
/// FAB) over the expandable pitch tile, shown when no capture is running.
class ShadowIdlePanelColumn extends ConsumerWidget {
  const ShadowIdlePanelColumn({
    required this.mediaId,
    required this.echoActive,
    required this.mediaPath,
    required this.startSec,
    required this.endSec,
    required this.showLiveProgress,
    required this.pitchExpanded,
    required this.takes,
    required this.selected,
    required this.onToggleRecord,
    required this.onPlayOrPause,
    required this.onDeleteTake,
    required this.onChooseTake,
    required this.onTogglePitch,
    super.key,
  });

  final String mediaId;
  final bool echoActive;
  final String? mediaPath;
  final double startSec;
  final double endSec;
  final bool showLiveProgress;
  final bool pitchExpanded;
  final List<RecordingRow> takes;
  final RecordingRow? selected;
  final VoidCallback onToggleRecord;
  final void Function(String path) onPlayOrPause;
  final void Function(RecordingRow row) onDeleteTake;
  final Future<void> Function(String id) onChooseTake;
  final VoidCallback onTogglePitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    final toggleRecordingTooltip = hotkeyTooltipLabel(
      ref,
      'player.toggleRecording',
      l10n.shadowRecordingRecord,
    );
    final pitchContourTooltip = hotkeyTooltipLabel(
      ref,
      'player.togglePitchContour',
      l10n.pitchContourTitle,
    );
    final sel = selected;
    final hasMedia = mediaPath != null && mediaPath!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadowReadingToolbarRow(
          tok: tok,
          scheme: scheme,
          pitchExpanded: pitchExpanded,
          pitchTooltip: pitchContourTooltip,
          hasMediaPath: hasMedia,
          onPitchTap: onTogglePitch,
          leadingShare: SharePracticePosterButton(
            mediaId: mediaId,
            iconColor: scheme.onSurface,
          ),
          takesActions: takes.isNotEmpty && sel != null
              ? ShadowTakesToolbarActions(
                  row: sel,
                  list: takes,
                  echoActive: echoActive,
                  scheme: scheme,
                  tok: tok,
                  l10n: l10n,
                  onPlayOrPause: () {
                    final path = sel.localPath;
                    if (path != null && path.isNotEmpty) {
                      onPlayOrPause(path);
                    }
                  },
                  onDeleteCurrent: () => onDeleteTake(sel),
                  onChooseTake: onChooseTake,
                )
              : null,
          recordFab: Tooltip(
            message: '$toggleRecordingTooltip\n${l10n.shadowReadingHint}',
            child: ShadowRecordFab(
              recording: false,
              echoActive: echoActive,
              ringProgress: 0,
              overTarget: false,
              overPulseHigh: false,
              showProgressArc: false,
              onTap: onToggleRecord,
              scheme: scheme,
              tok: tok,
            ),
          ),
        ),
        if (hasMedia) ...[
          if (pitchExpanded) SizedBox(height: tok.space8),
          ShadowPitchContourTile(
            mediaPath: mediaPath,
            startSec: startSec,
            endSec: endSec,
            showLiveProgress: showLiveProgress,
            expanded: pitchExpanded,
            selectedRecordingPath: sel?.localPath,
            selectedRecordingDurationMs: sel?.duration,
            onToggleExpanded: onTogglePitch,
          ),
        ],
      ],
    );
  }
}
