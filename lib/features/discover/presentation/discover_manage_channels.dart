/// Manage Discover subscriptions and browse recommended channels.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/sheet_drag_handle.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/presentation/discover_actions.dart';
import 'package:enjoy_player/features/discover/presentation/discover_recommended_avatar_strip.dart';
import 'package:enjoy_player/features/discover/presentation/discover_subscribe_sheet.dart';
import 'package:enjoy_player/features/discover/presentation/discover_subscription_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum DiscoverManageChannelsPresentation { sheet, dialog }

Future<void> showDiscoverManageChannels(BuildContext context, WidgetRef ref) {
  final w = MediaQuery.sizeOf(context).width;
  final tokens = EnjoyThemeTokens.of(context);
  if (w >= tokens.breakpointRail) {
    return showEnjoyDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final t = EnjoyThemeTokens.of(ctx);
        return Dialog(
          backgroundColor: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusXl),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: t.modalMaxWidthLarge,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusXl),
              child: const DiscoverManageChannelsView(
                presentation: DiscoverManageChannelsPresentation.dialog,
              ),
            ),
          ),
        );
      },
    );
  }
  return showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const DiscoverManageChannelsView(
      presentation: DiscoverManageChannelsPresentation.sheet,
    ),
  );
}

class DiscoverManageChannelsView extends ConsumerWidget {
  const DiscoverManageChannelsView({required this.presentation, super.key});

  final DiscoverManageChannelsPresentation presentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final recommendedAsync = ref.watch(filteredRecommendedChannelsProvider);
    final subscriptionsAsync = ref.watch(discoverSubscriptionsProvider);
    final isDialog = presentation == DiscoverManageChannelsPresentation.dialog;

    final subscriptionsWidget = subscriptionsAsync.when<Widget>(
      loading: () =>
          const SliverToBoxAdapter(child: SkeletonMediaList(itemCount: 2)),
      error: (_, _) => SliverToBoxAdapter(
        child: Text(
          l10n.discoverSubscriptionsLoadFailed,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
      data: (subs) {
        if (subs.isEmpty) {
          return SliverToBoxAdapter(
            child: Text(
              l10n.discoverNoSubscriptionsHint,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }
        return SliverList.separated(
          itemCount: subs.length,
          separatorBuilder: (_, _) => ColoredBox(
            color: cs.surfaceContainerLow,
            child: Divider(
              height: 1,
              thickness: 1,
              indent:
                  t.space16 + DiscoverSubscriptionRow.avatarSize + t.space12,
              endIndent: t.space16,
              color: cs.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          itemBuilder: (_, i) {
            final channel = subs[i];
            final topRadius = i == 0
                ? Radius.circular(t.radiusLg)
                : Radius.zero;
            final bottomRadius = i == subs.length - 1
                ? Radius.circular(t.radiusLg)
                : Radius.zero;
            return ClipRSuperellipse(
              borderRadius: BorderRadius.vertical(
                top: topRadius,
                bottom: bottomRadius,
              ),
              child: ColoredBox(
                color: cs.surfaceContainerLow,
                child: DiscoverSubscriptionRow(
                  key: ValueKey('discover-sub-${channel.channelId}'),
                  channel: channel,
                  navigateToFeed: false,
                  embeddedInList: true,
                  onUnsubscribe: () => unawaited(
                    unsubscribeDiscoverChannel(context, ref, channel.channelId),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final scrollBody = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            t.space24,
            t.space8,
            t.space24,
            t.space24,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.discoverRecommendedHeading,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          final cur = ref.read(
                            discoverRecommendedShowAllLanguagesProvider,
                          );
                          ref
                              .read(
                                discoverRecommendedShowAllLanguagesProvider
                                    .notifier,
                              )
                              .setShowAll(!cur);
                        },
                        child: Text(
                          ref.watch(discoverRecommendedShowAllLanguagesProvider)
                              ? l10n.discoverLanguageFilterLabel
                              : l10n.discoverLanguageFilterAll,
                        ),
                      ),
                    ),
                    SizedBox(height: t.space4),
                    recommendedAsync.when(
                      loading: () => const SizedBox(
                        height: DiscoverRecommendedAvatarStrip.rowHeight,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, _) => Text(
                        l10n.discoverRecommendedLoadFailed,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      data: (recommended) => subscriptionsAsync.when(
                        loading: () => const SizedBox(
                          height: DiscoverRecommendedAvatarStrip.rowHeight,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (subs) => DiscoverRecommendedAvatarStrip(
                          recommended: recommended,
                          subscribedChannelIds: subs
                              .map((s) => s.channelId)
                              .toSet(),
                        ),
                      ),
                    ),
                    SizedBox(height: t.space24),
                    OutlinedButton.icon(
                      onPressed: () =>
                          unawaited(showDiscoverSubscribeSheet(context)),
                      icon: const Icon(EnjoyIcons.addLink, size: 18),
                      label: Text(l10n.discoverSubscribeAction),
                    ),
                    SizedBox(height: t.space24),
                    Text(
                      l10n.discoverYourChannelsHeading,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space12),
                  ],
                ),
              ),
              subscriptionsWidget,
            ],
          ),
        ),
      ],
    );

    if (isDialog) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(t.space16, t.space8, t.space8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.discoverManageChannels,
                    style: tt.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(EnjoyIcons.close),
                ),
              ],
            ),
          ),
          Expanded(child: scrollBody),
        ],
      );
    }

    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;
    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PaddedSheetDragHandle(),
            Padding(
              padding: EdgeInsets.fromLTRB(t.space24, 0, t.space24, t.space8),
              child: Text(l10n.discoverManageChannels, style: tt.titleLarge),
            ),
            Expanded(child: scrollBody),
          ],
        ),
      ),
    );
  }
}
