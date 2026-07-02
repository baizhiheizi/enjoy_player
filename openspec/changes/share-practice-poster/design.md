## Context

Enjoy Player stores shadow-reading practice locally in Drift: `recordings` (per take, with `referenceText` and timing) and denormalized aggregates on `echo_sessions` (`recordingsCount`, `recordingsDurationMs`). Transcript line overlap logic already exists (`countRecordingsPerLineIndex`). Library tiles resolve cover art via local thumb, network URL, or generative fallback (`coverSeed`).

There is no image export or mobile share infrastructure today. Diagnostic export uses `FilePicker.saveFile` (desktop-oriented). Brand tokens (`AppColors`, `EnjoyLogo`, dark gradient) and practice stat formatting (`formatPracticeDurationMs`) exist.

Primary audience for this feature is **mobile users sharing to WeChat** (Moments, friend chats) and similar apps on iOS/Android. Desktop share is secondary (save PNG).

## Goals / Non-Goals

**Goals:**

- Generate a **branded, mobile-first practice poster** (9:16) for one media item with cover, title, hero sentence, stats, and QR to `https://player.enjoy.bot`.
- **Preview → share** flow with system share sheet on iOS/Android (WeChat and other targets via OS picker).
- **Offline-capable** — all data from local Drift; no server render.
- Reuse existing thumbnail, transcript, and recording overlap logic.
- Localized poster chrome (`en`, `zh`).

**Non-Goals:**

- Web target or in-browser share.
- Server-generated posters or cloud-hosted share links.
- User-selectable hero line or multiple templates in MVP.
- Posting username, avatar, or pronunciation score on the poster.
- Deep link QR to a specific video in cloud library.

## Decisions

### 1. Canvas: 9:16 mobile portrait (1080×1920 logical)

**Decision:** Design and export at **9:16** with generous top/bottom safe margins (WeChat Moments may center-crop).

**Rationale:** WeChat Moments and mobile stories expect tall images; 4:5 is acceptable on Instagram but 9:16 is the dominant Chinese mobile share format.

**Alternatives considered:** 1:1 (too cramped for quote + stats + QR); dual export (deferred).

### 2. Render pipeline: Flutter widget → PNG via `RepaintBoundary`

**Decision:** Build a fixed-size `PracticePosterWidget` wrapped in `RepaintBoundary`, capture with `toImage(pixelRatio: 3)` after async assets (network/local thumb) resolve.

**Rationale:** Matches app theme/fonts/SVG logo; no new rendering stack.

**Alternatives considered:** `CustomPainter` only (harder to maintain layout); server-side (out of scope).

### 3. Share: `share_plus` on mobile; `FilePicker.saveFile` on desktop

**Decision:**

- **iOS / Android:** `Share.shareXFiles([XFile.fromData(pngBytes, mimeType: 'image/png', name: 'enjoy-practice.png')])` — opens system sheet where user picks WeChat, save to album, etc.
- **Windows / macOS:** `FilePicker.saveFile` with PNG bytes (same pattern as `diagnostic_export_flow.dart`).

**Rationale:** WeChat has no stable public SDK for third-party image share; OS share sheet is the standard path on mobile. `share_plus` is the de-facto Flutter wrapper.

**Alternatives considered:** WeChat SDK (platform-specific, store policy, maintenance); saving to gallery only (extra step before WeChat).

### 4. Hero sentence: most-practiced transcript line

**Decision:** Pick transcript line index with **highest recording count** (`countRecordingsPerLineIndex`); tie-break by **longer line text**. Fallback: longest non-empty `referenceText` among recordings; if none, omit quote block.

**Rationale:** Aligns with "sentence with most recordings" from product intent; tie-break improves poster readability.

**Alternatives considered:** Longest sentence only (less meaningful); user picker (v2).

### 5. Stats: three tiles

**Decision:** Show **takes** (recording count for target), **sentences** (transcript line indices with ≥1 recording), **spoken time** (sum of `recording.duration` for target, formatted via `formatPracticeDurationMs`).

**Rationale:** Clear, verifiable from local DB; matches profile stat patterns.

**Alternatives considered:** Denormalized `echo_sessions` fields only (can drift); average pronunciation score (not always available).

### 6. Feature module layout

**Decision:** `lib/features/share_poster/` with:

- `domain/practice_poster_data.dart` — pure aggregation model + hero-line resolver
- `application/practice_poster_builder.dart` — loads media, transcript, recordings from DAOs
- `presentation/practice_poster_widget.dart` — fixed 9:16 layout
- `presentation/practice_poster_preview_sheet.dart` — preview + Share / Save actions
- `application/practice_poster_export.dart` — capture + platform dispatch

**Rationale:** Follows feature-layer architecture; keeps player UI thin (one entry action).

### 7. Entry point: player overflow when recordings exist

**Decision:** Add **Share practice poster** to player chrome (e.g. overflow menu) enabled when `recordingsCount > 0` for current media. Optional secondary entry from shadow-reading panel later.

**Rationale:** User is in context of the video they practiced; avoids clutter on library tiles in MVP.

### 8. Dependencies

**Decision:** Add `share_plus` and `qr_flutter` to `pubspec.yaml`.

**Rationale:** QR widget fits poster layout; share_plus handles mobile MIME share.

### 9. Branding

**Decision:** Dark zinc gradient background (`AppColors.gradientStartDark` → `gradientEndDark`), `EnjoyLogo`, accent from `generativeAccentForSeed(media.coverSeed)` on quote card border/glow, footer CTA + QR. Tagline localized (e.g. "Shadow reading with Enjoy Player").

**Rationale:** Consistent with app; promotional without feeling like a raw screenshot.

## Risks / Trade-offs

- **[WeChat crop]** → Use safe margins; keep logo/stats/QR away from extreme edges; test on iOS/Android WeChat share.
- **[Thumbnail load delay]** → Preview sheet shows loading until image ready; disable Share until capture succeeds.
- **[Long CJK hero text]** → Max 3–4 lines with ellipsis in poster widget.
- **[Copyright on thumbnail/subtitle text]** → Voluntary user share; no Enjoy-hosted public page in MVP.
- **[share_plus platform quirks]** → Graceful error + fallback "Save image" where share fails; log via `logNamed` (see [conventions.md § Logging](../../../docs/conventions.md#logging)).
- **[Empty practice]** → Hide menu item when zero recordings; no empty poster.

## Migration Plan

- Additive only: new feature module, new dependencies, new l10n keys, docs update.
- No DB migration.
- Rollback: remove entry point and feature module; no data impact.

## Open Questions

- Minimum recordings to enable share (1 vs 3)? **Default: 1** for MVP.
- Include video provider badge (YouTube) on poster? **Defer** — may imply endorsement.
- Android: request storage permission if saving to gallery in future? **Not needed for share sheet MVP.**
