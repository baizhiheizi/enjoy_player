/// Craft history: browse, re-open, and remove Craft records (keep audio).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/application/craft_history_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_library_repository_provider.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Full-screen route listing Craft history (`provider = 'craft'`).
/// Tapping loads an item for edit. Remove deletes the Craft history
/// record (clears Craft provenance) but leaves the practice audio in
/// the library.
class CraftHistoryScreen extends ConsumerWidget {
  const CraftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final historyAsync = ref.watch(craftHistoryProvider);

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      showBack: true,
      title: l10n.craftHistoryTitle,
      body: (context, metrics) => historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: EnjoyIcons.sparkle,
              title: l10n.craftHistoryEmptyTitle,
              subtitle: l10n.craftHistoryEmptyHint,
              action: () => context.go('/craft'),
              actionLabel: l10n.craftHistoryEmptyAction,
            );
          }
          return ListView(
            padding: metrics.padding(top: t.space16, bottom: t.space32),
            children: [
              EnjoySectionHeader(
                title: l10n.craftHistoryTitle,
                caption: '${items.length}',
                padding: EdgeInsets.only(bottom: t.space12),
              ),
              EnjoyCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const SettingsRowDivider(insetForLeading: false),
                      _CraftHistoryTile(
                        media: items[i],
                        onTap: () => _openForEdit(context, ref, items[i]),
                        onRemove: () => _removeRecord(context, ref, items[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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

  Future<void> _removeRecord(
    BuildContext context,
    WidgetRef ref,
    Media media,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      title: Text(l10n.craftHistoryRemoveTitle),
      content: Text(l10n.craftHistoryRemoveMessage(media.title)),
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.craftHistoryRemoveConfirm),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;

    final editingId = ref.read(craftControllerProvider).editingMediaId;
    try {
      await ref
          .read(craftLibraryRepositoryProvider)
          .removeCraftHistoryRecord(media.id);
    } catch (_) {
      if (context.mounted) {
        AppNotice.error(context, l10n.craftHistoryRemoveFailed);
      }
      return;
    }
    if (!context.mounted) return;

    if (editingId == media.id) {
      ref.read(craftControllerProvider.notifier).resetForNextCapture();
    }
    AppNotice.success(context, l10n.craftHistoryRemoved);
  }
}

class _CraftHistoryTile extends StatelessWidget {
  const _CraftHistoryTile({
    required this.media,
    required this.onTap,
    required this.onRemove,
  });

  final Media media;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd().add_jm();

    return SettingsRow(
      leadingIcon: EnjoyIcons.sparkle,
      title: media.title,
      subtitle: dateFmt.format(media.updatedAt.toLocal()),
      onTap: onTap,
      trailing: EnjoyIconButton(
        icon: EnjoyIcons.delete,
        tooltip: l10n.craftHistoryRemoveTooltip,
        variant: EnjoyButtonVariant.destructive,
        size: 30,
        onPressed: onRemove,
      ),
    );
  }
}
