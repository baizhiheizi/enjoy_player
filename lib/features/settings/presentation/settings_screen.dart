/// Settings — editorial grouped iOS-style cards.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/centered_max_width_scroll.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/guest_migration_providers.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_ctrl.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/hotkeys/presentation/widgets/kbd_chip.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/about_section_card.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/language_choice_sheet.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final contentMaxWidth = t.contentMaxWidth + 96;

    return Scaffold(
      body: CenteredMaxWidthScrollView(
        maxWidth: contentMaxWidth,
        slivers: [
          SliverToBoxAdapter(
            child: EditorialHeader(
              title: l10n.settingsTitle,
              subtitle: l10n.settingsSubtitle,
            ),
          ),

          // ── Account hero ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: t.space8),
              child: Consumer(
                builder: (context, ref, _) {
                  final auth = ref.watch(authCtrlProvider);
                  return auth.when(
                    data: (state) {
                      if (state is AuthSignedIn) {
                        final avatarUrl = state.profile.avatarUrl;
                        final hasAvatar =
                            avatarUrl != null && avatarUrl.isNotEmpty;
                        return _AccountHeroCard(
                          sectionLabel: l10n.settingsSectionAccount,
                          sectionHint: l10n.settingsSectionAccountHint,
                          name: state.profile.name,
                          email: state.profile.email,
                          signedIn: true,
                          primaryActionLabel: l10n.settingsAccountOpenProfile,
                          onPrimaryAction: () => context.push('/profile'),
                          avatar: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            radius: 28,
                            backgroundImage: hasAvatar
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                            child: hasAvatar
                                ? null
                                : Text(
                                    (state.profile.name.isNotEmpty
                                            ? state.profile.name[0]
                                            : '?')
                                        .toUpperCase(),
                                    style: tt.titleLarge?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      }
                      return _AccountHeroCard(
                        sectionLabel: l10n.settingsSectionAccount,
                        sectionHint: l10n.settingsSectionAccountHint,
                        name: l10n.settingsAccountSignIn,
                        email: l10n.settingsAccountSignedOut,
                        signedIn: false,
                        primaryActionLabel: l10n.settingsAccountSignIn,
                        onPrimaryAction: () => context.push('/sign-in'),
                        avatar: CircleAvatar(
                          backgroundColor: cs.surfaceContainerHighest
                              .withValues(alpha: 0.9),
                          radius: 28,
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 32,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                    loading: () => const _AccountHeroSkeleton(),
                    error: (Object e, StackTrace s) => Padding(
                      padding: EdgeInsets.fromLTRB(
                        t.space24,
                        0,
                        t.space24,
                        t.space8,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(t.radiusLg),
                          border: Border.all(
                            color: cs.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(t.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.settingsAuthLoadFailed,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: t.space12),
                              FilledButton.tonal(
                                onPressed: () =>
                                    ref.invalidate(authCtrlProvider),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (Object error, StackTrace stackTrace) =>
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
                            return _SettingsTile(
                              leadingIcon: Icons.cloud_sync_outlined,
                              title: l10n.syncSettingsTileTitle,
                              subtitle: l10n.settingsSectionSyncHint,
                              valueBadge: _SyncQueueStatusPill(
                                snapshot: snap,
                                l10n: l10n,
                              ),
                              onTap: () => context.push('/settings/sync'),
                            );
                          },
                          loading: () => _SettingsTile(
                            leadingIcon: Icons.cloud_sync_outlined,
                            title: l10n.syncSettingsTileTitle,
                            subtitle: l10n.loading,
                            valueBadge: Skeleton.line(
                              width: 100,
                              height: 26,
                              borderRadius: BorderRadius.circular(t.radiusFull),
                            ),
                            onTap: () => context.push('/settings/sync'),
                          ),
                          error: (Object e, StackTrace s) => _SettingsTile(
                            leadingIcon: Icons.cloud_sync_outlined,
                            leadingIconTint: cs.error,
                            title: l10n.syncSettingsTileTitle,
                            subtitle: l10n.error,
                            valueBadge: _SettingsValuePill(
                              icon: Icons.error_outline_rounded,
                              label: l10n.error,
                              foregroundColor: cs.error,
                            ),
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
                      leading: Skeleton.circle(diameter: 48),
                      title: l10n.syncSettingsTileTitle,
                      showChevron: false,
                    ),
                    error: (Object e, StackTrace s) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: t.space24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(t.radiusLg),
                          border: Border.all(
                            color: cs.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(t.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.settingsAuthLoadFailed,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: t.space12),
                              FilledButton.tonal(
                                onPressed: () =>
                                    ref.invalidate(authCtrlProvider),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                  final auth = ref.watch(authCtrlProvider);
                  final signedIn = auth.maybeWhen(
                    data: (s) => s is AuthSignedIn,
                    orElse: () => false,
                  );
                  final langSubtitle = signedIn
                      ? l10n.settingsLanguageSubtitleSignedIn
                      : l10n.settingsLanguageSubtitleDeviceOnly;
                  return prefs.when(
                    data: (state) {
                      final displayLang = localeToBcp47(
                        state.effectiveDisplayLocale,
                      );
                      final learn = state.effectiveLearningLanguage;
                      final native = state.effectiveNativeLanguage;
                      final nativeChoices = allowedNativeTags(
                        kDefaultLearningLanguageTag,
                      );
                      String labelForTag(String tag) {
                        if (tagsEqual(tag, 'en-US')) {
                          return l10n.settingsLanguageOptionEnUs;
                        }
                        return l10n.settingsLanguageOptionZhCn;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SettingsTile(
                            leadingIcon: Icons.language_rounded,
                            title: l10n.settingsAppearanceDisplayLanguage,
                            subtitle: langSubtitle,
                            valueBadge: _SettingsValuePill(
                              label: labelForTag(displayLang),
                            ),
                            showChevron: true,
                            onTap: () async {
                              final opts = <LanguageChoiceOption>[
                                for (final loc in kAppDisplayLocales)
                                  LanguageChoiceOption(
                                    value: localeToBcp47(loc),
                                    label: labelForTag(localeToBcp47(loc)),
                                  ),
                              ];
                              final picked = await showLanguageChoiceSheet(
                                context: context,
                                title: l10n.settingsLanguagePickerTitleDisplay,
                                options: opts,
                                selectedValue: displayLang,
                              );
                              if (picked == null || !context.mounted) {
                                return;
                              }
                              await ref
                                  .read(appPreferencesCtrlProvider.notifier)
                                  .setLocale(
                                    displayLocaleFromRawOrDefault(picked),
                                  );
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsTile(
                            leadingIcon: Icons.translate_rounded,
                            title: l10n.settingsAppearanceLearningLanguage,
                            subtitle:
                                l10n.settingsLearningLanguageFixedSubtitle,
                            valueBadge: _SettingsValuePill(label: learn),
                            showChevron: false,
                          ),
                          const _SettingsDivider(),
                          _SettingsTile(
                            leadingIcon: Icons.record_voice_over_outlined,
                            title: l10n.settingsAppearanceNativeLanguage,
                            subtitle: langSubtitle,
                            valueBadge: _SettingsValuePill(
                              label: labelForTag(native),
                            ),
                            showChevron: nativeChoices.length > 1,
                            onTap: nativeChoices.length > 1
                                ? () async {
                                    final opts = <LanguageChoiceOption>[
                                      for (final tag in nativeChoices)
                                        LanguageChoiceOption(
                                          value: tag,
                                          label: labelForTag(tag),
                                        ),
                                    ];
                                    final picked = await showLanguageChoiceSheet(
                                      context: context,
                                      title: l10n
                                          .settingsLanguagePickerTitleNative,
                                      options: opts,
                                      selectedValue: native,
                                    );
                                    if (picked == null || !context.mounted) {
                                      return;
                                    }
                                    await ref
                                        .read(
                                          appPreferencesCtrlProvider.notifier,
                                        )
                                        .setNativeLanguage(picked);
                                  }
                                : null,
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

          // ── Recording (microphone) ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionRecording,
              hint: l10n.settingsSectionRecordingHint,
              icon: Icons.mic_none_rounded,
            ),
          ),
          const SliverToBoxAdapter(
            child: _SettingsCard(
              padding: EdgeInsets.zero,
              child: _RecordingMicTile(),
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
                          subtitle: l10n.settingsKeyboardOpenCheatsheetSubtitle,
                          trailing: KbdChordRow(binding: keys, compact: true),
                          showChevron: false,
                          onTap: () => showHotkeysHelpDialog(context),
                        );
                      },
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      leadingIcon: Icons.tune_rounded,
                      title: l10n.settingsKeyboardCustomizeTitle,
                      subtitle: l10n.hotkeysSectionKeyboardHint,
                      onTap: () => context.push('/settings/keyboard'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: t.space8)),
          ],

          // ── Developer (debug / profile only) ───────────────────────────
          if (!kReleaseMode) ...[
            SliverToBoxAdapter(
              child: _SettingsSectionHeader(
                title: l10n.settingsSectionDeveloper,
                hint: l10n.settingsSectionDeveloperHint,
                icon: Icons.developer_mode_outlined,
                subdued: true,
              ),
            ),
            SliverToBoxAdapter(
              child: _SettingsSubduedCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: t.space16,
                          vertical: t.space8,
                        ),
                        childrenPadding: EdgeInsets.fromLTRB(
                          t.space16,
                          t.space16,
                          t.space16,
                          t.space16,
                        ),
                        leading: const _SettingsExpansionLeading(
                          icon: Icons.dns_outlined,
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
                    const _SettingsDivider(insetForLeading: false),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: t.space16,
                          vertical: t.space8,
                        ),
                        childrenPadding: EdgeInsets.fromLTRB(
                          t.space16,
                          t.space16,
                          t.space16,
                          t.space16,
                        ),
                        leading: const _SettingsExpansionLeading(
                          icon: Icons.smart_toy_outlined,
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
                    const _SettingsDivider(insetForLeading: false),
                    _SettingsTile(
                      leadingIcon: Icons.science_outlined,
                      title: l10n.settingsAiPlaygroundTileTitle,
                      subtitle: l10n.settingsAiPlaygroundTileSubtitle,
                      onTap: () => context.push('/settings/ai-playground'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: t.space8)),
          ],

          // ── About ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSectionHeader(
              title: l10n.settingsSectionAbout,
              hint: l10n.settingsSectionAboutHint,
              icon: Icons.info_outline_rounded,
            ),
          ),
          const SliverToBoxAdapter(child: AboutSectionCard()),

          SliverToBoxAdapter(child: SizedBox(height: t.space32)),
        ],
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
    this.valueBadge,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? leadingIcon;
  final Color? leadingIconTint;
  final Widget? valueBadge;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final interactive = onTap != null;
    final iconTint = leadingIconTint ?? cs.primary;

    final Widget? leadWidget;
    if (leading != null) {
      leadWidget = SizedBox(
        width: 44,
        height: 44,
        child: Center(child: leading!),
      );
    } else if (leadingIcon != null) {
      leadWidget = SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(
            leadingIcon,
            color: iconTint.withValues(alpha: interactive ? 0.92 : 0.6),
            size: 24,
          ),
        ),
      );
    } else {
      leadWidget = null;
    }

    Widget disclosure() {
      return Icon(
        Icons.chevron_right_rounded,
        color: cs.onSurfaceVariant.withValues(alpha: 0.55),
        size: 20,
      );
    }

    List<Widget> trailingWidgets() {
      final widgets = <Widget>[];
      if (valueBadge != null) {
        widgets.add(valueBadge!);
      }
      if (trailing != null) {
        widgets.add(trailing!);
      }
      if (showChevron && onTap != null) {
        widgets.add(disclosure());
      }
      return widgets;
    }

    Widget textColumn({required bool compact}) {
      final trailingChildren = trailingWidgets();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: interactive
                          ? null
                          : cs.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                if (trailingChildren.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < trailingChildren.length; i++) ...[
                        if (i > 0) SizedBox(width: t.space12),
                        trailingChildren[i],
                      ],
                    ],
                  ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: interactive
                          ? null
                          : cs.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: t.space4),
            Text(
              subtitle!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.86),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (compact && trailingChildren.isNotEmpty) ...[
            SizedBox(height: t.space8),
            Wrap(
              spacing: t.space8,
              runSpacing: t.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: trailingChildren,
            ),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap == null ? null : Haptics.wrapTap(context, onTap!),
            borderRadius: BorderRadius.circular(t.radiusXl),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return cs.primary.withValues(alpha: 0.08);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return cs.onSurface.withValues(alpha: 0.045);
              }
              return null;
            }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.space20,
                  vertical: t.space12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leadWidget != null) ...[
                      leadWidget,
                      SizedBox(width: t.space16),
                    ],
                    Expanded(child: textColumn(compact: compact)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({this.insetForLeading = true});

  final bool insetForLeading;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: insetForLeading ? t.space20 + 44 + t.space16 : t.space20,
      endIndent: t.space20,
      color: cs.outlineVariant.withValues(alpha: 0.18),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.title,
    required this.hint,
    required this.icon,
    this.subdued = false,
  });

  final String title;
  final String hint;
  final IconData icon;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final iconFg = subdued ? cs.onSurfaceVariant : cs.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(t.space24, t.space16, t.space24, t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, size: 20, color: iconFg),
            ),
          ),
          SizedBox(width: t.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: subdued
                        ? cs.onSurface.withValues(alpha: 0.92)
                        : null,
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  hint,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(
                      alpha: subdued ? 0.75 : 0.9,
                    ),
                    height: 1.4,
                  ),
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: Material(
        color: cs.surfaceContainerLow.withValues(alpha: 0.88),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceContainerHigh.withValues(alpha: 0.38),
                cs.surfaceContainerLow.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(t.space16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Lower-emphasis surface for advanced / developer tools.
class _SettingsSubduedCard extends StatelessWidget {
  const _SettingsSubduedCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: Material(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.88),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusLg),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? EdgeInsets.all(t.space16),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsExpansionLeading extends StatelessWidget {
  const _SettingsExpansionLeading({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(child: Icon(icon, color: cs.onSurfaceVariant, size: 22)),
    );
  }
}

class _SettingsValuePill extends StatelessWidget {
  const _SettingsValuePill({
    this.icon,
    required this.label,
    this.foregroundColor,
  });

  final IconData? icon;
  final String label;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = foregroundColor ?? cs.onSurfaceVariant;

    Widget? leading;
    if (icon != null) {
      leading = Icon(icon, size: 16, color: fg);
    } else if (foregroundColor != null) {
      leading = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: foregroundColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 148, minHeight: 30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, SizedBox(width: t.space4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: leading != null ? TextAlign.start : TextAlign.end,
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncQueueStatusPill extends StatelessWidget {
  const _SyncQueueStatusPill({required this.snapshot, required this.l10n});

  final SyncQueueSnapshot snapshot;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (snapshot.isFullyCaughtUp) {
      return _SettingsValuePill(
        icon: Icons.check_circle_outline_rounded,
        label: l10n.syncSettingsTileSubtitleUpToDate,
        foregroundColor: cs.primary,
      );
    }
    final hasFailed = snapshot.permanentlyFailed > 0;
    return _SettingsValuePill(
      icon: hasFailed
          ? Icons.warning_amber_rounded
          : Icons.hourglass_empty_rounded,
      label: l10n.syncSettingsTileSubtitleCounts(
        snapshot.retryablePending,
        snapshot.permanentlyFailed,
      ),
      foregroundColor: hasFailed ? cs.error : cs.onSurface,
    );
  }
}

class _AccountHeroCard extends StatelessWidget {
  const _AccountHeroCard({
    required this.sectionLabel,
    required this.sectionHint,
    required this.name,
    required this.email,
    required this.signedIn,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.avatar,
  });

  final String sectionLabel;
  final String sectionHint;
  final String name;
  final String email;
  final bool signedIn;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusXl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                t.gradientStart.withValues(alpha: 0.94),
                t.gradientEnd.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sectionLabel.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    letterSpacing: 1.05,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  sectionHint,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: t.space16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    SizedBox(width: t.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.35,
                              color: cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: t.space8),
                          Text(
                            email,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.82),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: t.space20),
                EnjoyButton.secondary(
                  onPressed: onPrimaryAction,
                  icon: signedIn
                      ? Icons.manage_accounts_outlined
                      : Icons.login_rounded,
                  child: Text(primaryActionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountHeroSkeleton extends StatelessWidget {
  const _AccountHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusXl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - t.space32;
            return Skeleton.box(
              width: w,
              height: 188,
              borderRadius: BorderRadius.circular(t.radiusXl),
            );
          },
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(hintText: l10n.settingsApiBaseUrlHint),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        SizedBox(height: t.space12),
        FilledButton(
          onPressed: (!_loaded || _saving)
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await ref
                        .read(apiBaseUrlProvider.notifier)
                        .setBaseUrl(_controller.text);
                    if (context.mounted) {
                      AppNotice.success(context, l10n.settingsApiBaseUrlSave);
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.settingsApiBaseUrlSave),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(hintText: l10n.settingsAiApiBaseUrlHint),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        SizedBox(height: t.space12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: (!_loaded || _saving)
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
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.settingsAiApiBaseUrlSave),
              ),
            ),
            SizedBox(width: t.space8),
            Expanded(
              child: OutlinedButton(
                onPressed: (!_loaded || _saving)
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(aiApiBaseUrlProvider.notifier)
                              .clearOverride();
                          final url = await ref
                              .read(aiApiBaseUrlProvider.future);
                          if (mounted) {
                            _controller.text = url;
                          }
                          if (context.mounted) {
                            AppNotice.success(
                              context,
                              l10n.settingsAiApiBaseUrlCleared,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(l10n.settingsAiApiBaseUrlUseDefault),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Recording microphone tile ──────────────────────────────────────────────

class _RecordingMicTile extends ConsumerWidget {
  const _RecordingMicTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(recordingInputDeviceCtrlProvider).valueOrNull;
    final selected = state?.selectedDevice;
    final autoPicked = state?.autoPicked ?? true;

    final String subtitle;
    if (state == null || state.devices.isEmpty) {
      subtitle = l10n.settingsRecordingMicEmpty;
    } else if (autoPicked) {
      subtitle = selected != null
          ? l10n.settingsRecordingMicAuto(selected.label)
          : l10n.settingsRecordingMicAutoNoDevice;
    } else {
      subtitle = selected?.label ?? l10n.settingsRecordingMicEmpty;
    }

    return _SettingsTile(
      leadingIcon: Icons.mic_none_rounded,
      title: l10n.settingsRecordingMicTitle,
      subtitle: subtitle,
      onTap: () async {
        await ref.read(recordingInputDeviceCtrlProvider.notifier).refresh();
        if (!context.mounted) return;
        await _showRecordingMicPicker(context, ref);
      },
    );
  }
}

Future<void> _showRecordingMicPicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final state = ref.read(recordingInputDeviceCtrlProvider).valueOrNull;
  final devices = state?.devices ?? const [];
  final selectedId = state?.selectedId;
  final autoPicked = state?.autoPicked ?? true;

  // The dialog applies the choice itself (via the controller) and then pops.
  // Barrier-dismiss is a no-op, no need to disambiguate the result.
  final groupValue = autoPicked ? null : selectedId;
  await showEnjoyDialog<void>(
    context: context,
    builder: (dialogCtx) {
      final t = EnjoyThemeTokens.of(dialogCtx);
      final mq = MediaQuery.sizeOf(dialogCtx);

      Future<void> apply(String? deviceId) async {
        await ref
            .read(recordingInputDeviceCtrlProvider.notifier)
            .selectDeviceId(deviceId);
        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
      }

      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.modalMaxWidthLarge),
          child: Padding(
            padding: EdgeInsets.all(t.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.settingsRecordingMicDialogTitle,
                  style: Theme.of(
                    dialogCtx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: t.space16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: mq.height * 0.5),
                  child: SingleChildScrollView(
                    child: RadioGroup<String?>(
                      groupValue: groupValue,
                      onChanged: apply,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String?>(
                            value: null,
                            title: Text(l10n.settingsRecordingMicAutoOption),
                          ),
                          if (devices.isEmpty)
                            ListTile(
                              enabled: false,
                              title: Text(l10n.settingsRecordingMicEmpty),
                            )
                          else
                            for (final d in devices)
                              RadioListTile<String?>(
                                value: d.id,
                                title: Text(
                                  d.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
