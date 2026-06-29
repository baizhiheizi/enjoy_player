/// Manage Discover subscriptions and browse recommended channels.
library;

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
    final recommendedAsync = ref.watch(recommendedChannelsProvider);
    final subscriptionsAsync = ref.watch(discoverSubscriptionsProvider);
    final isDialog = presentation == DiscoverManageChannelsPresentation.dialog;

    final scrollBody = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(t.space24, t.space8, t.space24, t.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.discoverRecommendedHeading,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: t.space12),
          recommendedAsync.when(
            loading: () => const SizedBox(
              height: DiscoverRecommendedAvatarStrip.rowHeight,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Text(
              l10n.discoverRecommendedLoadFailed,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            data: (recommended) => subscriptionsAsync.when(
              loading: () => const SizedBox(
                height: DiscoverRecommendedAvatarStrip.rowHeight,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (subs) => DiscoverRecommendedAvatarStrip(
                recommended: recommended,
                subscribedChannelIds: subs.map((s) => s.channelId).toSet(),
              ),
            ),
          ),
          SizedBox(height: t.space24),
          OutlinedButton.icon(
            onPressed: () => unawaited(showDiscoverSubscribeSheet(context)),
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: Text(l10n.discoverSubscribeAction),
          ),
          SizedBox(height: t.space24),
          Text(
            l10n.discoverYourChannelsHeading,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: t.space12),
          subscriptionsAsync.when(
            loading: () => const SkeletonMediaList(itemCount: 2),
            error: (_, _) => Text(
              l10n.discoverSubscriptionsLoadFailed,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            data: (subs) {
              if (subs.isEmpty) {
                return Text(
                  l10n.discoverNoSubscriptionsHint,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                );
              }
              return DiscoverSubscriptionList(
                children: [
                  for (final channel in subs)
                    DiscoverSubscriptionRow(
                      channel: channel,
                      navigateToFeed: false,
                      embeddedInList: true,
                      onUnsubscribe: () => unawaited(
                        unsubscribeDiscoverChannel(
                          context,
                          ref,
                          channel.channelId,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
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
                  icon: const Icon(Icons.close_rounded),
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
