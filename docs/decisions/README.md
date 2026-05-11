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
