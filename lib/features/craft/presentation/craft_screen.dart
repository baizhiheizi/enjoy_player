/// Craft screen: full-screen route with Express + Advanced modes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
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
    final state = ref.watch(craftControllerProvider);

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
        kind: EnjoyPageKind.form,
        showBack: true,
        title: l10n.craftScreenTitle,
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
                padding: EdgeInsets.fromLTRB(
                  metrics.gutter,
                  4,
                  metrics.gutter,
                  8,
                ),
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.maxWidth ?? double.infinity,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        metrics.gutter,
                        0,
                        metrics.gutter,
                        metrics.gutter,
                      ),
                      // Stages own their scroll — avoid nested ScrollViews.
                      child: state.screenMode == CraftScreenMode.express
                          ? const ExpressFlow()
                          : const SingleChildScrollView(child: AdvancedTools()),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
