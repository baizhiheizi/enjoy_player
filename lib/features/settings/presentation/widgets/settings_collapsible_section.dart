/// A Settings section that can be manually expanded/collapsed.
///
/// Used only for the low-frequency sections that default-collapse
/// (Developer, About — FR-012); every other section always renders via
/// [SettingsSectionCard] with no collapse affordance. Respects
/// "reduce motion" (collapse/expand happens instantly, no animation) and
/// keeps a real, always-visible tap target so the toggle works even with
/// motion disabled — see quickstart.md's accessibility pass.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsCollapsibleSection extends StatelessWidget {
  const SettingsCollapsibleSection({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
    required this.collapsed,
    required this.onToggle,
    required this.child,
    this.needsAttention = false,
    this.wrapInCard = true,
  });

  final String title;
  final String hint;
  final IconData icon;
  final bool collapsed;
  final VoidCallback onToggle;
  final Widget child;

  /// Shows a small badge in the header when [collapsed] is true so an
  /// error/warning inside isn't silently hidden (spec edge case).
  final bool needsAttention;

  /// Set to `false` when [child] already renders its own bordered surface
  /// (e.g. [AboutSectionCard]) to avoid a card-inside-a-card look.
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // `AnimatedSize`/`AnimatedRotation` with a literal `Duration.zero` throw
    // "RenderAnimatedSize was mutated in its own performLayout" — the
    // animation controller's listener re-dirties layout mid-pass. A 1ms
    // duration is visually instant (respecting reduced motion) without
    // tripping that framework assertion.
    final duration = reduceMotion
        ? const Duration(milliseconds: 1)
        : t.motionMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: collapsed
              ? l10n.settingsSectionExpandSemantics
              : l10n.settingsSectionCollapseSemantics,
          child: InkWell(
            onTap: Haptics.wrapTap(context, onToggle),
            borderRadius: BorderRadius.circular(t.radiusLg),
            child: SettingsSectionHeader(
              title: title,
              hint: hint,
              icon: icon,
              subdued: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (collapsed && needsAttention) ...[
                    _AttentionBadge(label: l10n.settingsSectionNeedsAttention),
                    SizedBox(width: t.space8),
                  ],
                  AnimatedRotation(
                    turns: collapsed ? 0 : 0.5,
                    duration: duration,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: collapsed
              ? const SizedBox(width: double.infinity)
              : (wrapInCard
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: t.space16),
                        child: EnjoyCard(
                          padding: EdgeInsets.all(t.space16),
                          child: child,
                        ),
                      )
                    : child),
        ),
      ],
    );
  }
}

class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space4),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(t.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: cs.onErrorContainer),
          SizedBox(width: t.space4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
