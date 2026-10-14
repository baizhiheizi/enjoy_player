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
import 'package:enjoy_player/features/player/application/player_margin_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/player_margin.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

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
    final compact = EnjoyThemeTokens.of(context).breakpointCompact;
    if (w >= compact) {
      await openPlayerMargin(
        context,
        PlayerMarginEntry(
          id: 'lookup:${request.selectedText}',
          label: AppLocalizations.of(context)!.lookupSheetTitle,
          builder: (context, close) => DictionaryLookupSheet(
            presentation: DictionaryLookupPresentation.dialog,
            request: request,
            onClose: close,
          ),
        ),
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
