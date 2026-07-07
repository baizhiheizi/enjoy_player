/// Radio-style selectable rows used inside the subtitle track lists.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'subtitle_track_picker_helpers.dart';
import 'subtitle_track_picker_primitives.dart';

class TrackOptionTile<T> extends StatelessWidget {
  const TrackOptionTile({
    super.key,
    required this.value,
    required this.selected,
    required this.track,
    required this.padding,
    required this.onDelete,
  });

  final T value;
  final bool selected;
  final TranscriptTrack track;
  final EdgeInsetsGeometry padding;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = trackLabel(track);
    final badgeColors = providerBadgeColors(cs, track.source);

    return Padding(
      padding: padding,
      child: Material(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.34)
            : cs.surfaceContainerHighest.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
          side: BorderSide(
            color: selected
                ? cs.primary.withValues(alpha: 0.42)
                : cs.outlineVariant.withValues(alpha: 0.14),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<T>(
          value: value,
          selected: selected,
          contentPadding: EdgeInsets.fromLTRB(
            t.space8,
            t.space8,
            t.space4,
            t.space8,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            label,
            style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: t.space8),
            child: Wrap(
              spacing: t.space8,
              runSpacing: t.space4,
              children: [
                MetaChip(
                  label: providerLabel(l10n, track.source),
                  background: badgeColors.bg,
                  foreground: badgeColors.fg,
                ),
                if (track.language.isNotEmpty && track.language != 'und')
                  MetaChip(
                    label: track.language.toUpperCase(),
                    background: cs.surfaceContainerHighest,
                    foreground: cs.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          secondary: IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              fixedSize: const Size(36, 36),
              backgroundColor: cs.surface.withValues(alpha: 0.35),
            ),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
            tooltip: l10n.subtitlesDeleteTrack,
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}

class NoneOptionTile extends StatelessWidget {
  const NoneOptionTile({
    super.key,
    required this.padding,
    required this.label,
    required this.selected,
  });

  final EdgeInsetsGeometry padding;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: padding,
      child: Material(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.34)
            : cs.surfaceContainerHighest.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
          side: BorderSide(
            color: selected
                ? cs.primary.withValues(alpha: 0.42)
                : cs.outlineVariant.withValues(alpha: 0.14),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<String?>(
          value: null,
          selected: selected,
          contentPadding: EdgeInsets.fromLTRB(
            t.space8,
            t.space12,
            t.space12,
            t.space12,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            label,
            style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
