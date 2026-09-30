/// Craft screen: full-screen route with Express + Advanced modes.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';
import 'package:enjoy_player/features/craft/presentation/advanced_tools.dart';
import 'package:enjoy_player/features/craft/presentation/confirm_discard_unsaved_craft_preview.dart';
import 'package:enjoy_player/features/craft/presentation/express_flow.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Full-screen Craft route reached from the import chooser.
class CraftScreen extends ConsumerWidget {
  const CraftScreen({super.key});

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final state = ref.read(craftControllerProvider);
    if (state.isCapturing) {
      ref.read(craftControllerProvider.notifier).cancelCapture();
    } else if (state.hasUnsavedPreview) {
      final discard = await confirmDiscardUnsavedCraftPreview(context);
      if (discard != true || !context.mounted) return;
      ref.read(craftControllerProvider.notifier).resetForNextCapture();
    }

    if (!context.mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      unawaited(Navigator.of(context).pushNamed('/'));
    }
  }

  Future<void> _changeMode(
    BuildContext context,
    WidgetRef ref,
    CraftScreenMode next,
  ) async {
    final state = ref.read(craftControllerProvider);
    if (next == state.screenMode) return;
    if (state.hasUnsavedPreview) {
      final discard = await confirmDiscardUnsavedCraftPreview(context);
      if (discard != true || !context.mounted) return;
    }
    ref.read(craftControllerProvider.notifier).setScreenMode(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final state = ref.watch(craftControllerProvider);
    final isAdvanced = state.screenMode == CraftScreenMode.advanced;
    final blockPop = state.isCapturing || state.hasUnsavedPreview;

    return PopScope(
      canPop: !blockPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_leave(context, ref));
      },
      child: EnjoyPage(
        kind: isAdvanced ? EnjoyPageKind.hub : EnjoyPageKind.form,
        showBack: true,
        title: l10n.craftScreenTitle,
        actions: [
          EnjoyIconButton(
            icon: EnjoyIcons.history,
            tooltip: l10n.craftHistoryTooltip,
            onPressed: () => context.push('/craft/history'),
          ),
        ],
        onBack: () => unawaited(_leave(context, ref)),
        body: (context, metrics) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: metrics.padding(top: t.space8, bottom: t.space12),
                child: Center(
                  child: EnjoySegmentedControl<CraftScreenMode>(
                    segments: [
                      EnjoySegment(
                        value: CraftScreenMode.express,
                        icon: EnjoyIcons.mic,
                        label: l10n.craftModeExpress,
                      ),
                      EnjoySegment(
                        value: CraftScreenMode.advanced,
                        icon: EnjoyIcons.edit,
                        label: l10n.craftModeAdvanced,
                      ),
                    ],
                    value: state.screenMode,
                    onChanged: (next) =>
                        unawaited(_changeMode(context, ref, next)),
                  ),
                ),
              ),
              Expanded(
                child: isAdvanced
                    ? ListView(
                        padding: metrics.padding(top: 0, bottom: t.space32),
                        children: const [AdvancedTools()],
                      )
                    : Padding(
                        padding: metrics.padding(top: 0, bottom: t.space24),
                        child: const ExpressFlow(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
