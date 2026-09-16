/// Global-navigation hotkey commands (issue #719): help / cheatsheet,
/// settings, craft, search. They live in the hotkeys feature because the
/// actions are app-shell concerns, not owned by another feature.
library;

import 'dart:async';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_cheatsheet_open.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _log = logNamed('AppHotkeys');

/// `global.help` (default `Shift+/`) — opens the cheatsheet, or closes it when
/// already open.
class GlobalHelpHotkeyCommand extends HotkeyCommand {
  const GlobalHelpHotkeyCommand();

  @override
  String get actionId => 'global.help';

  /// The dialog needs the router navigator's context; without it (router not
  /// mounted) the key stays unhandled.
  @override
  bool canExecute(HotkeyCtx ctx) => ctx.routerNavigatorContext != null;

  @override
  void execute(HotkeyCtx ctx) {
    final navCtx = ctx.routerNavigatorContext!;
    if (hotkeysCheatsheetOpen.value) {
      final rootNav = ctx.rootNavigatorState;
      if (rootNav != null) unawaited(rootNav.maybePop());
      return;
    }
    unawaited(showHotkeysHelpDialog(navCtx));
  }
}

/// `global.settings` — navigate to `/settings`.
class GlobalSettingsHotkeyCommand extends HotkeyCommand {
  const GlobalSettingsHotkeyCommand();

  @override
  String get actionId => 'global.settings';

  @override
  bool canExecute(HotkeyCtx ctx) => true;

  @override
  void execute(HotkeyCtx ctx) {
    ctx.router.go('/settings');
  }
}

/// `global.craft` — navigate to `/craft` (consumed even when already there,
/// matching the old chain: returning early would let the same chord fall
/// through to lower-priority commands).
class GlobalCraftHotkeyCommand extends HotkeyCommand {
  const GlobalCraftHotkeyCommand();

  @override
  String get actionId => 'global.craft';

  @override
  bool canExecute(HotkeyCtx ctx) => true;

  @override
  void execute(HotkeyCtx ctx) {
    final path = ctx.path;
    if (path == '/craft' || path.startsWith('/craft/')) return;
    ctx.router.go('/craft');
  }
}

/// `global.search` — stub notice (search UX not built yet).
class GlobalSearchHotkeyCommand extends HotkeyCommand {
  const GlobalSearchHotkeyCommand();

  @override
  String get actionId => 'global.search';

  @override
  bool canExecute(HotkeyCtx ctx) => true;

  @override
  void execute(HotkeyCtx ctx) {
    final navCtx = ctx.routerNavigatorContext;
    if (navCtx != null) {
      final l10n = AppLocalizations.of(navCtx);
      if (l10n != null) {
        AppNotice.info(navCtx, l10n.hotkeysStubSearch);
      }
    }
    _log.fine('global search hotkey (stub)');
  }
}

/// Global commands in dispatch order (the old listener chain's global block).
final List<HotkeyCommand> globalHotkeyCommands = [
  const GlobalHelpHotkeyCommand(),
  const GlobalSettingsHotkeyCommand(),
  const GlobalCraftHotkeyCommand(),
  const GlobalSearchHotkeyCommand(),
];
