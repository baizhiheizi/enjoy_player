/// Collapsible card section and its selected-track summary used by both the
/// primary and translation track lists in the subtitle picker.
library;

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'subtitle_track_picker_helpers.dart';
import 'subtitle_track_picker_primitives.dart';

/// A track row (label over the selected track, chevron at the end) that
/// opens its option list in place.
class CollapsibleTrackSection extends StatelessWidget {
  const CollapsibleTrackSection({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.selectionLabel,
    this.selectedTrack,
    required this.child,
    this.inlineExpandedList = false,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String selectionLabel;
  final TranscriptTrack? selectedTrack;
  final Widget child;
  final bool inlineExpandedList;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnjoyPressable(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          pressedScale: 1,
          washColor: t.sunk,
          selected: isExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: t.ink3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SelectionSummary(
                        label: selectionLabel,
                        track: selectedTrack,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: t.motionFast,
                  curve: Curves.easeOut,
                  child: Icon(EnjoyIcons.chevronRight, size: 16, color: t.ink3),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: t.motionStandard,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: inlineExpandedList
                      ? child
                      : ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: kExpandedTrackListMaxHeight,
                          ),
                          child: SingleChildScrollView(child: child),
                        ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class SelectionSummary extends StatelessWidget {
  const SelectionSummary({
    super.key,
    required this.label,
    this.track,
    this.compact = false,
  });

  final String label;
  final TranscriptTrack? track;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final muted = track == null;
    final selected = track;
    final badgeColors = selected == null
        ? null
        : providerBadgeColors(cs, selected.source);

    if (compact && selected != null && badgeColors != null) {
      return Row(
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: t.ink,
              ),
            ),
          ),
          SizedBox(width: t.space8),
          MetaChip(
            label: providerLabel(l10n, selected.source),
            background: badgeColors.bg,
            foreground: badgeColors.fg,
          ),
          if (selected.language.isNotEmpty && selected.language != 'und') ...[
            SizedBox(width: t.space8),
            MetaChip(
              label: selected.language.toUpperCase(),
              background: cs.surfaceContainerHighest,
              foreground: cs.onSurfaceVariant,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            fontSize: 14,
            color: muted ? t.ink2 : t.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (selected != null && badgeColors != null) ...[
          SizedBox(height: t.space8),
          Wrap(
            spacing: t.space8,
            runSpacing: t.space4,
            children: [
              MetaChip(
                label: providerLabel(l10n, selected.source),
                background: badgeColors.bg,
                foreground: badgeColors.fg,
              ),
              if (selected.language.isNotEmpty && selected.language != 'und')
                MetaChip(
                  label: selected.language.toUpperCase(),
                  background: cs.surfaceContainerHighest,
                  foreground: cs.onSurfaceVariant,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
