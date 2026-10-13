/// Global-navigation hotkey commands (issue #719): help / cheatsheet,
/// settings, craft, search. They live in the hotkeys feature because the
/// actions are app-shell concerns, not owned by another feature.
library;

import 'dart:async';

import 'package:flutter/scheduler.dart';

import 'package:enjoy_player/core/routing/library_source.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkeys_cheatsheet_open.dart';
import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_help_dialog.dart';
import 'package:enjoy_player/features/library/application/library_search_focus.dart';
import 'package:enjoy_player/features/library/application/library_search_focus_provider.dart';

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

/// `global.search` (default `Ctrl+K`, `⌘K` on macOS) — focuses library
/// search, the same field `/` focuses; from the player it first returns to
/// Library.
class GlobalSearchHotkeyCommand extends HotkeyCommand {
  const GlobalSearchHotkeyCommand();

  @override
  String get actionId => 'global.search';

  @override
  bool canExecute(HotkeyCtx ctx) =>
      librarySearchHotkeyEnabledForPath(ctx.path) ||
      ctx.path.startsWith('/player/');

  @override
  void execute(HotkeyCtx ctx) {
    if (ctx.path.startsWith('/player/')) {
      ctx.router.go(libraryRouteForSource(LibrarySource.local));
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          ctx.read(librarySearchFocusRequestProvider.notifier).pulse();
        });
      });
      return;
    }
    requestLibrarySearchFocus(ctx.read);
  }
}

/// Global commands in dispatch order (the old listener chain's global block).
final List<HotkeyCommand> globalHotkeyCommands = [
  const GlobalHelpHotkeyCommand(),
  const GlobalSettingsHotkeyCommand(),
  const GlobalCraftHotkeyCommand(),
  const GlobalSearchHotkeyCommand(),
];
