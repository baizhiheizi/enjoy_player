# Superpowers: refactor specs & implementation plans

`docs/superpowers/` holds **design specs** and **implementation plans** for
large, mechanically-verifiable refactors — the working documents produced
*before* the code moves, so humans and agents can agree on scope, constraints,
and file layout up front.

## Layout

```
docs/superpowers/
├── specs/   # design documents: what & why, constraints, audit, approach
│   └── YYYY-MM-DD-<slug>-design.md
└── plans/   # step-by-step implementation plans: how, in what order
    └── YYYY-MM-DD-<slug>.md
```

Existing entry: the subtitle-track-picker split
([spec](specs/2026-07-07-subtitle-track-picker-split-design.md),
[plan](plans/2026-07-07-subtitle-track-picker-split.md), resolved issue #206).

## When to create an entry

Create a spec + plan pair when a refactor is:

- **Large** — touches a 1000+ LOC file or spans several files, and
- **Mechanical** — pure code motion / rename / regrouping with no intended
  behavior or API change, and
- **Risky to review as a raw diff** — a written audit and file map make the
  "nothing changed but locations" claim checkable.

Small fixes, behavior changes, and new features do **not** belong here: they
follow the normal flow (feature spec in [`docs/features/`](../features/),
irreversible choices as [ADRs](../decisions/README.md)).

## Spec format (`specs/YYYY-MM-DD-<slug>-design.md`)

Required sections, in order:

1. **Header** — date, linked issue, branch name, refactor type (e.g. "Pure
   mechanical refactor (no behavior or API change)").
2. **Goal** — one paragraph: what is split/moved and what "done" means.
3. **Constraints (non-negotiable)** — public API surface that must not change,
   external callers that require zero edits, the codebase idiom to follow
   (check [`docs/conventions.md`](../conventions.md) § Imports and existing
   precedents before choosing between separate libraries and `part` files).
4. **Audit findings** — what the originating (often automated) issue got
   wrong: mis-grouped symbols, inverted dependency direction, stale line
   counts. This section is mandatory because automated structural analyses
   drift from the real tree.
5. **Approach** — dependency-layer diagram plus a file table
   (`File | Contents | ~LOC`) for the target layout.

## Plan format (`plans/YYYY-MM-DD-<slug>.md`)

1. **Agentic execution header** — names the sub-skill / execution mode an
   agent must use, and states that steps use checkbox (`- [ ]`) syntax.
2. **Goal / Architecture / Tech Stack** — one line each, linking back to the
   spec.
3. **File Structure** — responsibility table for every touched file, plus the
   **rename map** when underscore-private symbols must cross file boundaries
   (Dart `_` is library-scoped: a symbol shared across separate libraries must
   be renamed to a plain feature-internal name).
4. **Tasks** — numbered, checkboxed, one per file/step, each independently
   green (`flutter analyze` + `flutter test`), ordered so every intermediate
   commit compiles.
5. **New tests** — any smoke test added to lock the refactor (e.g. a widget
   test proving the split sheet still renders).

## Relationship to other docs

| Doc | Role vs superpowers |
|-----|---------------------|
| [`docs/decisions/`](../decisions/README.md) | ADRs record **irreversible choices**; a superpowers spec assumes them (e.g. "no `part of` outside generated code" was a constraint in the picker split — note `app_database.dart` DAOs are the exception to that rule). |
| [`docs/features/`](../features/) | Feature behavior docs; a mechanical refactor must not require feature-doc edits. |
| [`docs/conventions.md`](../conventions.md) | Style / import rules the plan must obey. |
| [`AGENTS.md`](../../AGENTS.md) | Hard gates (green tree, codegen, no `print()`) apply to every plan task. |
