# ADR-0055: Adaptive page layout system

## Status
Accepted

## Context
Shell screens mixed three page-chrome families (`EditorialHeader`, Material `AppBar`, custom back rows) and several informal max widths (`contentMaxWidth`, `contentMaxWidth + 96`, unconstrained forms). On wide desktops, form Save buttons stretched edge-to-edge while Discover titles clamped to 720px against a full-bleed grid. Future screens had no enforced page-layout convention.

## Decision
Adopt page **families** with shared primitives and tokens:

| Kind | Max width | Typical screens |
|------|-----------|-----------------|
| `browse` | full pane + `pageGutter` | Home, Discover, Library, channel feeds |
| `hub` | centered `hubMaxWidth` (840) | Profile, Settings, Subscription, Credits, Hotkeys, AI providers, Vocabulary |
| `form` | centered `formMaxWidth` (680) | Preferences, Edit Profile |
| `auth` | centered `modalMaxWidth` (400) | Sign-in |
| `playerChrome` | player-owned | Expanded player |

Primitives:

- `EnjoyPageKind` / `EnjoyPageMetrics` / `pageGutterOf` — [`lib/core/layout/enjoy_page_kind.dart`](../../lib/core/layout/enjoy_page_kind.dart)
- `EnjoyPage` — scaffold + metrics body builder
- `EnjoySubpageAppBar` — push-route chrome (replaces ad-hoc `AppBar` / back rows)
- `EditorialHeader` — browse uses gutter-aligned width; hubs may use column mode

Breakpoints: `breakpointCompact` (600) selects compact vs default gutter; `breakpointRail` (900) remains shell sidebar / Settings two-pane.

Do **not** invent per-screen max widths (e.g. `contentMaxWidth + 96`).

## Consequences
- New presentation screens must pick an `EnjoyPageKind` and use `EnjoyPage` / tokens.
- Docs: [app-ui.md](../features/app-ui.md), [conventions.md](../conventions.md), Cursor rule `.cursor/rules/layout.mdc`.
- Player transcript / side-by-side layout remains governed by existing player ADRs; only shared gutters/tokens apply when touched.
