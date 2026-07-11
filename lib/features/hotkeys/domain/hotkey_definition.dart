/// Hotkey metadata (aligned with web `HotkeyDefinition` in `stores/hotkeys.ts`).
library;

enum HotkeyScope { global, player, library, modal }

class HotkeyDefinition {
  const HotkeyDefinition({
    required this.id,
    required this.defaultKeys,
    this.description,
    required this.descriptionKey,
    required this.scope,
    required this.customizable,
    this.useKey = false,
  });

  final String id;
  final String defaultKeys;
  final String? description;
  final String descriptionKey;
  final HotkeyScope scope;
  final bool customizable;
  final bool useKey;
}
