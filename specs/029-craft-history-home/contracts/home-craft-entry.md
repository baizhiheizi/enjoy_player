# C1. Home Craft entry & global hotkey

**Date**: 2026-07-23 | **Feature**: 029-craft-history-home

## C1.1 Home trailing actions (CHANGED)

**Module**: `lib/features/library/presentation/home_screen.dart`

`EditorialHeader.trailing` becomes a `Row` (min size) with:

1. Craft control — label from new l10n key (product name **Craft** in EN + ZH); `onPressed` → `context.push('/craft')`
2. Existing Import `FilledButton.icon` → `showImportChooser`

Apply the same trailing on `_HomeLoadingScrollView` so loading Home stays consistent.

**UI effect**: Craft opens without showing the import chooser (FR-001, FR-002).

## C1.2 Import chooser Craft row (CHANGED copy only)

**Module**: `lib/features/library/presentation/library_actions.dart`

Keep the Craft `ListTile` (`context.push('/craft')`). Update label via `importCraftFromText` ARB (see C3). Do not remove the row (FR-015).

## C1.3 Hotkey definition (NEW)

**Module**: `lib/features/hotkeys/domain/hotkey_definitions.dart`

```dart
HotkeyDefinition(
  id: 'global.craft',
  defaultKeys: 'c',
  descriptionKey: 'craft',
  scope: HotkeyScope.global,
  customizable: true,
),
```

## C1.4 Hotkey dispatch (NEW)

**Module**: `lib/features/hotkeys/presentation/app_hotkeys_keyboard_listener.dart`

When `_matches(..., 'global.craft')` (after existing global focus guard):

- If `goRouter.state.uri.path` is already `/craft` (or a Craft child such as `/craft/history` if introduced) → return `true` without pushing another route.
- Else → `goRouter.go('/craft')` and return `true`.

Text-field focus continues to block via `primaryFocusBlocksGlobalHotkeys()` (FR-004).

## C1.5 Hotkey description (NEW)

**Module**: `lib/features/hotkeys/presentation/hotkeys_description.dart` + ARBs

Map `descriptionKey: 'craft'` → `l10n.hotkeysDescCraft` (EN/ZH).
