# ADR-0062: Remove Craft history record keeps practice audio

## Status

Accepted

## Context

Craft history (ADR-0061) lists saved items with `Audios.provider = 'craft'`.
Learners need to remove a Craft history record without destroying the
generated practice audio in the library. Full library delete is too
destructive; a soft-hide list of media ids is the wrong model — the Craft
record itself should be removed, not merely concealed.

## Decision

1. **Remove = clear Craft provenance**: `MediaLibraryRepository.removeCraftHistoryRecord(mediaId)` updates the existing audio row’s `provider` from `'craft'` to `'user'`, bumps `updatedAt`, and enqueues sync update.
2. **Keep the artifact**: Same media id, local audio file, transcripts, and library membership remain. The item is no longer listed in Craft history and loses the Craft badge.
3. **Not library delete**: Do not call `deleteMedia` and do not delete the audio file for this action.

## Consequences

- Craft history and library practice are separable: declutter history without losing shadow-reading material.
- After removal, the item cannot be reopened from Craft history (no Craft provenance); practice continues from Home/Library.
- `source` flags such as `craft-express` may remain for local diagnostics; membership in Craft history is defined solely by `provider == 'craft'`.
