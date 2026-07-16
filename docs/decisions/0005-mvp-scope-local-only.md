# ADR-0005: MVP scope — local files only

## Status

Accepted — **import storage superseded in part by [ADR-0050](0050-path-linked-local-media.md)** (prefer lasting link; copy only when lasting access is unavailable). Other MVP scope decisions in this ADR remain in force unless separately superseded.

## Context

The product vision includes YouTube, URL streaming, and cloud sync (see web app). The first Flutter deliverable must ship a focused learning player without external service dependencies.

## Decision

MVP **v1** includes:

- Import local media via `file_picker` (historically copy into app documents; see ADR-0050 for current link-preferring behavior).
- Transcript import (`.srt` / `.vtt`).
- Expanded + mini player UX, line navigation, echo mode, persisted position.

Explicitly **excluded** from v1:

- `flutter_inappwebview` / YouTube
- URL streaming UX
- Cloud sync / auth
- Dictation, recording, vocabulary workflows

## Consequences

- Desktop/mobile file workflows must feel solid before adding network features.
- Future ADRs must supersede this scope when promoting features into MVP.
