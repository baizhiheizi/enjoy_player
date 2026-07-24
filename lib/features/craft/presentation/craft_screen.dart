/// Craft screen: full-screen route with Express + Advanced modes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';
import 'package:enjoy_player/features/craft/presentation/advanced_tools.dart';
import 'package:enjoy_player/features/craft/presentation/express_flow.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Full-screen Craft route reached from the import chooser.
class CraftScreen extends ConsumerWidget {
  const CraftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final state = ref.watch(craftControllerProvider);
    final isAdvanced = state.screenMode == CraftScreenMode.advanced;

    return PopScope(
      canPop: !state.isCapturing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (ref.read(craftControllerProvider).isCapturing) {
          ref.read(craftControllerProvider.notifier).cancelCapture();
        }
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: EnjoyPage(
        // Express = form column; Advanced = hub width (matches AI settings).
        kind: isAdvanced ? EnjoyPageKind.hub : EnjoyPageKind.form,
        showBack: true,
        title: l10n.craftScreenTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: l10n.craftHistoryTooltip,
            onPressed: () => context.push('/craft/history'),
          ),
        ],
        onBack: () {
          if (ref.read(craftControllerProvider).isCapturing) {
            ref.read(craftControllerProvider.notifier).cancelCapture();
          }
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            unawaited(Navigator.of(context).pushNamed('/'));
          }
        },
        body: (context, metrics) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: metrics.padding(top: t.space8, bottom: t.space12),
                child: Center(
                  child: SegmentedButton<CraftScreenMode>(
                    style: enjoySegmentedButtonStyle(context),
                    segments: [
                      ButtonSegment(
                        value: CraftScreenMode.express,
                        icon: const Icon(Icons.mic_rounded, size: 18),
                        label: Text(l10n.craftModeExpress),
                      ),
                      ButtonSegment(
                        value: CraftScreenMode.advanced,
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(l10n.craftModeAdvanced),
                      ),
                    ],
                    selected: {state.screenMode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(craftControllerProvider.notifier)
                          .setScreenMode(selection.first);
                    },
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
