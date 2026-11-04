import 'package:flutter/material.dart';

import 'package:enjoy_player/core/transcript/transcript_lens_metrics.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_pitch_contour_tile.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/widgets/shadow_take_summary_row.dart';

/// Player-embed takes strip (`takesRowInLoop`): the chip summary row and the
/// pitch tile sit under the echo loop, inset by the transcript gutter.
class ShadowTakesInLoopRow extends StatelessWidget {
  const ShadowTakesInLoopRow({
    required this.takes,
    required this.selected,
    required this.mediaPath,
    required this.startSec,
    required this.endSec,
    required this.showLiveProgress,
    required this.pitchExpanded,
    required this.onPlayOrPause,
    required this.onOpenList,
    required this.onTogglePitch,
    super.key,
  });

  final List<RecordingRow> takes;
  final RecordingRow? selected;
  final String? mediaPath;
  final double startSec;
  final double endSec;
  final bool showLiveProgress;
  final bool pitchExpanded;
  final void Function(RecordingRow row) onPlayOrPause;
  final VoidCallback onOpenList;
  final VoidCallback onTogglePitch;

  @override
  Widget build(BuildContext context) {
    final takesInset = TranscriptLensMetrics.of(context).takesLeftInset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: takesInset),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ShadowTakeSummaryRow(
              takes: takes,
              selected: selected,
              onPlayOrPause: onPlayOrPause,
              onOpenList: onOpenList,
            ),
          ),
        ),
        ShadowPitchContourTile(
          mediaPath: mediaPath,
          startSec: startSec,
          endSec: endSec,
          showLiveProgress: showLiveProgress,
          expanded: pitchExpanded,
          selectedRecordingPath: selected?.localPath,
          selectedRecordingDurationMs: selected?.duration,
          onToggleExpanded: onTogglePitch,
          leftInset: takesInset,
        ),
      ],
    );
  }
}
