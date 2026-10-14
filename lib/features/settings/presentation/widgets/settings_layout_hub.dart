/// Phone Settings hub (below the rail breakpoint) — the `Settings` board's
/// `st-narrow` layout: account card, one grouped card of section rows, and
/// the mono version footer. Search keeps the flat single-column stack, where
/// every section renders inline so matches stay visible in place.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/subscription_tier_label.dart';
import 'package:enjoy_player/features/settings/application/settings_search_query_provider.dart';
import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_spec.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/account_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/appearance_language_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/cloud_sync_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_layout_single_column.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/shadow_reading/application/recording_input_device_controller.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsLayoutHub extends ConsumerWidget {
  const SettingsLayoutHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(settingsSearchQueryProvider);
    if (query.trim().isNotEmpty) {
      return const SettingsLayoutSingleColumn();
    }

    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sections = visibleSettingsSections(l10n, '');
    final hubSections = sections
        .where((spec) => spec.sectionId != SettingsSectionIds.account)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sections.any(
          (spec) => spec.sectionId == SettingsSectionIds.account,
        ))
          const _AccountEntry(),
        SizedBox(height: t.space16),
        if (hubSections.isNotEmpty)
          EnjoyCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < hubSections.length; i++) ...[
                  _HubSectionRow(spec: hubSections[i]),
                  if (i < hubSections.length - 1) const SettingsRowDivider(),
                ],
              ],
            ),
          ),
        SizedBox(height: t.space20),
        const _VersionFooter(),
        SizedBox(height: t.space32),
      ],
    );
  }
}

class _AccountEntry extends ConsumerWidget {
  const _AccountEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) return const AccountSection();
    return _AccountCard(profile: auth.profile);
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final tier = subscriptionTierLabel(l10n, ref.watch(currentTierProvider));

    return EnjoyPressable(
      onTap: () => context.go('/profile'),
      borderRadius: BorderRadius.circular(t.radiusCard),
      child: EnjoyCard(
        padding: EdgeInsets.all(t.space16),
        child: Row(
          children: [
            AccountAvatar(name: profile.name),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$tier · ${profile.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(EnjoyIcons.chevronRight, size: 16, color: t.ink3),
          ],
        ),
      ),
    );
  }
}

class _HubSectionRow extends ConsumerWidget {
  const _HubSectionRow({required this.spec});

  final SettingsSectionSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final value = _value(ref, l10n);

    return SettingsRow(
      leadingIcon: spec.icon,
      leadingIconTone: switch (spec.sectionId) {
        SettingsSectionIds.cloudSync => EnjoyIconTileTone.original,
        SettingsSectionIds.aiProviders => EnjoyIconTileTone.brand,
        _ => EnjoyIconTileTone.neutral,
      },
      title: spec.title(l10n),
      trailing: value == null
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kSettingsRowValueTextMaxWidth,
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
              ),
            ),
      onTap: () => context.push(_routeFor(spec.sectionId)),
    );
  }

  String? _value(WidgetRef ref, AppLocalizations l10n) {
    switch (spec.sectionId) {
      case SettingsSectionIds.cloudSync:
        final auth = ref.watch(authCtrlProvider).valueOrNull;
        if (auth is! AuthSignedIn) return null;
        final snapshot = ref.watch(syncQueueSnapshotProvider).valueOrNull;
        if (snapshot == null) return null;
        return SyncQueueStatusPill(
          retryablePending: snapshot.retryablePending,
          permanentlyFailed: snapshot.permanentlyFailed,
          l10n: l10n,
        ).label;
      case SettingsSectionIds.appearanceLanguage:
        final prefs = ref.watch(appPreferencesCtrlProvider).valueOrNull;
        if (prefs == null) return null;
        return appearanceThemeModeLabel(l10n, prefs.themeMode);
      case SettingsSectionIds.aiProviders:
        final configs = ref.watch(aiModalityConfigCtrlProvider);
        final byok = [
          configs.asr,
          configs.tts,
          configs.llm,
          configs.translation,
          configs.dictionary,
          configs.assessment,
        ].any((config) => config.provider == AIProvider.byok);
        return byok
            ? l10n.settingsAiProvidersByok
            : l10n.settingsAiProvidersEnjoyAi;
      case SettingsSectionIds.recording:
        final state = ref.watch(recordingInputDeviceCtrlProvider).valueOrNull;
        if (state == null) return null;
        if (state.autoPicked) return l10n.settingsRecordingMicAutoShort;
        return state.selectedDevice?.label;
      case SettingsSectionIds.about:
        return ref.watch(_packageInfoProvider).valueOrNull?.version;
      case _:
        return null;
    }
  }

  String _routeFor(String sectionId) {
    return switch (sectionId) {
      SettingsSectionIds.cloudSync => '/settings/sync',
      SettingsSectionIds.appearanceLanguage => '/settings/appearance-language',
      SettingsSectionIds.aiProviders => '/settings/ai-providers',
      SettingsSectionIds.recording => '/settings/recording',
      SettingsSectionIds.keyboardShortcuts => '/settings/keyboard',
      SettingsSectionIds.developer => '/settings/developer',
      SettingsSectionIds.about => '/settings/about',
      _ => '/settings',
    };
  }
}

class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final info = ref.watch(_packageInfoProvider).valueOrNull;

    return Text.rich(
      TextSpan(
        text: l10n.appTitle,
        children: [
          if (info != null)
            TextSpan(
              text: ' ${info.version} (${info.buildNumber})',
              style: enjoyMonoStyle(context, size: 12.5, color: t.ink3),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12.5, color: t.ink3),
    );
  }
}
