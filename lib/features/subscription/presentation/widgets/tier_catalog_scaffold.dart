/// Shared shell for the tier catalog's Free / Lite / Pro cards plus the
/// feature-row bullet they render.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';

/// Fixed badge-row height so Free / Lite / Pro titles align in the wide row.
const double kTierBadgeSlotHeight = 28;

/// Tappable-pill padding for the catalog's badges (rides `EnjoyTierBadge`).
const EdgeInsets kCatalogPillPadding = EdgeInsets.symmetric(
  horizontal: 10,
  vertical: 4,
);

/// Price display size shared by the Free and paid tier cards.
const double kTierPriceSize = 38;

/// Card shell: reserved badge slot, feature list, and (when [expand] is true)
/// a spacer that pins the CTA to the bottom so wide-layout cards stretch to
/// equal height.
class TierCardScaffold extends StatelessWidget {
  const TierCardScaffold({
    required this.expand,
    required this.badges,
    required this.title,
    required this.description,
    required this.price,
    required this.dailyCredits,
    this.intervalLine,
    required this.features,
    required this.emphasizeFeatures,
    required this.cta,
    super.key,
  });

  final bool expand;
  final Widget? badges;
  final String title;
  final String description;
  final Widget price;
  final String dailyCredits;
  final String? intervalLine;
  final List<String> features;
  final bool emphasizeFeatures;
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        SizedBox(
          height: kTierBadgeSlotHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: badges ?? const SizedBox.shrink(),
          ),
        ),
        SizedBox(height: t.space12),
        Text(
          title,
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: t.space4),
        Text(
          description,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        SizedBox(height: t.space16),
        price,
        SizedBox(height: t.space4),
        Text(
          dailyCredits,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (intervalLine != null) ...[
          SizedBox(height: t.space12),
          Text(
            intervalLine!,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        SizedBox(height: t.space16),
        for (final feature in features) ...[
          TierFeatureBullet(
            text: feature,
            emphasize: emphasizeFeatures,
            tt: tt,
          ),
          SizedBox(height: t.space8),
        ],
        if (expand) const Spacer() else SizedBox(height: t.space16),
        cta,
      ],
    );

    return EnjoyCard(padding: EdgeInsets.all(t.space20), child: body);
  }
}

class TierFeatureBullet extends StatelessWidget {
  const TierFeatureBullet({
    required this.text,
    required this.emphasize,
    required this.tt,
    super.key,
  });

  final String text;
  final bool emphasize;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            EnjoyIcons.check,
            size: 15,
            color: emphasize ? t.brandInk : t.ink3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: tt.bodyMedium)),
      ],
    );
  }
}
