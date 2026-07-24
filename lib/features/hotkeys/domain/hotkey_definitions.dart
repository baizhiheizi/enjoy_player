/// Default shortcuts for enjoy_player (subset of web `HOTKEY_DEFINITIONS`).
library;

import 'hotkey_definition.dart';

/// Stable Settings KV key for JSON map of action id → binding string.
const String kHotkeysCustomBindingsKey = 'hotkeys_custom_bindings';

final List<HotkeyDefinition> hotkeyDefinitions = [
  const HotkeyDefinition(
    id: 'global.help',
    defaultKeys: 'shift+slash',

    descriptionKey: 'help',
    scope: HotkeyScope.global,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'global.search',
    defaultKeys: 'ctrl+k',

    descriptionKey: 'search',
    scope: HotkeyScope.global,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'global.settings',
    defaultKeys: 'ctrl+comma',

    descriptionKey: 'settings',
    scope: HotkeyScope.global,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'global.craft',
    defaultKeys: 'c',
    descriptionKey: 'craft',
    scope: HotkeyScope.global,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.togglePlay',
    defaultKeys: 'space',

    descriptionKey: 'togglePlay',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.toggleExpand',
    defaultKeys: 'ctrl+shift+p',

    descriptionKey: 'toggleExpand',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.toggleFullscreen',
    defaultKeys: 'f11',

    descriptionKey: 'toggleFullscreen',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.prevLine',
    defaultKeys: 'a',

    descriptionKey: 'prevLine',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.nextLine',
    defaultKeys: 'd',

    descriptionKey: 'nextLine',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.replayLine',
    defaultKeys: 's',

    descriptionKey: 'replayLine',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.toggleEchoMode',
    defaultKeys: 'e',

    descriptionKey: 'toggleEchoMode',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.toggleBlurPractice',
    defaultKeys: 'h',

    descriptionKey: 'toggleBlurPractice',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.toggleRecording',
    defaultKeys: 'r',

    descriptionKey: 'toggleRecording',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.toggleAssessment',
    defaultKeys: 'v',

    descriptionKey: 'toggleAssessment',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.togglePitchContour',
    defaultKeys: 'p',

    descriptionKey: 'togglePitchContour',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.playRecording',
    defaultKeys: 'g',

    descriptionKey: 'playRecording',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.slowDown',
    defaultKeys: 'shift+comma',

    descriptionKey: 'slowDown',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.speedUp',
    defaultKeys: 'shift+period',

    descriptionKey: 'speedUp',
    scope: HotkeyScope.player,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'player.expandEchoBackward',
    defaultKeys: '[',

    descriptionKey: 'expandEchoBackward',
    scope: HotkeyScope.player,
    customizable: true,
    useKey: true,
  ),
  const HotkeyDefinition(
    id: 'player.expandEchoForward',
    defaultKeys: ']',

    descriptionKey: 'expandEchoForward',
    scope: HotkeyScope.player,
    customizable: true,
    useKey: true,
  ),
  const HotkeyDefinition(
    id: 'player.shrinkEchoBackward',
    defaultKeys: '{',

    descriptionKey: 'shrinkEchoBackward',
    scope: HotkeyScope.player,
    customizable: true,
    useKey: true,
  ),
  const HotkeyDefinition(
    id: 'player.shrinkEchoForward',
    defaultKeys: '}',

    descriptionKey: 'shrinkEchoForward',
    scope: HotkeyScope.player,
    customizable: true,
    useKey: true,
  ),
  const HotkeyDefinition(
    id: 'library.search',
    defaultKeys: '/',

    descriptionKey: 'librarySearch',
    scope: HotkeyScope.library,
    customizable: true,
  ),
  const HotkeyDefinition(
    id: 'modal.close',
    defaultKeys: 'escape',

    descriptionKey: 'closeModal',
    scope: HotkeyScope.modal,
    customizable: false,
  ),
];

final Map<String, HotkeyDefinition> hotkeyDefinitionMap = {
  for (final d in hotkeyDefinitions) d.id: d,
};

List<HotkeyDefinition> hotkeysByScope(HotkeyScope scope) =>
    hotkeyDefinitions.where((d) => d.scope == scope).toList();
