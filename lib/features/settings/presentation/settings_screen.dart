/// Settings — editorial grouped iOS-style cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/guest_migration_providers.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_settings_section.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final ScrollController _scrollController;
  final GlobalKey _keyboardSectionKey = GlobalKey();
  String? _lastKeyboardScrollUri;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isDesktop) return;
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['section'] != 'keyboard') {
      _lastKeyboardScrollUri = null;
      return;
    }
    final full = uri.toString();
    if (_lastKeyboardScrollUri == full) return;
    _lastKeyboardScrollUri = full;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _keyboardSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: EnjoyThemeTokens.of(context).motionStandard,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.contentMaxWidth + 96),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: EditorialHeader(
                  title: l10n.settingsTitle,
                  subtitle: l10n.settingsSubtitle,
                ),
              ),

              // ── Account section ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SettingsSectionHeader(
                  title: l10n.settingsSectionAccount,
                  hint: l10n.settingsSectionAccountHint,
                  icon: Icons.person_outline_rounded,
                ),
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
                            return _SettingsTile(
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
                              title: state.profile.name,
                              subtitle: state.profile.email,
                              onTap: () => context.push('/profile'),
                            );
                          }
                          return _SettingsTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.surfaceContainerHighest,
                              radius: 20,
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            title: l10n.settingsAccountSignIn,
                            subtitle: l10n.settingsAccountSignedOut,
                            onTap: () => context.push('/sign-in'),
                          );
                        },
                        loading: () => _SettingsTile(
                          leading: Skeleton.circle(diameter: 40),
                          title: l10n.loading,
                          showChevron: false,
                        ),
                        error: (Object e, StackTrace s) =>
                            const SizedBox.shrink(),
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
                  final migration = ref.watch(guestMigrationCtrlProvider);
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SettingsSectionHeader(
                          title: l10n.settingsSectionDataMigration,
                          hint: l10n.settingsSectionDataMigrationHint,
                          icon: Icons.folder_shared_outlined,
                        ),
                        _SettingsCard(
                          padding: EdgeInsets.zero,
                          child: _SettingsTile(
                            leadingIcon: Icons.move_to_inbox_rounded,
                            title: l10n.settingsMigrationTitle,
                            subtitle: l10n.settingsMigrationSubtitle,
                            showChevron: !migration.isLoading,
                            trailing: migration.isLoading
                                ? Skeleton.circle(diameter: 24)
                                : null,
                            onTap: migration.isLoading
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
                                        AppNotice.success(
                                          context,
                                          l10n.migrationSuccess,
                                        );
                                      },
                                      error: (Object e, StackTrace st) {
                                        AppNotice.error(
                                          context,
                                          l10n.migrationMigrationFailed,
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
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionSync,
              hint: l10n.settingsSectionSyncHint,
              icon: Icons.cloud_sync_outlined,
            ),
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
                            final subtitle = snap.isFullyCaughtUp
                                ? l10n.syncSettingsTileSubtitleUpToDate
                                : l10n.syncSettingsTileSubtitleCounts(
                                    snap.retryablePending,
                                    snap.permanentlyFailed,
                                  );
                            return _SettingsTile(
                              leadingIcon: Icons.cloud_sync_outlined,
                              title: l10n.syncSettingsTileTitle,
                              subtitle: subtitle,
                              onTap: () => context.push('/settings/sync'),
                            );
                          },
                          loading: () => _SettingsTile(
                            leadingIcon: Icons.cloud_sync_outlined,
                            title: l10n.syncSettingsTileTitle,
                            subtitle: l10n.loading,
                            onTap: () => context.push('/settings/sync'),
                          ),
                          error: (Object e, StackTrace s) => _SettingsTile(
                            leadingIcon: Icons.cloud_sync_outlined,
                            leadingIconTint: cs.error,
                            title: l10n.syncSettingsTileTitle,
                            subtitle: '$e',
                            onTap: () => context.push('/settings/sync'),
                          ),
                        );
                      }
                      return _SettingsTile(
                        leadingIcon: Icons.cloud_off_outlined,
                        leadingIconTint: cs.onSurfaceVariant,
                        title: l10n.syncSettingsTileTitle,
                        subtitle: l10n.syncSettingsTileSubtitleSignedOut,
                        onTap: () => context.push('/settings/sync'),
                      );
                    },
                    loading: () => _SettingsTile(
                      leading: Skeleton.circle(diameter: 40),
                      title: l10n.syncSettingsTileTitle,
                      showChevron: false,
                    ),
                    error: (Object e, StackTrace s) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Appearance & Language ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionAppearanceLanguage,
              hint: l10n.settingsSectionAppearanceLanguageHint,
              icon: Icons.palette_outlined,
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: Consumer(
                builder: (context, ref, _) {
                  final prefs = ref.watch(appPreferencesCtrlProvider);
                  return prefs.when(
                    data: (state) {
                      final displayLang =
                          state.locale?.toLanguageTag() ?? 'en';
                      final learn = state.learningLanguage ?? '—';
                      final native = state.nativeLanguage ?? '—';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Tooltip(
                            message: l10n.settingsAppearanceSyncedFromProfile,
                            child: _SettingsTile(
                              leading: Container(
                                width: 36,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(t.radiusSm),
                                  gradient: LinearGradient(
                                    colors: [
                                      t.gradientStart,
                                      t.gradientEnd,
                                    ],
                                  ),
                                ),
                              ),
                              title: l10n.settingsAppearanceTheme,
                              subtitle: l10n.settingsAppearanceThemeValue,
                              showChevron: false,
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                          Tooltip(
                            message: l10n.settingsAppearanceSyncedFromProfile,
                            child: _SettingsTile(
                              leadingIcon: Icons.language_rounded,
                              title: l10n.settingsAppearanceDisplayLanguage,
                              subtitle: displayLang,
                              showChevron: false,
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                          Tooltip(
                            message: l10n.settingsAppearanceSyncedFromProfile,
                            child: _SettingsTile(
                              leadingIcon: Icons.translate_rounded,
                              title: l10n.settingsAppearanceLearningLanguage,
                              subtitle: learn,
                              showChevron: false,
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                          Tooltip(
                            message: l10n.settingsAppearanceSyncedFromProfile,
                            child: _SettingsTile(
                              leadingIcon: Icons.record_voice_over_outlined,
                              title: l10n.settingsAppearanceNativeLanguage,
                              subtitle: native,
                              showChevron: false,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Skeleton.line(width: double.infinity, height: 18),
                          const SizedBox(height: 16),
                          Skeleton.line(width: 220, height: 14),
                          const SizedBox(height: 12),
                          Skeleton.line(width: 180, height: 14),
                        ],
                      ),
                    ),
                    error: (e, s) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Keyboard shortcuts (desktop only) ─────────────────────────
          if (isDesktop) ...[
            SliverToBoxAdapter(
              child: _SettingsSectionHeader(
                title: l10n.hotkeysSectionKeyboard,
                hint: l10n.hotkeysSectionKeyboardHint,
                icon: Icons.keyboard_outlined,
              ),
            ),
            SliverToBoxAdapter(
              child: _SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  key: _keyboardSectionKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        ref.watch(hotkeysCtrlProvider);
                        final keys = ref
                            .read(hotkeysCtrlProvider.notifier)
                            .effectiveKeys('global.help');
                        return _SettingsTile(
                          leadingIcon: Icons.help_outline_rounded,
                          title: l10n.settingsKeyboardOpenCheatsheet,
                          subtitle:
                              l10n.settingsKeyboardOpenCheatsheetSubtitle,
                          trailing: KbdChordRow(
                            binding: keys,
                            compact: true,
                          ),
                          showChevron: false,
                          onTap: () => showHotkeysHelpDialog(context),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: HotkeysSettingsSection(),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: t.space8)),
          ],

          // ── Advanced ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionAdvanced,
              hint: l10n.settingsSectionAdvancedHint,
              icon: Icons.tune_rounded,
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: t.space16,
                        vertical: t.space4,
                      ),
                      childrenPadding: EdgeInsets.fromLTRB(
                        t.space16,
                        0,
                        t.space16,
                        t.space16,
                      ),
                      leading: Icon(
                        Icons.dns_outlined,
                        color: cs.primary,
                      ),
                      title: Text(
                        l10n.settingsApiBaseUrl,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.settingsApiBaseUrlHint,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      children: const [_ApiBaseUrlEditor()],
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: t.space16,
                    endIndent: t.space16,
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: t.space16,
                        vertical: t.space4,
                      ),
                      childrenPadding: EdgeInsets.fromLTRB(
                        t.space16,
                        0,
                        t.space16,
                        t.space16,
                      ),
                      leading: Icon(
                        Icons.smart_toy_outlined,
                        color: cs.primary,
                      ),
                      title: Text(
                        l10n.settingsAiApiBaseUrl,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        l10n.settingsAiApiBaseUrlHint,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      children: const [_AiApiBaseUrlEditor()],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── Developer ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionDeveloper,
              hint: l10n.settingsSectionDeveloperHint,
              icon: Icons.developer_mode_outlined,
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: _SettingsTile(
                leadingIcon: Icons.science_outlined,
                title: l10n.settingsAiPlaygroundTileTitle,
                subtitle: l10n.settingsAiPlaygroundTileSubtitle,
                onTap: () => context.push('/settings/ai-playground'),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: t.space8)),

          // ── About ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionAbout,
              hint: l10n.settingsSectionAboutHint,
              icon: Icons.info_outline_rounded,
            ),
          ),
          SliverToBoxAdapter(
            child: _SettingsCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        SizedBox(height: t.space4),
                        Text(
                          l10n.settingsAboutSubtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: t.space8),
                        Text(
                          l10n.settingsAboutMadeWithCare,
                          style: tt.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
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
    ),
  ),
);
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.leadingIconTint,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? leadingIcon;
  final Color? leadingIconTint;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Widget? leadWidget;
    if (leading != null) {
      leadWidget = leading;
    } else if (leadingIcon != null) {
      leadWidget = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(t.radiusSm),
        ),
        child: Icon(
          leadingIcon,
          color: leadingIconTint ?? cs.primary,
          size: 20,
        ),
      );
    } else {
      leadWidget = null;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : Haptics.wrapTap(context, onTap!),
        borderRadius: BorderRadius.circular(t.radiusLg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space12,
              vertical: t.space8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leadWidget != null) ...[
                  leadWidget,
                  SizedBox(width: t.space12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        SizedBox(height: t.space4),
                        Text(
                          subtitle!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (showChevron && onTap != null) ...[
                  SizedBox(width: t.space4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space12, t.space24, t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: cs.primary),
          SizedBox(width: t.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: t.space4),
                Text(
                  hint,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: EnjoyCard(
        padding: padding ?? EdgeInsets.all(t.space16),
        child: child,
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
                        AppNotice.success(
                          context,
                          l10n.settingsApiBaseUrlSave,
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

class _AiApiBaseUrlEditor extends ConsumerStatefulWidget {
  const _AiApiBaseUrlEditor();

  @override
  ConsumerState<_AiApiBaseUrlEditor> createState() =>
      _AiApiBaseUrlEditorState();
}

class _AiApiBaseUrlEditorState extends ConsumerState<_AiApiBaseUrlEditor> {
  late final TextEditingController _controller;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = await ref.read(aiApiBaseUrlProvider.future);
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
            labelText: l10n.settingsAiApiBaseUrl,
            hintText: l10n.settingsAiApiBaseUrlHint,
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
                          .read(aiApiBaseUrlProvider.notifier)
                          .setBaseUrl(_controller.text);
                      if (context.mounted) {
                        AppNotice.success(
                          context,
                          l10n.settingsAiApiBaseUrlSave,
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
                  : Text(l10n.settingsAiApiBaseUrlSave),
        ),
        SizedBox(height: t.space4),
        Text(
          l10n.settingsAiApiBaseUrlHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
