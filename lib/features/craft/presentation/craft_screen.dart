/// Craft screen: full-screen route with Express + Advanced modes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.craftScreenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : Navigator.of(context).pushNamed('/'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.center,
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
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final paneWidth = constraints.maxWidth;

            // Express mode: centered form column with adaptive gutters.
            if (state.screenMode == CraftScreenMode.express) {
              final metrics = EnjoyPageMetrics.of(
                context,
                kind: EnjoyPageKind.form,
                paneWidth: paneWidth,
              );
              return SingleChildScrollView(
                padding: metrics.padding(),
                child: const Center(child: ExpressFlow()),
              );
            }

            // Advanced mode: full-bleed with page gutters.
            final gutter = pageGutterOf(context, paneWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.all(gutter),
              child: const AdvancedTools(),
            );
          },
        ),
      ),
    );
  }
}
