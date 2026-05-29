## 1. Routing and navigation shell

- [ ] 1.1 Add `librarySourceFromUri(Uri)` helper (default `local`; accept `cloud`)
- [ ] 1.2 Wire `/library` to read `source` query in router or screen
- [ ] 1.3 Add `/cloud` → `/library?source=cloud` redirect in `app_router.dart`
- [ ] 1.4 Reduce bottom nav to 4 items in `root_shell.dart`; map `/library` and `/cloud` to Library index
- [ ] 1.5 Remove Cloud sidebar row in `app_sidebar.dart`; extend Library selected state for `/cloud`
- [ ] 1.6 Update `ensureLibraryRouteForSearch` to force Local source (`/library` without cloud query)

## 2. Shared UI primitives

- [ ] 2.1 Extract shared `SegmentedButton` style (Library/Cloud kind segments) to `core/theme/widgets/` helper
- [ ] 2.2 Add ARB keys: `librarySourceLocal`, `librarySourceCloud`, `librarySourceCloudEyebrow`, semantics label
- [ ] 2.3 Run `flutter gen-l10n`

## 3. Unified Library screen shell

- [ ] 3.1 Refactor `LibraryScreen` into source-aware shell with Local/Cloud source segment above Audio/Video
- [ ] 3.2 Wire source segment to `context.go('/library?source=…')`; preserve `TabController` kind index on source change
- [ ] 3.3 Context-aware `EditorialHeader`: Import (local), Refresh (cloud), cloud eyebrow subtitle when active
- [ ] 3.4 Show compact search only when `source=local` and width < rail breakpoint
- [ ] 3.5 Use `IndexedStack` (or equivalent) for local vs cloud subtrees to preserve cloud pagination state
- [ ] 3.6 Add `AnimatedSwitcher` cross-fade between source bodies (~220ms; respect reduced motion)

## 4. Extract and compose tab bodies

- [ ] 4.1 Extract local audio/video bodies + search from `library_screen.dart` into dedicated widgets/files
- [ ] 4.2 Refactor `cloud_screen.dart` bodies into composable widgets (lists/grids + pagination); remove standalone route page builder usage
- [ ] 4.3 Embed cloud bodies in shell; show `AuthRequiredCallout` when cloud source + signed out
- [ ] 4.4 Remove or deprecate standalone `CloudScreen` scaffold (keep cloud logic, not duplicate nav entry)

## 5. Documentation

- [ ] 5.1 Update `docs/features/app-ui.md` navigation section (4 mobile tabs; Library source switch)
- [ ] 5.2 Update `docs/features/library.md` and `docs/features/cloud.md` for unified entry point
- [ ] 5.3 Add ADR for navigation consolidation (Library + Cloud shell merge) if warranted by docs-system rules

## 6. Tests and verification

- [ ] 6.1 Unit/widget tests: `/cloud` redirect; nav index for `/library?source=cloud`
- [ ] 6.2 Widget test: source segment switches URL; header trailing differs by source
- [ ] 6.3 Widget test: search hidden in cloud source; search hotkey navigates to local
- [ ] 6.4 Run `flutter analyze` and `flutter test`
