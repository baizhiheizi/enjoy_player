# Feature: Library

## MVP behavior

- List media from Drift `videos` / `audios` tables (newest first).
- **Local video thumbnails**: when a video is opened in the player and the row has **no** `http(s)` artwork URL and **no** readable local thumbnail file, the app captures a **JPEG** via media_kit `Player.screenshot` on the **single** active player and writes `media_thumbs/<key>.jpg` under app documents (`posterStorageKeyHexForVideo` in `lib/data/files/video_poster_extract.dart`: content `md5` when set, else SHA-256 of row `id`). Frame timing follows `posterSeekSeconds` in the same file (temporary seek from start when the session restores at **0**, then seek back to start). Capture is **best-effort** and does not block playback. **FFmpeg** remains for **duration probe** on import (`ffmpeg -i`) but **not** for posters. When `thumbnail_url` is `http(s)`, library/home tiles use **`Image.network`** (`localThumbnailFileForCard` in `lib/core/utils/remote_thumbnail_url.dart` avoids treating those URLs as local paths). Without artwork, tiles use a deterministic **generative cover** seeded by content hash.
- **Tile accent (Home + Library grids)**: hover / border tint uses **`generativeAccentForSeed`** only. The app does **not** run `palette_generator` / `PaletteGenerator.fromImageProvider` per grid tile — that work ran on the **main isolate** (package `palette_generator` 0.3.x) and with many tiles caused **multi-second UI freezes** on Windows (especially debug). **Artwork-derived palettes** remain for the **active player** (e.g. transport / hero artwork via `currentArtworkPaletteProvider`), where a single extraction is acceptable.
- **Import**: pick a file (`FileType.media`), show a non-dismissible **Importing media…** dialog, copy and hash the file in a **background isolate** via `FileStorage` (UI stays responsive), insert row, dismiss the dialog, then navigate to `/player/:id`. Video posters appear after first open as above. On failure, the dialog closes and a **SnackBar** explains the error. Entry point is the **toolbar +** action on Library and the empty-state primary button.
- **Navigation**: Library and Settings are reached from the persistent shell (`NavigationBar` on compact widths, `NavigationRail` from ~900px when not on the player route).
- **Delete**: Home and Library media cards expose **Delete** (trash icon on tile thumbnails; audio list shows delete beside the chevron) **on pointer hover** on desktop-class pointers. **Android / iOS**: long-press a card to open a bottom sheet with **Delete**, then the same confirmation dialog as desktop; confirming removes the row locally via `MediaLibraryRepository.deleteMedia`, enqueues cloud sync delete when signed in, and closes the expanded player route if that item was open.

## Home

- When **signed in**, the Home screen shows a **Today's Goal** card (practice minutes vs. profile goal from `GET /api/v1/mine/stats` and `UserProfile.goal`, default 30) and a **Community activity** card in a **responsive two-column row** on wide viewports (≈720px+), or a **stacked column** on narrow screens. The block is **above** the recent media grid (only when the home body has loaded library data — empty state vs. scroll view). Signed-out users do not see these cards.
- **Community activity** loads `GET /api/v1/users/active` with the device timezone (client **8s timeout**; on timeout the card hides / shows no data).

## Performance (signed-in cold start, Windows)

**Symptom:** App window not responding to scroll / input for several seconds after launch when signed in, sometimes overlapping slow `GET /api/v1/mine/stats` or `GET /api/v1/users/active` in logs — but those requests are async; the stall was **main-isolate** work, not HTTP latency itself.

**Root cause:** Each Home / Library grid tile watched `artworkPaletteProvider`, which calls `PaletteGenerator.fromImageProvider` in `lib/core/theme/dynamic_color/artwork_palette.dart`. That decodes thumbnails and clusters colors **on the UI isolate**. Many tiles produced several seconds of continuous CPU work on the Dart event loop (observed in debug with DevTools CPU sampling).

**Fix:** Home and Library grid tiles use **`generativeAccentForSeed`** for hover / border tint only — no per-tile `palette_generator`. **Artwork-derived palettes** remain for the **active player** (e.g. `currentArtworkPaletteProvider` on transport / hero artwork), where a single extraction is acceptable.

**Also in tree (supporting, not the freeze root cause):** `driftRuntimeOptions.dontWarnAboutMultipleDatabases` in `lib/main.dart` (guest + per-user DBs are intentional), and `app_database_provider.dart` caches one `AppDatabase` per session name with `onDispose` cleanup — avoids duplicate instances and Drift’s multi-open warning spam.

**Regression checks:** Use Flutter DevTools **CPU profiler** (UI thread) if similar freezes reappear; avoid reintroducing per-item `PaletteGenerator` in large scrollables without an isolate or precomputed palette.

## Future

- Metadata editing, search filters.
