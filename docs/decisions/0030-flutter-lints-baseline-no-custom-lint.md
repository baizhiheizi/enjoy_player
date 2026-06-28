# ADR-0030: Expanded flutter_lints baseline; defer custom_lint

## Status

Accepted — 2026-06-29.

## Context

Issue #110 grouped several low-risk code-quality items. The lint baseline in
`analysis_options.yaml` was intentionally thin (four rules on top of
`flutter_lints`). The tech stack doc also noted that `custom_lint` was not
adopted because of analyzer-range friction with `drift_dev` and other
codegen packages.

`flutter_lints` 6.0.0 is available on pub.dev and matches the project's
Dart ^3.12 / Flutter 3.x toolchain.

## Decision

1. **Expand `analysis_options.yaml`** with additional core lints:
   `prefer_single_quotes`, `sort_constructors_first`, `require_trailing_commas`,
   `unawaited_futures`, `discarded_futures`, `cancel_subscriptions`,
   `close_sinks`, and `depend_on_referenced_packages`.

2. **Keep `flutter_lints: ^6.0.0`** — the caret range resolves to the current
   stable 6.x release.

3. **Do not adopt `custom_lint` yet.** Codegen (`drift_dev`, `riverpod_generator`,
   `json_serializable`) still pins a shared analyzer range; adding
   `custom_lint` + plugin packages would increase version-resolution churn
   without clear MVP benefit. Revisit when analyzer constraints align or
   when a specific custom rule becomes blocking.

4. **Remove legacy `@deprecated` color aliases** in `AppColors` once callers
   migrate to the `*Dark` names (no remaining references at time of adoption).

5. **Replace deprecated `RadioListTile` group API** with `RadioGroup` where
   subtitle track pickers still used the old pattern.

## Consequences

- `dart fix --apply` and `dart format` may touch many files when new rules
  land; run as part of the same PR.
- Stronger async hygiene lints (`unawaited_futures`, `discarded_futures`) may
  surface latent bugs — fix or explicitly `unawaited()` at call sites.
- `custom_lint` remains a documented follow-up, not a silent omission.
