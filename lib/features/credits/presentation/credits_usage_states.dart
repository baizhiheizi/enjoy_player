/// Async / result states for the credits usage screen
/// (loading skeleton, error retry, empty state).
library;

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart'
    as empty_widget;
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/credits/application/credits_usage_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageErrorBody extends ConsumerWidget {
  const PageErrorBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.all(t.space24),
      child: empty_widget.EmptyState(
        title: l10n.creditsUsageError,
        subtitle: l10n.creditsUsageErrorDescription,
        action: () => ref.invalidate(creditsUsagePageProvider),
        actionLabel: l10n.creditsUsageRetry,
      ),
    );
  }
}

class CreditsUsageLoadingList extends StatelessWidget {
  const CreditsUsageLoadingList({super.key});

  static const _skeletonCount = 4;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return SkeletonTickerHost(
      child: Column(
        children: [
          for (var i = 0; i < _skeletonCount; i++)
            Padding(
              padding: EdgeInsets.only(bottom: t.space12),
              child: const _UsageLogCardSkeleton(),
            ),
        ],
      ),
    );
  }
}

class _UsageLogCardSkeleton extends StatelessWidget {
  const _UsageLogCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return EnjoyCard(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.line(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(t.radiusSm),
          ),
          SizedBox(height: t.space8),
          Skeleton.line(
            width: 120,
            height: 12,
            borderRadius: BorderRadius.circular(t.radiusSm),
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              Skeleton.line(
                width: 72,
                height: 24,
                borderRadius: BorderRadius.circular(t.radiusFull),
              ),
              SizedBox(width: t.space8),
              Skeleton.line(
                width: 48,
                height: 24,
                borderRadius: BorderRadius.circular(t.radiusFull),
              ),
            ],
          ),
          SizedBox(height: t.space12),
          Row(
            children: [
              Expanded(
                child: Skeleton.line(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
              SizedBox(width: t.space16),
              Expanded(
                child: Skeleton.line(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreditsUsageEmptyState extends StatelessWidget {
  const CreditsUsageEmptyState({required this.hasFilters, super.key});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return empty_widget.EmptyState(
      title: l10n.creditsUsageNoRecords,
      subtitle: hasFilters
          ? l10n.creditsUsageNoRecordsWithFilters
          : l10n.creditsUsageNoRecordsDescription,
    );
  }
}
