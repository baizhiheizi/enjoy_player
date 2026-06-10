# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-06-10

### Added

- **Discover** tab: browse recommended YouTube channels, subscribe locally, and import videos from a merged upload feed.
- **Unified Library** navigation: Local and Cloud media in one shell tab (`/library?source=cloud`).
- **OTA updates**: in-app update prompts with platform feeds on `dl.enjoy.bot` (Android, iOS, macOS Sparkle, Windows WinSparkle).
- Transcript **recording counts** per line; hotkey **settings** screen and global focus policy.
- **Mobile transport** line navigation for narrow player layouts.
- Signed-in **Home**: today's practice goal and community activity cards.

### Changed

- Library search with `/` hotkey; improved media card thumbnails and YouTube artwork handling.
- Release tooling: shared local/CI scripts, R2 publish pipeline, and local-first packaging docs.

## [0.1.0] - 2026-05-22

First public beta.

### Added

- Initial MVP scaffold: feature-first layout, Drift schema, media_kit player, Riverpod providers, go_router shell with mini player, transcript import (SRT/VTT), echo mode parity with web `echo-utils`.
- Documentation system: AGENTS.md, ADRs, feature specs, Cursor rules.
