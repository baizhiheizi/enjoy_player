# Architecture Decision Records

ADRs are **immutable** after merge. To change a decision, add a new ADR that **supersedes** the old one.

## Template

```markdown
# ADR-NNNN: Title

## Status
Proposed | Accepted | Superseded by ADR-XXXX

## Context
What problem are we solving?

## Decision
What did we choose?

## Consequences
Trade-offs, follow-up work, risks.
```

## Index

| ID | Title |
|----|-------|
| [0001](0001-state-management-riverpod.md) | State management with Riverpod 3 |
| [0002](0002-persistence-drift.md) | Local persistence with Drift |
| [0003](0003-player-core-media-kit.md) | media_kit as sole player engine |
| [0004](0004-feature-first-architecture.md) | Feature-first directory layout |
| [0005](0005-mvp-scope-local-only.md) | MVP scope — local files only |
| [0006](0006-auth-and-profile-sync.md) | Auth, profile, settings sync (browser flow) |
| [0007](0007-dynamic-color-from-artwork.md) | Dynamic color from media artwork |
| [0008](0008-light-mode-parity.md) | Light mode parity |
| [0009](0009-platform-adaptive-shell.md) | Platform-adaptive shell nuances |
| [0010](0010-cloud-sync-mvp.md) | Cloud sync MVP — metadata (audio/video/recording) |
| [0011](0011-dark-mode-only.md) | Dark mode only + logo-aligned brand (supersedes 0008) |
| [0012](0012-per-user-sqlite-isolation.md) | Per-user SQLite + secure profile cache (partial supersession of 0006) |
| [0013](0013-local-first-sync.md) | Local-first cloud sync + Cloud index (supersedes 0010 download behavior on player) |
| [0014](0014-ai-capabilities-layer.md) | AI capabilities layer (Enjoy worker + capability pattern; BYOK/local placeholders) |
| [0015](0015-youtube-playback.md) | YouTube playback via WebView + HTML5 video (dual engine with media_kit) |
| [0016](0016-enjoy-account-webview-sign-in.md) | Enjoy account sign-in via in-app WebView (partial supersession of 0006) |
| [0017](0017-azure-pronunciation-assessment.md) | Azure pronunciation assessment via native Flutter plugin (token-only) |
| [0018](0018-shared-interactive-primitives.md) | Shared interactive primitives — EnjoyTappable, Haptics, EnjoyButton |
| [0019](0019-transcript-dictionary-lookup.md) | Transcript dictionary lookup — selection scope, bottom sheet, worker APIs |
| [0020](0020-android-windows-release-identity.md) | Android app ID `ai.enjoy.player`, release signing via `key.properties`, Windows release branding + Inno installer |
| [0021](0021-youtube-discover-rss.md) | YouTube discovery via RSS feeds and local channel subscriptions |
| [0022](0022-unified-library-navigation.md) | Unified Library navigation — local + cloud source switch |
| [0023](0023-app-update-distribution.md) | App update distribution — store no-op, direct feeds on dl.enjoy.bot |
| [0024](0024-download-landing-page.md) | Download landing page — static site on Cloudflare Pages at get.enjoy.bot |
| [0025](0025-youtube-player-block-google-signin-nav.md) | Block Google sign-in navigations in YouTube player WebView (supplements 0015) |
| [0026](0026-local-production-diagnostics.md) | Local production diagnostics — rotating logs, opt-in verbose, zip export |
| [0027](0027-native-auth-v2.md) | Native auth v2 — Google, Apple, email OTP, PKCE fallback (supersedes 0016 WebView-primary) |
| [0028](0028-agentic-engine-choice.md) | Agentic workflow engine choice — third-party Anthropic-compatible proxy (proposed) |
| [0029](0029-supply-chain-risk.md) | Supply-chain risk for pre-release and local-path dependencies |
