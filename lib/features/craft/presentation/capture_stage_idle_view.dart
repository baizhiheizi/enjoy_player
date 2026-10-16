import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CaptureIdleView extends StatelessWidget {
  const CaptureIdleView({
    super.key,
    required this.state,
    required this.l10n,
    required this.theme,
    required this.isTablet,
    required this.onMicTap,
    required this.onTypeInstead,
  });

  final CraftJobState state;
  final AppLocalizations l10n;
  final ThemeData theme;
  final bool isTablet;
  final VoidCallback onMicTap;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = theme.colorScheme;
    final buttonSize = isTablet ? 88.0 : 72.0;
    final sourceLang = state.sourceLanguage;
    final sourceLabel = sourceLang == null
        ? '—'
        : languageEndonymLabel(sourceLang) ?? sourceLang.toUpperCase();
    final targetLabel =
        languageEndonymLabel(state.targetLanguage) ??
        state.targetLanguage.toUpperCase();

    Widget langChip(String label, {required bool target}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: target ? t.originalSoft : t.sunk,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: target ? t.originalInk : t.ink2,
        ),
      ),
    );

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonSize * 1.8,
              height: buttonSize * 1.8,
              child: Center(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    gradient: RadialGradient(
                      colors: [
                        t.you.withValues(alpha: 0.22),
                        t.you.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.45, 0.75, 1],
                    ),
                  ),
                  child: EnjoyPressable(
                    onTap: onMicTap,
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    pressedScale: 0.95,
                    semanticsLabel: l10n.craftCaptureTitle,
                    child: AnimatedContainer(
                      duration: t.motionFast,
                      width: buttonSize,
                      height: buttonSize,
                      decoration: ShapeDecoration(
                        color: t.you,
                        shape: const CircleBorder(),
                        shadows: t.shadowRecordButton,
                      ),
                      child: Icon(
                        EnjoyIcons.micFill,
                        color: t.onYou,
                        size: buttonSize * 0.42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: t.space16),
            Text(
              l10n.craftCaptureTitle,
              style: enjoyDisplayStyle(
                context,
                size: isTablet ? 30 : 26,
                color: scheme.onSurface,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: t.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                l10n.craftCaptureSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: t.space16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                langChip(sourceLabel, target: false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(EnjoyIcons.arrowRight, size: 14, color: t.ink3),
                ),
                langChip(targetLabel, target: true),
              ],
            ),
            SizedBox(height: t.space16),
            EnjoyButton.ghost(
              onPressed: onTypeInstead,
              icon: EnjoyIcons.keyboard,
              child: Text(l10n.craftCaptureTypeInstead),
            ),
          ],
        ),
      ),
    );
  }
}
