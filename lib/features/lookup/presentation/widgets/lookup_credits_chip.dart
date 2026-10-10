/// Remaining-credits chip at the top of the lookup sheet (issue #870 2.5).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Signed-in-only stadium chip showing today's remaining worker credits so
/// the sheet warns before a lookup is rejected, not after. Renders nothing
/// while signed out or while the summary has not loaded (loading / error),
/// so it never adds noise to anonymous or offline use.
class LookupCreditsChip extends ConsumerWidget {
  const LookupCreditsChip({super.key});

  static const double _hPad = 20;

  /// Mirrors the profile meter's low threshold: 90% of the daily pool used.
  static const _kLowRemainingFraction = 0.1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return const SizedBox.shrink();

    final summary = ref.watch(creditsSummaryProvider).valueOrNull;
    if (summary == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final t = EnjoyThemeTokens.of(context);
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final tier = ref.watch(currentTierProvider);
    final limit = status?.dailyCreditsLimit ?? fallbackDailyCreditsLimit(tier);

    final remaining = summary.dailyRemaining.clamp(0, limit);
    final isLow = remaining <= limit * _kLowRemainingFraction;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final count = NumberFormat.decimalPattern(locale).format(remaining);
    final label = isLow
        ? l10n.lookupCreditsRunningLowLabel(count)
        : l10n.lookupCreditsRemainingLabel(count);
    final tone = isLow ? t.danger : t.ink2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: EnjoyPressable(
          shape: const StadiumBorder(),
          semanticsLabel: label,
          onTap: () => context.push(isLow ? '/subscription' : '/credits'),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(EnjoyIcons.wallet, size: 14, color: tone),
                SizedBox(width: t.space4),
                Text(
                  label,
                  style: enjoyMonoStyle(
                    context,
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: tone,
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
