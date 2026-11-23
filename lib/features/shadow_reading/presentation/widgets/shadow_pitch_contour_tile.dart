import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/player/application/display_position_provider.dart';
import 'package:enjoy_player/features/shadow_reading/presentation/pitch_contour_section.dart';

/// Shadow-reading pitch tile: [PitchContourSection] with the live
/// player-progress marker, shared by the panel's player-embed and
/// vocabulary-embed branches so the contour is defined exactly once.
class ShadowPitchContourTile extends ConsumerStatefulWidget {
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
  ConsumerState<ShadowPitchContourTile> createState() =>
      _ShadowPitchContourTileState();
}

class _ShadowPitchContourTileState
    extends ConsumerState<ShadowPitchContourTile> {
  final ValueNotifier<double?> _relativeSec = ValueNotifier<double?>(null);

  double? _computeRelative(Duration pos) {
    if (!widget.showLiveProgress || !widget.expanded) return null;
    final posSec = pos.inMilliseconds / 1000.0;
    return (posSec - widget.startSec).clamp(
      0.0,
      widget.endSec - widget.startSec,
    );
  }

  @override
  void didUpdateWidget(covariant ShadowPitchContourTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showLiveProgress != widget.showLiveProgress ||
        oldWidget.expanded != widget.expanded ||
        oldWidget.startSec != widget.startSec ||
        oldWidget.endSec != widget.endSec) {
      if (!widget.showLiveProgress || !widget.expanded) {
        _relativeSec.value = null;
      } else {
        final pos =
            ref.read(displayPositionProvider).valueOrNull ?? Duration.zero;
        _relativeSec.value = _computeRelative(pos);
      }
    }
  }

  @override
  void dispose() {
    _relativeSec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.mediaPath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }
    if (widget.showLiveProgress && widget.expanded) {
      _relativeSec.value ??= _computeRelative(
        ref.read(displayPositionProvider).valueOrNull ?? Duration.zero,
      );
      ref.listen<AsyncValue<Duration>>(displayPositionProvider, (_, next) {
        _relativeSec.value = _computeRelative(
          next.valueOrNull ?? Duration.zero,
        );
      });
    } else {
      _relativeSec.value = null;
    }
    final section = PitchContourSection(
      mediaPath: path,
      startSec: widget.startSec,
      endSec: widget.endSec,
      currentTimeRelativeSecListenable: _relativeSec,
      selectedRecordingPath: widget.selectedRecordingPath,
      selectedRecordingDurationMs: widget.selectedRecordingDurationMs,
      expanded: widget.expanded,
      onToggleExpanded: widget.onToggleExpanded,
      showHeader: false,
    );
    final inset = widget.leftInset;
    if (inset == null) return section;
    return Padding(
      padding: EdgeInsets.only(left: inset),
      child: section,
    );
  }
}
