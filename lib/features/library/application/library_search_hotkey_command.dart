/// `library.search` (`/`) hotkey command (issue #719).
library;

import 'package:enjoy_player/features/hotkeys/application/hotkey_command.dart';
import 'package:enjoy_player/features/library/application/library_search_focus.dart';

/// Focuses library search on desktop shell browse routes (not the expanded
/// player or auth-only flows) — see [librarySearchHotkeyEnabledForPath].
class LibrarySearchHotkeyCommand extends HotkeyCommand {
  const LibrarySearchHotkeyCommand();

  @override
  String get actionId => 'library.search';

  @override
  bool canExecute(HotkeyCtx ctx) => librarySearchHotkeyEnabledForPath(ctx.path);

  @override
  void execute(HotkeyCtx ctx) {
    requestLibrarySearchFocus(ctx.read);
  }
}
