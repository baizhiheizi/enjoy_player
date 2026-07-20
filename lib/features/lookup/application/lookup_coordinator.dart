/// Opens the transcript dictionary / translation bottom sheet.
library;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_focus_policy.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/lookup/domain/lookup_request.dart';
import 'package:enjoy_player/features/lookup/presentation/dictionary_lookup_sheet.dart';

part 'lookup_coordinator.g.dart';

final Logger _log = logNamed('lookup');

@Riverpod(keepAlive: true)
class LookupCoordinator extends _$LookupCoordinator {
  @override
  int build() => 0;

  Future<void> open(BuildContext context, LookupRequest request) async {
    if (!context.mounted) return;
    _log.fine('lookup sheet: "${request.selectedText}"');
    final w = MediaQuery.sizeOf(context).width;
    final rail = EnjoyThemeTokens.of(context).breakpointRail;
    if (w >= rail) {
      final scheme = Theme.of(context).colorScheme;
      final t = EnjoyThemeTokens.of(context);
      await showEnjoyDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) {
          return Dialog(
            backgroundColor: scheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radiusXl),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(t.radiusXl),
                child: DictionaryLookupSheet(
                  presentation: DictionaryLookupPresentation.dialog,
                  request: request,
                ),
              ),
            ),
          );
        },
      );
      releasePrimaryFocusForGlobalHotkeys();
      return;
    }

    await showEnjoySheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetContext) => DictionaryLookupSheet(
        presentation: DictionaryLookupPresentation.bottomSheet,
        request: request,
      ),
    );
    releasePrimaryFocusForGlobalHotkeys();
  }
}
