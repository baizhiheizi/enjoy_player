# Feature: Library

## MVP behavior

- List media from Drift `media` table (newest first).
- Import: pick a file (`FileType.media`), copy into documents via `FileStorage`, insert row, navigate to `/player/:id`. Entry point is the **toolbar +** action on Library and the empty-state primary button.
- **Navigation**: Library and Settings are reached from the persistent shell (`NavigationBar` on compact widths, `NavigationRail` from ~900px when not on the player route).

## Future

- Thumbnails, metadata editing, delete swipe, search filters.
