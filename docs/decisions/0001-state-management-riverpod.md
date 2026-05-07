# ADR-0001: State management with Riverpod 3

## Status

Accepted

## Context

The Enjoy web app uses many small client stores (Zustand). We need a Dart-native, testable, async-friendly state layer with good codegen support.

## Decision

Use **flutter_riverpod 3** with `riverpod_annotation` / `riverpod_generator` for most providers. Keep a single `StreamProvider` hand-written where codegen fails on Drift row types (see `library_media_provider.dart`).

## Consequences

- `build_runner` is required when changing annotated providers.
- Team must follow Riverpod patterns (avoid global mutable singletons).
