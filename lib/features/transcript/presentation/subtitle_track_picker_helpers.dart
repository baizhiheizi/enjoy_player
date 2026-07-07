/// Pure helpers, theme shims, and constants shared across the subtitle track
/// picker modules. No widgets, no state.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Which collapsible section of the picker is being built.
enum PickerSection { primary, secondary }

/// Max height for an expanded track list before it scrolls internally.
const double kExpandedTrackListMaxHeight = 280;

/// Horizontal inset aligned with section headers and list rows.
double sheetHorizontalPadding(EnjoyThemeTokens t) => t.space16 + t.space4;

/// Inner padding for track options inside a collapsible card.
EdgeInsetsDirectional trackOptionPadding(EnjoyThemeTokens t) =>
    EdgeInsetsDirectional.fromSTEB(t.space8, t.space4, t.space8, t.space4);

ThemeData trackPickerRadioTheme(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).copyWith(
    splashColor: cs.primary.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
    hoverColor: cs.onSurface.withValues(alpha: 0.04),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return cs.primary;
        return cs.onSurfaceVariant.withValues(alpha: 0.55);
      }),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: Colors.transparent,
      iconColor: cs.onSurfaceVariant,
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          EnjoyThemeTokens.of(context).radiusSm,
        ),
      ),
    ),
  );
}

String trackLabel(TranscriptTrack track) =>
    track.label.isNotEmpty ? track.label : track.language;

TranscriptTrack? findTrack(List<TranscriptTrack> tracks, String? id) {
  if (id == null) return null;
  for (final track in tracks) {
    if (track.id == id) return track;
  }
  return null;
}

String providerLabel(AppLocalizations l10n, String source) {
  switch (source) {
    case 'official':
      return l10n.subtitlesProviderOfficial;
    case 'auto':
      return l10n.subtitlesProviderAuto;
    case 'ai':
      return l10n.subtitlesProviderAi;
    case 'user':
      return l10n.subtitlesProviderUser;
    default:
      return source.toUpperCase();
  }
}

({Color bg, Color fg}) providerBadgeColors(ColorScheme cs, String source) {
  switch (source) {
    case 'official':
      return (bg: cs.primaryContainer, fg: cs.onPrimaryContainer);
    case 'auto':
      return (bg: cs.tertiaryContainer, fg: cs.onTertiaryContainer);
    case 'ai':
      return (bg: cs.secondaryContainer, fg: cs.onSecondaryContainer);
    case 'user':
      return (bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
    default:
      return (bg: cs.surfaceContainerHigh, fg: cs.onSurfaceVariant);
  }
}
