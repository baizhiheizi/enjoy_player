/// Craft screen: full-screen route with Express + Advanced modes.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';
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
        body: (context, metrics) {
          final narrow = metrics.paneWidth < t.breakpointCompact;
          final columnMaxWidth = isAdvanced ? t.hubMaxWidth : t.formMaxWidth;
          final controls = _CraftHeaderControls(
            mode: state.screenMode,
            iconOnlyHistory: narrow,
            onModeChanged: (next) => unawaited(_changeMode(context, ref, next)),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditorialHeader(
                widthMode: EditorialHeaderWidthMode.column,
                columnMaxWidth: columnMaxWidth,
                overline: l10n.craftOverline,
                title: l10n.craftScreenTitle,
                trailing: narrow ? null : controls,
              ),
              if (narrow)
                Padding(
                  padding: metrics.padding(top: 0, bottom: t.space16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: controls,
                  ),
                ),
              if (!isAdvanced)
                Padding(
                  padding: metrics.padding(top: 0, bottom: t.space12),
                  child: CraftStageStepper(stage: state.stage),
                ),
              Expanded(
                child: isAdvanced
                    ? ListView(
                        padding: metrics.padding(top: 0, bottom: t.space32),
                        children: const [AdvancedTools()],
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: state.stage == CraftStage.capture
                                ? _kCaptureCardMaxHeight
                                : double.infinity,
                          ),
                          child: Padding(
                            padding: metrics.padding(top: 0, bottom: t.space24),
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: t.paper,
                                shape: RoundedSuperellipseBorder(
                                  borderRadius: BorderRadius.circular(
                                    t.radiusCard,
                                  ),
                                  side: BorderSide(color: t.line),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  narrow ? t.space16 : t.space24,
                                ),
                                child: const ExpressFlow(),
                              ),
                            ),
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

const double _kCaptureCardMaxHeight = 460;

class _CraftHeaderControls extends StatelessWidget {
  const _CraftHeaderControls({
    required this.mode,
    required this.iconOnlyHistory,
    required this.onModeChanged,
  });

  final CraftScreenMode mode;
  final bool iconOnlyHistory;
  final ValueChanged<CraftScreenMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    void openHistory() => unawaited(context.push('/craft/history'));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnjoySegmentedControl<CraftScreenMode>(
          segments: [
            EnjoySegment(
              value: CraftScreenMode.express,
              label: l10n.craftModeExpress,
            ),
            EnjoySegment(
              value: CraftScreenMode.advanced,
              label: l10n.craftModeAdvanced,
            ),
          ],
          value: mode,
          onChanged: onModeChanged,
        ),
        SizedBox(width: t.space8),
        if (iconOnlyHistory)
          EnjoyIconButton(
            icon: EnjoyIcons.history,
            tooltip: l10n.craftHistoryTooltip,
            onPressed: openHistory,
          )
        else
          EnjoyButton.secondary(
            icon: EnjoyIcons.history,
            onPressed: openHistory,
            child: Text(l10n.craftHistoryTooltip),
          ),
      ],
    );
  }
}

/// Capture → Rewrite → Audio progress for the Express flow.
class CraftStageStepper extends StatelessWidget {
  const CraftStageStepper({required this.stage, super.key});

  final CraftStage stage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final steps = [
      (CraftStage.capture, l10n.craftStageCapture),
      (CraftStage.rewrite, l10n.craftStageRewrite),
      (CraftStage.audio, l10n.craftStageAudio),
    ];
    final current = steps.indexWhere((s) => s.$1 == stage);

    Widget step(int index, String label) {
      final active = index == current;
      final done = current > index || stage == CraftStage.done;
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: ShapeDecoration(
          color: active ? t.paper : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: active ? t.line : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: active ? null : t.sunk,
                gradient: active ? t.brand : null,
                shape: const CircleBorder(),
              ),
              child: done
                  ? Icon(EnjoyIcons.check, size: 12, color: t.ink2)
                  : Text(
                      '${index + 1}',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : t.ink3,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? t.ink : t.ink3,
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      child: Row(
        children: [
          for (final (i, s) in steps.indexed) ...[
            if (i > 0)
              Container(
                width: 24,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: t.line,
              ),
            step(i, s.$2),
          ],
        ],
      ),
    );
  }
}
