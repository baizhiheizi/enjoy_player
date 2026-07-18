/// Radio-style selectable rows used inside the subtitle track lists.
///
/// Compact single-line layout: leading radio + title (Expanded) + provider and
/// language chips + trailing delete. Unselected rows are borderless with a
/// 1px bottom divider; selected rows get a tinted card.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'subtitle_track_picker_helpers.dart';
import 'subtitle_track_picker_primitives.dart';

/// Shared shell for the three track-option row variants.
///
/// Renders a single-line row inside the caller-provided [padding]:
/// leading radio, an expandable title, optional trailing chip(s), and an
/// optional trailing delete affordance. The outer chrome switches between a
/// tinted card (when [selected]) and a borderless row with a 1px bottom
/// divider (when not).
class _CompactOptionRow<T> extends StatelessWidget {
  const _CompactOptionRow({
    required this.value,
    required this.selected,
    required this.title,
    required this.padding,
    required this.chips,
    this.enabled = true,
    this.onTap,
    this.deleteLabel,
    this.onDelete,
  });

  final T value;
  final bool selected;
  final String title;
  final EdgeInsetsGeometry padding;
  final List<Widget> chips;
  final bool enabled;
  final VoidCallback? onTap;
  final String? deleteLabel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(t.radiusSm);
    final titleColor = enabled ? null : cs.onSurface.withValues(alpha: 0.38);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Radio<T>(
            value: value,
            enabled: enabled,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                height: 1.2,
                color: titleColor,
              ),
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(width: 8),
            ..._spaced(chips, const SizedBox(width: 6)),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: 2),
            _CompactDeleteButton(label: deleteLabel!, onPressed: onDelete!),
          ],
        ],
      ),
    );

    final inkWell = InkWell(
      onTap: !enabled
          ? null
          : onTap ??
                () => RadioGroup.maybeOf<T>(context)?.onChanged.call(value),
      borderRadius: radius,
      child: SizedBox(height: 40, child: row),
    );

    return Padding(
      padding: padding,
      child: selected
          ? Material(
              color: cs.primaryContainer.withValues(alpha: 0.34),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.42)),
              ),
              clipBehavior: Clip.antiAlias,
              child: inkWell,
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.14),
                  ),
                ),
              ),
              child: inkWell,
            ),
    );
  }

  static List<Widget> _spaced(List<Widget> children, Widget gap) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(gap);
      out.add(children[i]);
    }
    return out;
  }
}

class _CompactDeleteButton extends StatelessWidget {
  const _CompactDeleteButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        Icons.delete_outline_rounded,
        size: 18,
        color: cs.onSurfaceVariant,
      ),
      tooltip: label,
      onPressed: onPressed,
    );
  }
}

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
    final cs = Theme.of(context).colorScheme;
    final label = trackLabel(track);
    final badgeColors = providerBadgeColors(cs, track.source);

    final chips = <Widget>[
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
    ];

    return _CompactOptionRow<T>(
      value: value,
      selected: selected,
      title: label,
      padding: padding,
      chips: chips,
      deleteLabel: l10n.subtitlesDeleteTrack,
      onDelete: onDelete,
    );
  }
}

class AutoTranslateOptionTile extends StatelessWidget {
  const AutoTranslateOptionTile({
    super.key,
    required this.value,
    required this.selected,
    required this.padding,
    required this.targetLanguage,
    this.enabled = true,
  });

  final String value;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final String targetLanguage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final badgeColors = providerBadgeColors(cs, 'ai');

    final chips = <Widget>[
      MetaChip(
        label: providerLabel(l10n, 'ai'),
        background: badgeColors.bg,
        foreground: badgeColors.fg,
      ),
      if (targetLanguage.isNotEmpty)
        MetaChip(
          label: l10n.subtitlesAutoTranslateLanguageChip(
            targetLanguage.toUpperCase(),
          ),
          background: cs.surfaceContainerHighest,
          foreground: cs.onSurfaceVariant,
        ),
    ];

    return _CompactOptionRow<String?>(
      value: value,
      selected: selected,
      title: l10n.subtitlesAutoTranslate,
      padding: padding,
      chips: chips,
      enabled: enabled,
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
    return _CompactOptionRow<String?>(
      value: null,
      selected: selected,
      title: label,
      padding: padding,
      chips: const [],
    );
  }
}
