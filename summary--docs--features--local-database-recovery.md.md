<hash>size:5070</hash>

# `docs/features/local-database-recovery.md`

- Bootstrap database failures are classified and routed to a localized recovery surface.
- Migrations defend against duplicate-column retries and downgrade execution.
- Reset backs up, closes, wipes, invalidates database/preferences providers, and reloads in place without deleting auth tokens.
