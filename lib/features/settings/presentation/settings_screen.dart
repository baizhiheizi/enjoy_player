/// Settings — editorial grouped iOS-style cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/guest_migration_providers.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_settings_section.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: EditorialHeader(title: l10n.settingsTitle)),

          // ── Account section ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(text: l10n.settingsSectionAccount),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: Consumer(
                builder: (context, ref, _) {
                  final auth = ref.watch(authCtrlProvider);
                  return auth.when(
                    data: (state) {
                      if (state is AuthSignedIn) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            radius: 20,
                            child: Text(
                              (state.profile.name.isNotEmpty
                                      ? state.profile.name[0]
                                      : '?')
                                  .toUpperCase(),
                              style: tt.titleMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(
                            state.profile.name,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            state.profile.email,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/profile'),
                        );
                      }
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest,
                          radius: 20,
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          l10n.settingsAccountSignIn,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.settingsAccountSignedOut,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/sign-in'),
                      );
                    },
                    loading:
                        () => ListTile(
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          ),
                          title: Text(l10n.loading),
                        ),
                    error: (Object e, StackTrace s) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Guest data migration (signed-in + guest DB has data) ───────
          Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authCtrlProvider);
              final signedIn = auth.maybeWhen(
                data: (s) => s is AuthSignedIn,
                orElse: () => false,
              );
              if (!signedIn) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              final guestDataAsync = ref.watch(guestDatabaseHasDataProvider);
              return guestDataAsync.when(
                data: (hasGuestData) {
                  if (!hasGuestData) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final cs = Theme.of(context).colorScheme;
                  final tt = Theme.of(context).textTheme;
                  final migration = ref.watch(guestMigrationCtrlProvider);
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(text: l10n.settingsSectionDataMigration),
                        _SettingsCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: Icon(
                              Icons.move_to_inbox_rounded,
                              color: cs.primary,
                            ),
                            title: Text(
                              l10n.settingsMigrationTitle,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              l10n.settingsMigrationSubtitle,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            trailing:
                                migration.isLoading
                                    ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.primary,
                                      ),
                                    )
                                    : const Icon(Icons.chevron_right_rounded),
                            onTap:
                                migration.isLoading
                                    ? null
                                    : () async {
                                      await ref
                                          .read(
                                            guestMigrationCtrlProvider.notifier,
                                          )
                                          .migrate();
                                      if (!context.mounted) return;
                                      final s = ref.read(
                                        guestMigrationCtrlProvider,
                                      );
                                      s.when(
                                        data: (_) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.migrationSuccess,
                                              ),
                                            ),
                                          );
                                        },
                                        error: (Object e, StackTrace st) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                          ),
                        ),
                        SizedBox(height: t.space8),
                      ],
                    ),
                  );
                },
                loading:
                    () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error:
                    (Object error, StackTrace stackTrace) =>
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
              );
            },
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Cloud sync ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(text: l10n.settingsSectionSync),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: Consumer(
                builder: (context, ref, _) {
                  final auth = ref.watch(authCtrlProvider);
                  final snapAsync = ref.watch(syncQueueSnapshotProvider);
                  return auth.when(
                    data: (state) {
                      if (state is AuthSignedIn) {
                        return snapAsync.when(
                          data: (snap) {
                            final subtitle =
                                snap.isFullyCaughtUp
                                    ? l10n.syncSettingsTileSubtitleUpToDate
                                    : l10n.syncSettingsTileSubtitleCounts(
                                      snap.retryablePending,
                                      snap.permanentlyFailed,
                                    );
                            return ListTile(
                              leading: Icon(
                                Icons.cloud_sync_outlined,
                                color: cs.primary,
                              ),
                              title: Text(
                                l10n.syncSettingsTileTitle,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.push('/settings/sync'),
                            );
                          },
                          loading:
                              () => ListTile(
                                leading: Icon(
                                  Icons.cloud_sync_outlined,
                                  color: cs.primary,
                                ),
                                title: Text(l10n.syncSettingsTileTitle),
                                subtitle: Text(l10n.loading),
                              ),
                          error:
                              (Object e, StackTrace s) => ListTile(
                                leading: Icon(
                                  Icons.cloud_sync_outlined,
                                  color: cs.error,
                                ),
                                title: Text(l10n.syncSettingsTileTitle),
                                subtitle: Text('$e'),
                                onTap: () => context.push('/settings/sync'),
                              ),
                        );
                      }
                      return ListTile(
                        leading: Icon(
                          Icons.cloud_off_outlined,
                          color: cs.onSurfaceVariant,
                        ),
                        title: Text(
                          l10n.syncSettingsTileTitle,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.syncSettingsTileSubtitleSignedOut,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings/sync'),
                      );
                    },
                    loading:
                        () => ListTile(
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          ),
                          title: Text(l10n.syncSettingsTileTitle),
                        ),
                    error: (Object e, StackTrace s) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Keyboard shortcuts (desktop only) ─────────────────────────
          if (isDesktop) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(text: l10n.hotkeysSectionKeyboard),
            ),
            const SliverToBoxAdapter(
              child: _SettingsCard(child: HotkeysSettingsSection()),
            ),
            SliverToBoxAdapter(child: SizedBox(height: t.space8)),
          ],

          // ── Advanced ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(text: l10n.settingsSectionAdvanced),
          ),
          const SliverToBoxAdapter(
            child: _SettingsCard(child: _ApiBaseUrlEditor()),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Developer ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(text: l10n.settingsSectionDeveloper),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.science_outlined, color: cs.primary),
                title: Text(
                  l10n.settingsAiPlaygroundTileTitle,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.settingsAiPlaygroundTileSubtitle,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/ai-playground'),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── About ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(text: l10n.settingsSectionAbout),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(t.radiusMd),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: cs.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: t.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.settingsAboutSubtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space32)),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space8, t.space24, t.space8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Rounded card wrapping settings rows — iOS-style grouped card.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(t.radiusXl),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(t.space16),
          child: child,
        ),
      ),
    );
  }
}

// ── API URL editor ────────────────────────────────────────────────────────────

class _ApiBaseUrlEditor extends ConsumerStatefulWidget {
  const _ApiBaseUrlEditor();

  @override
  ConsumerState<_ApiBaseUrlEditor> createState() => _ApiBaseUrlEditorState();
}

class _ApiBaseUrlEditorState extends ConsumerState<_ApiBaseUrlEditor> {
  late final TextEditingController _controller;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = await ref.read(apiBaseUrlProvider.future);
      if (mounted) {
        _controller.text = url;
        setState(() => _loaded = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(
            labelText: l10n.settingsApiBaseUrl,
            hintText: l10n.settingsApiBaseUrlHint,
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        SizedBox(height: t.space12),
        FilledButton(
          onPressed:
              (!_loaded || _saving)
                  ? null
                  : () async {
                    setState(() => _saving = true);
                    try {
                      await ref
                          .read(apiBaseUrlProvider.notifier)
                          .setBaseUrl(_controller.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsApiBaseUrlSave)),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
          child:
              _saving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(l10n.settingsApiBaseUrlSave),
        ),
        SizedBox(height: t.space4),
        Text(
          l10n.settingsApiBaseUrlHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
