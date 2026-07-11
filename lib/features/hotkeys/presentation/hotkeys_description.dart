/// Maps hotkey definition `descriptionKey` → [AppLocalizations] getter.
library;

import 'package:enjoy_player/l10n/app_localizations.dart';
import '../domain/hotkey_definition.dart';

String hotkeyDescription(AppLocalizations l10n, HotkeyDefinition d) {
  switch (d.descriptionKey) {
    case 'help':
      return l10n.hotkeysDescHelp;
    case 'search':
      return l10n.hotkeysDescSearch;
    case 'settings':
      return l10n.hotkeysDescSettings;
    case 'togglePlay':
      return l10n.hotkeysDescTogglePlay;
    case 'toggleExpand':
      return l10n.hotkeysDescToggleExpand;
    case 'toggleFullscreen':
      return l10n.hotkeysDescToggleFullscreen;
    case 'prevLine':
      return l10n.hotkeysDescPrevLine;
    case 'nextLine':
      return l10n.hotkeysDescNextLine;
    case 'replayLine':
      return l10n.hotkeysDescReplayLine;
    case 'toggleEchoMode':
      return l10n.hotkeysDescToggleEchoMode;
    case 'toggleBlurPractice':
      return l10n.hotkeysDescToggleBlurPractice;
    case 'toggleRecording':
      return l10n.hotkeysDescToggleRecording;
    case 'toggleAssessment':
      return l10n.hotkeysDescToggleAssessment;
    case 'togglePitchContour':
      return l10n.hotkeysDescTogglePitchContour;
    case 'playRecording':
      return l10n.hotkeysDescPlayRecording;
    case 'slowDown':
      return l10n.hotkeysDescSlowDown;
    case 'speedUp':
      return l10n.hotkeysDescSpeedUp;
    case 'expandEchoBackward':
      return l10n.hotkeysDescExpandEchoBackward;
    case 'expandEchoForward':
      return l10n.hotkeysDescExpandEchoForward;
    case 'shrinkEchoBackward':
      return l10n.hotkeysDescShrinkEchoBackward;
    case 'shrinkEchoForward':
      return l10n.hotkeysDescShrinkEchoForward;
    case 'librarySearch':
      return l10n.hotkeysDescLibrarySearch;
    case 'closeModal':
      return l10n.hotkeysDescCloseModal;
    default:
      return d.description ?? d.id;
  }
}

String hotkeysScopeLabel(AppLocalizations l10n, HotkeyScope scope) {
  switch (scope) {
    case HotkeyScope.global:
      return l10n.hotkeysScopeGlobal;
    case HotkeyScope.player:
      return l10n.hotkeysScopePlayer;
    case HotkeyScope.library:
      return l10n.hotkeysScopeLibrary;
    case HotkeyScope.modal:
      return l10n.hotkeysScopeModal;
  }
}
