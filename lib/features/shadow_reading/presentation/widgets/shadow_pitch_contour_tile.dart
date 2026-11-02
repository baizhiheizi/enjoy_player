import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/pitch_contour_section.dart';

/// Shadow-reading pitch tile: [PitchContourSection] with the live
/// player-progress marker, shared by the panel's player-embed and
/// vocabulary-embed branches so the contour is defined exactly once.
class ShadowPitchContourTile extends ConsumerWidget {
  const ShadowPitchContourTile({
    required this.mediaPath,
    required this.startSec,
    required this.endSec,
    required this.showLiveProgress,
    required this.expanded,
    required this.selectedRecordingPath,
    required this.selectedRecordingDurationMs,
    required this.onToggleExpanded,
    this.leftInset,
    super.key,
  });

  final String? mediaPath;
  final double startSec;
  final double endSec;

  /// Whether the contour tracks the live player position; without an open
  /// player (vocabulary embed) it renders without a progress marker.
  final bool showLiveProgress;
  final bool expanded;
  final String? selectedRecordingPath;
  final int? selectedRecordingDurationMs;
  final VoidCallback? onToggleExpanded;

  /// Player-transcript gutter inset; null renders the section unpadded.
  final double? leftInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = mediaPath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }
    double? relativeSec;
    if (showLiveProgress && expanded) {
      final posSec =
          (ref.watch(displayPositionProvider).valueOrNull ?? Duration.zero)
              .inMilliseconds /
          1000.0;
      relativeSec = (posSec - startSec).clamp(0.0, endSec - startSec);
    }
    final section = PitchContourSection(
      mediaPath: path,
      startSec: startSec,
      endSec: endSec,
      currentTimeRelativeSec: relativeSec,
      selectedRecordingPath: selectedRecordingPath,
      selectedRecordingDurationMs: selectedRecordingDurationMs,
      expanded: expanded,
      onToggleExpanded: onToggleExpanded,
      showHeader: false,
    );
    final inset = leftInset;
    if (inset == null) return section;
    return Padding(
      padding: EdgeInsets.only(left: inset),
      child: section,
    );
  }
}
