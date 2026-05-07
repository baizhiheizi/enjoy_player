# ADR-0002: Local persistence with Drift

## Status

Accepted

## Context

The web app persists media and transcripts in IndexedDB. The Flutter app needs a cross-platform relational store with migrations and type-safe queries.

## Decision

Use **Drift** with `drift_flutter` opening a single SQLite file per install. All tables are defined in `lib/data/db/app_database.dart` with DAOs colocated in the same library to avoid part/circular import issues.

## Consequences

- JSON column used for transcript lines for MVP flexibility.
- Schema migrations will use `schemaVersion` + `MigrationStrategy` as the app grows.
