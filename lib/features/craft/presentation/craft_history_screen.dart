/// Craft history: browse and re-open previously Crafted library items.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/application/craft_history_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Full-screen route listing every `provider = 'craft'` library item,
/// newest-edited first. Tapping an item loads it back into the Craft
/// controller for editing.
class CraftHistoryScreen extends ConsumerWidget {
  const CraftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(craftHistoryProvider);

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      showBack: true,
      title: l10n.craftHistoryTitle,
      body: (context, metrics) => historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: l10n.craftHistoryEmptyTitle,
              subtitle: l10n.craftHistoryEmptyHint,
              action: () => context.go('/craft'),
              actionLabel: l10n.craftHistoryEmptyAction,
            );
          }
          return ListView.separated(
            padding: metrics.padding(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: EnjoyThemeTokens.of(context).space8),
            itemBuilder: (context, index) => _CraftHistoryTile(
              media: items[index],
              onTap: () => _openForEdit(context, ref, items[index]),
            ),
          );
        },
        loading: () => const SkeletonSettingsList(rowCount: 6),
        error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
      ),
    );
  }

  Future<void> _openForEdit(
    BuildContext context,
    WidgetRef ref,
    Media media,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref
        .read(craftControllerProvider.notifier)
        .loadForEdit(media.id);
    if (!context.mounted) return;
    if (ok) {
      context.go('/craft');
    } else {
      AppNotice.error(context, l10n.craftEditUnavailable);
    }
  }
}

class _CraftHistoryTile extends StatelessWidget {
  const _CraftHistoryTile({required this.media, required this.onTap});

  final Media media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(Icons.auto_awesome_outlined, color: cs.primary),
        title: Text(media.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(dateFmt.format(media.updatedAt.toLocal())),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
