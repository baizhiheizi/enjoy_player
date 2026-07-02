import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

import 'shadow_record_fab.dart';

/// Idle shadow-reading toolbar: pitch toggle (left) · record FAB (center) ·
/// takes actions slot (right). The FAB is overlaid on a Row whose middle
/// reserves [ShadowRecordFab.ringOuterHitSize] so pitch/takes hug the center
/// without shifting the mic off true horizontal center.
///
/// Extracted from `shadow_reading_panel.dart` — see issue #180.
class ShadowReadingToolbarRow extends StatelessWidget {
  const ShadowReadingToolbarRow({
    required this.tok,
    required this.scheme,
    required this.pitchExpanded,
    required this.pitchTooltip,
    required this.hasMediaPath,
    required this.onPitchTap,
    required this.takesActions,
    required this.recordFab,
    super.key,
  });

  final EnjoyThemeTokens tok;
  final ColorScheme scheme;
  final bool pitchExpanded;
  final String pitchTooltip;
  final bool hasMediaPath;
  final VoidCallback onPitchTap;
  final Widget? takesActions;
  final Widget recordFab;

  @override
  Widget build(BuildContext context) {
    final pitchIcon = Icon(
      Icons.show_chart_rounded,
      size: 22,
      color: hasMediaPath
          ? null
          : scheme.onSurfaceVariant.withValues(alpha: 0.38),
    );

    final Widget pitchControl = Tooltip(
      message: pitchTooltip,
      child: hasMediaPath
          ? pitchExpanded
                ? IconButton.filledTonal(
                    onPressed: onPitchTap,
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: pitchIcon,
                  )
                : IconButton(
                    onPressed: onPitchTap,
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(44, 44),
                    ),
                    icon: pitchIcon,
                  )
          : IconButton(
              onPressed: null,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(44, 44),
              ),
              icon: pitchIcon,
            ),
    );

    // FAB stays at true horizontal center: overlay it on a Row whose middle
    // reserves ring width so pitch/takes hug the center without shifting the
    // mic.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: tok.space12),
                  child: pitchControl,
                ),
              ),
            ),
            const SizedBox(width: ShadowRecordFab.ringOuterHitSize),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: tok.space12),
                  child: takesActions ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
        recordFab,
      ],
    );
  }
}
