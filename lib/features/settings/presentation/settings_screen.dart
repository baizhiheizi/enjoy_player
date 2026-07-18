/// Settings hub — searchable, single-column on mobile, two-pane on desktop.
///
/// See specs/004-settings-redesign/ for the redesign spec/plan. Section
/// content lives in `widgets/sections/*.dart`; layout composition lives in
/// `widgets/settings_layout_single_column.dart` and
/// `widgets/settings_layout_two_pane.dart`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_layout_single_column.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_layout_two_pane.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_search_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = EnjoyPageMetrics.of(
            context,
            kind: EnjoyPageKind.hub,
            paneWidth: constraints.maxWidth,
          );
          final twoPane = constraints.maxWidth >= t.breakpointRail;
          if (!twoPane) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalInset,
                  ),
                  sliver: const SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(child: _EditorialHeaderSlot()),
                      SliverToBoxAdapter(child: SettingsSearchField()),
                      SliverToBoxAdapter(child: SettingsLayoutSingleColumn()),
                    ],
                  ),
                ),
              ],
            );
          }

          final twoPaneMaxWidth = t.hubMaxWidth + t.sidebarWidth;
          final hPad = math.max(
            metrics.gutter,
            (constraints.maxWidth - twoPaneMaxWidth) / 2,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_EditorialHeaderSlot(), SettingsSearchField()],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: const SettingsLayoutTwoPane(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Thin slot so [EditorialHeader] can resolve [AppLocalizations] via
/// [ConsumerWidget] and its own [LayoutBuilder] for centering.
class _EditorialHeaderSlot extends ConsumerWidget {
  const _EditorialHeaderSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    return EditorialHeader(
      title: l10n.settingsTitle,
      subtitle: l10n.settingsSubtitle,
      widthMode: EditorialHeaderWidthMode.column,
      columnMaxWidth: t.hubMaxWidth,
      // Outer padding already applied by the settings layout.
      padding: EdgeInsets.fromLTRB(0, t.space24, 0, t.space16),
    );
  }
}
