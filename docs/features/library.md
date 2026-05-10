# Feature: Library

## MVP behavior

- List media from Drift `videos` / `audios` tables (newest first).
- **Local video thumbnails**: when a video is opened in the player and the row has **no** `http(s)` artwork URL and **no** readable local thumbnail file, the app captures a **JPEG** via media_kit `Player.screenshot` on the **single** active player and writes `media_thumbs/<key>.jpg` under app documents (`posterStorageKeyHexForVideo` in `lib/data/files/video_poster_extract.dart`: content `md5` when set, else SHA-256 of row `id`). Frame timing follows `posterSeekSeconds` in the same file (temporary seek from start when the session restores at **0**, then seek back to start). Capture is **best-effort** and does not block playback. **FFmpeg** remains for **duration probe** on import (`ffmpeg -i`) but **not** for posters. When `thumbnail_url` is `http(s)`, library/home tiles use **`Image.network`** (`localThumbnailFileForCard` in `lib/core/utils/remote_thumbnail_url.dart` avoids treating those URLs as local paths). Without artwork, tiles use a deterministic **generative cover** seeded by content hash.
- **Import**: pick a file (`FileType.media`), show a non-dismissible **Importing media…** dialog, copy and hash the file in a **background isolate** via `FileStorage` (UI stays responsive), insert row, dismiss the dialog, then navigate to `/player/:id`. Video posters appear after first open as above. On failure, the dialog closes and a **SnackBar** explains the error. Entry point is the **toolbar +** action on Library and the empty-state primary button.
- **Navigation**: Library and Settings are reached from the persistent shell (`NavigationBar` on compact widths, `NavigationRail` from ~900px when not on the player route).
- **Delete**: Home and Library media cards expose **Delete** (trash icon on tile thumbnails; audio list shows delete beside the chevron) **on pointer hover only**. Choosing delete opens a confirmation dialog; confirming removes the row locally via `MediaLibraryRepository.deleteMedia`, enqueues cloud sync delete when signed in, and closes the expanded player route if that item was open.

## Home

- When **signed in**, the Home screen shows a **Today's Goal** card (practice minutes vs. profile goal from `GET /api/v1/mine/stats` and `UserProfile.goal`, default 30) and a **Community activity** card in a **responsive two-column row** on wide viewports (≈720px+), or a **stacked column** on narrow screens. The block is **above** the recent media grid. Signed-out users do not see these cards.
- **Community activity** loads `GET /api/v1/users/active` with the device timezone.

## Future

- Metadata editing, search filters.
