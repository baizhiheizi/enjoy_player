/// Settings hub — searchable, single-column on mobile, two-pane on desktop.
///
/// See specs/004-settings-redesign/ for the redesign spec/plan. Section
/// content lives in `widgets/sections/*.dart`; layout composition lives in
/// `widgets/settings_layout_single_column.dart` and
/// `widgets/settings_layout_two_pane.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/centered_max_width_scroll.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_layout_single_column.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_layout_two_pane.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_search_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final contentMaxWidth = t.contentMaxWidth + 96;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final twoPane = constraints.maxWidth >= t.breakpointRail;
          return CenteredMaxWidthScrollView(
            maxWidth: twoPane ? contentMaxWidth + t.sidebarWidth : contentMaxWidth,
            slivers: [
              SliverToBoxAdapter(
                child: EditorialHeader(
                  title: l10n.settingsTitle,
                  subtitle: l10n.settingsSubtitle,
                ),
              ),
              const SliverToBoxAdapter(child: SettingsSearchField()),
              SliverToBoxAdapter(
                child: twoPane
                    ? const SettingsLayoutTwoPane()
                    : const SettingsLayoutSingleColumn(),
              ),
            ],
          );
        },
      ),
    );
  }
}
