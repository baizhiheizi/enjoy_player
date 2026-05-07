# App UI (premium shell & theming)

## Baseline (pre-redesign reference)

- **Entry**: `MaterialApp.router` in `lib/app.dart` with light/dark `ThemeData` from `lib/core/theme/app_theme.dart`.
- **Navigation**: `go_router` `ShellRoute` → `RootShell` wraps `LibraryScreen`, `ExpandedPlayerScreen`, `SettingsScreen`.
- **Persistent chrome**: `MiniPlayerBar` when a session exists and chrome is not expanded.

## Anti-patterns removed or addressed

- **Seed-only theme**: Replaced with tuned typography, component themes, and `ThemeExtension` tokens.
- **Magic spacing/radius**: Centralized in `EnjoyThemeTokens` (`lib/core/theme/enjoy_tokens.dart`).
- **Unused semantic colors**: `AppColors` wired into tokens and echo / transcript accents.
- **Template library**: Card-based list, structured empty state, import in app bar (shell owns bottom/rail nav).
- **No adaptive shell**: `NavigationRail` at wide breakpoints; `NavigationBar` on compact; nav hidden on `/player/*` for focus.

## Behavior

- **Breakpoints** (from `EnjoyThemeTokens`): transcript side-by-side vs stacked; rail vs bottom nav.
- **Wide video + transcript**: No fixed vertical rule; transcript width is draggable (min ~240px, max 50% of width). Dragging the handle **left** widens the transcript / narrows the video; **right** does the reverse. The video uses **`BoxFit.cover`** so it always fills the video zone (cropped as needed). Video stage uses a soft surface gradient behind the frame.
- **Theme mode**: Still follows system (`ThemeMode.system` in `EnjoyApp`).
- **Motion**: Short fade on non-shell route transitions where configured in `app_router.dart`.

## Verification (after UI changes)

- `flutter analyze`
- `flutter test`
- Manual: light/dark, Library / Settings / Player, mini bar, subtitle sheet; narrow vs wide window (rail at ≥900px); wide player: drag between video and transcript to resize (Android + desktop targets as available).
