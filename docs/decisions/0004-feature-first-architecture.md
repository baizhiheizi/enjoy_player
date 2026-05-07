# ADR-0004: Feature-first directory layout

## Status

Accepted

## Context

The codebase must stay navigable as player, transcript, and library features grow. Alternatives: strict clean-arch layers only, or monolithic `lib/src`.

## Decision

Use **feature-first** structure: `lib/features/<feature>/{application,data,domain,presentation}` with shared `lib/core` and `lib/data`.

## Consequences

- Cross-feature imports should remain narrow (prefer shared `data` / `core` over feature-to-feature cycles).
- Documentation lists feature specs under `docs/features/`.
