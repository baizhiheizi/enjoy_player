# ADR-0056: UserVideo library membership + content-addressed uploads

## Status

Accepted

## Context

YouTube/Netflix video ids are globally unique. Treating `videos.user_id` as library ownership meant the first syncer claimed the row and other users got HTTP 409. Clients (especially the player) worked around this with mine GET → public catalog GET recovery. Local uploads were also salted with `userId`, preventing shared catalog identity for identical files.

## Decision

1. Server library membership is `user_videos` (soft-deletable). Mine create enrolls; mine delete leaves membership only.
2. New local video uploads use content-addressed ids (`vid = contentHash`, no `userId`). Legacy upload rows keep their existing ids (no rekey/merge).
3. Player drops public-catalog ownership recovery; duplicate races resolve via mine GET only. Mine pull `deletedAt` removes the local library row.

## Consequences

- Multi-user YouTube/Netflix library works without 409.
- Identical *new* uploads converge to one catalog video; historical uploads stay separate.
- Audio ids remain user-scoped for now (follow-up).
- Deploy backend membership expand before client content-hash builds.

## Related

- [sync.md](../features/sync.md)
- [ADR-0013](0013-local-first-sync.md)
