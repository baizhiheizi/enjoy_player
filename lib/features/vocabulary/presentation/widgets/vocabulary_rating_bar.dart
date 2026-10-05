/// Session-level Don't know / Know / Know well chips.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Three equal-width rating chips using prototype score colors.
class VocabularyRatingBar extends StatelessWidget {
  const VocabularyRatingBar({
    super.key,
    required this.ratingInFlight,
    required this.onRate,
  });

  final bool ratingInFlight;
  final ValueChanged<VocabularyRating> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final gap = MediaQuery.sizeOf(context).width < 360 ? t.space4 : t.space8;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.transcriptMaxListen),
        child: Row(
          children: [
            Expanded(
              child: _RatingChip(
                label: l10n.vocabularyDontKnow,
                icon: EnjoyIcons.close,
                background: t.sunk,
                foreground: t.danger,
                onPressed: ratingInFlight
                    ? null
                    : () => onRate(VocabularyRating.dontKnow),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _RatingChip(
                label: l10n.vocabularyKnow,
                icon: EnjoyIcons.check,
                background: t.sunk,
                foreground: t.ink2,
                onPressed: ratingInFlight
                    ? null
                    : () => onRate(VocabularyRating.know),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _RatingChip(
                label: l10n.vocabularyKnowWell,
                icon: EnjoyIcons.checkCircleFill,
                background: t.sunk,
                foreground: t.ink,
                onPressed: ratingInFlight
                    ? null
                    : () => onRate(VocabularyRating.knowWell),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(t.radiusLg);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: EnjoyPressable(
        onTap: onPressed,
        borderRadius: radius,
        pressedScale: 0.95,
        washColor: foreground,
        child: AnimatedOpacity(
          duration: t.motionFast,
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: EdgeInsets.symmetric(
              horizontal: t.space8,
              vertical: t.space12,
            ),
            decoration: ShapeDecoration(
              color: background,
              shape: RoundedSuperellipseBorder(
                borderRadius: radius,
                side: BorderSide(color: foreground.withValues(alpha: 0.18)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: foreground),
                SizedBox(height: t.space4 + 2),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
