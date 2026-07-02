import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String _formatSecsOneDecimal(double seconds) {
  return seconds.toStringAsFixed(1);
}

/// Live recording caption `0.0 s / 1.2 s` (+ over-target error badge) with
/// `Semantics`.
///
/// Extracted from `shadow_reading_panel.dart` — see issue #180.
class ShadowRecordingCaptionRow extends StatelessWidget {
  const ShadowRecordingCaptionRow({
    required this.elapsedSec,
    required this.targetSec,
    required this.overTarget,
    required this.overBySec,
    required this.l10n,
    required this.tt,
    required this.scheme,
    required this.tok,
    super.key,
  });

  final double elapsedSec;
  final double targetSec;
  final bool overTarget;
  final double overBySec;
  final AppLocalizations l10n;
  final TextTheme tt;
  final ColorScheme scheme;
  final EnjoyThemeTokens tok;

  @override
  Widget build(BuildContext context) {
    if (targetSec > 0) {
      return Semantics(
        label:
            '${_formatSecsOneDecimal(elapsedSec)} seconds elapsed of '
            '${_formatSecsOneDecimal(targetSec)} seconds target',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tok.space8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_formatSecsOneDecimal(elapsedSec)} s / '
                '${_formatSecsOneDecimal(targetSec)} s',
                style: tt.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (overTarget) ...[
                SizedBox(width: tok.space8),
                Icon(Icons.circle, size: 8, color: scheme.error),
                SizedBox(width: tok.space4),
                Flexible(
                  child: Text(
                    l10n.shadowRecordingOverTarget(
                      _formatSecsOneDecimal(overBySec),
                    ),
                    style: tt.labelSmall?.copyWith(color: scheme.error),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Text(
        '${_formatSecsOneDecimal(elapsedSec)} s',
        style: tt.labelMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
