/// Busy-aware retry action shared by the lookup surfaces.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum LookupRetryButtonVariant { inline, callout }

extension _LookupRetryButtonVariantMetrics on LookupRetryButtonVariant {
  double get loadingIconSize => switch (this) {
    LookupRetryButtonVariant.inline => 14,
    LookupRetryButtonVariant.callout => 18,
  };

  double get refreshIconSize => switch (this) {
    LookupRetryButtonVariant.inline => 16,
    LookupRetryButtonVariant.callout => 20,
  };
}

class LookupRetryButton extends StatelessWidget {
  const LookupRetryButton({
    required this.busy,
    required this.onPressed,
    this.variant = LookupRetryButtonVariant.inline,
    super.key,
  });

  final bool busy;
  final VoidCallback? onPressed;
  final LookupRetryButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final icon = busy
        ? LoadingIcon(size: variant.loadingIconSize, color: scheme.primary)
        : Icon(EnjoyIcons.refresh, size: variant.refreshIconSize);
    final label = Text(l10n.lookupErrorRetry);

    return switch (variant) {
      LookupRetryButtonVariant.inline => TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(horizontal: t.space8),
          minimumSize: const Size(0, 36),
        ),
        onPressed: busy ? null : onPressed,
        icon: icon,
        label: label,
      ),
      LookupRetryButtonVariant.callout => FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space8,
          ),
        ),
        onPressed: busy ? null : onPressed,
        icon: icon,
        label: label,
      ),
    };
  }
}
