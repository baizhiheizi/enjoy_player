/// Dismissible banner prompting guest → account local data migration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/guest_migration_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class GuestMigrationBanner extends ConsumerWidget {
  const GuestMigrationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAsync = ref.watch(showGuestMigrationBannerProvider);
    return showAsync.when(
      data: (show) {
        if (!show) return const SizedBox.shrink();
        final t = EnjoyThemeTokens.of(context);
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final l10n = AppLocalizations.of(context)!;
        final migration = ref.watch(guestMigrationCtrlProvider);

        return Padding(
          padding: EdgeInsets.fromLTRB(t.space24, t.space12, t.space24, 0),
          child: Material(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(t.radiusLg),
            child: Padding(
              padding: EdgeInsets.all(t.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.move_to_inbox_rounded,
                        color: cs.onPrimaryContainer,
                        size: 28,
                      ),
                      SizedBox(width: t.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.migrationBannerTitle,
                              style: tt.titleSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: t.space4),
                            Text(
                              l10n.migrationBannerBody,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer.withValues(
                                  alpha: 0.92,
                                ),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: t.space12),
                  if (migration.isLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: t.space8),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: t.space8,
                      runSpacing: t.space8,
                      children: [
                        TextButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(guestMigrationCtrlProvider.notifier)
                                      .dismiss(),
                          child: Text(l10n.migrationBannerActionDismiss),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ref
                                .read(guestMigrationCtrlProvider.notifier)
                                .migrate();
                            if (!context.mounted) return;
                            final s = ref.read(guestMigrationCtrlProvider);
                            s.when(
                              data: (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.migrationSuccess),
                                  ),
                                );
                              },
                              error: (Object e, StackTrace st) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.migrationMigrationFailed,
                                    ),
                                  ),
                                );
                              },
                              loading: () {},
                            );
                          },
                          child: Text(l10n.migrationBannerActionMove),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
    );
  }
}
