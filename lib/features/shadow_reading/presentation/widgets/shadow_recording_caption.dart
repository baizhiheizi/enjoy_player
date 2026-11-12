import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
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
        label: l10n.shadowRecordingElapsedSemantics(
          _formatSecsOneDecimal(elapsedSec),
          _formatSecsOneDecimal(targetSec),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tok.space8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.shadowRecordingElapsedCountdown(
                  _formatSecsOneDecimal(elapsedSec),
                  _formatSecsOneDecimal(targetSec),
                ),
                style: tt.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (overTarget) ...[
                SizedBox(width: tok.space8),
                Icon(EnjoyIcons.dot, size: 8, color: scheme.error),
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
        l10n.shadowRecordingElapsedSeconds(_formatSecsOneDecimal(elapsedSec)),
        style: tt.labelMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Live elapsed caption driven by the shared ticker's tenths: the
/// tenths-to-seconds conversion and the over-target evaluation happen once
/// here, so every recording surface renders from a single formula
/// (issue #1320).
class ShadowRecordingElapsedCaption extends StatelessWidget {
  const ShadowRecordingElapsedCaption({
    required this.elapsedTenths,
    required this.targetSec,
    super.key,
  });

  final ValueListenable<int> elapsedTenths;
  final double targetSec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tok = EnjoyThemeTokens.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: elapsedTenths,
      builder: (context, tenths, _) {
        final elapsedSec = tenths / 10;
        final overTarget = targetSec > 0 && elapsedSec > targetSec;
        return ShadowRecordingCaptionRow(
          elapsedSec: elapsedSec,
          targetSec: targetSec,
          overTarget: overTarget,
          overBySec: overTarget ? elapsedSec - targetSec : 0.0,
          l10n: l10n,
          tt: tt,
          scheme: scheme,
          tok: tok,
        );
      },
    );
  }
}
