/// Editorial pill [SegmentedButton] styling shared across Library chrome.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

/// Shared Material 3 segment styling for Library source and kind controls.
ButtonStyle enjoySegmentedButtonStyle(BuildContext context) {
  final t = EnjoyThemeTokens.of(context);
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return SegmentedButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
    foregroundColor: cs.onSurfaceVariant,
    selectedForegroundColor: cs.onPrimaryContainer,
    selectedBackgroundColor: cs.primaryContainer.withValues(alpha: 0.65),
    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
    splashFactory: NoSplash.splashFactory,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(t.radiusFull),
    ),
    textStyle: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}
