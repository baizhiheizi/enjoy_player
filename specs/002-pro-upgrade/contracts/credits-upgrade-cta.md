# Contract: Credits Upgrade CTA

**Feature**: `002-pro-upgrade` | **Consumer**: AI feature error surfaces | **Version**: 1.0

## Purpose

When AI Worker returns HTTP 402, guide users to subscription management (User Story 4, FR-012, SC-004).

## Trigger

`AppFailure` instance of `CreditsFailure` from `mapApiExceptionToAppFailure` when `ApiException.statusCode == 402`.

## Presentation

Use existing notice patterns (`AppNotice`, snackbar, or inline error row with action — match nearest AI surface).

| Element | Requirement |
|---------|-------------|
| Message | Server message or localized fallback (`subscriptionCreditsLimitMessage`) |
| Primary action label | Localized (`subscriptionViewPlans` or `subscriptionUpgrade`) |
| Primary action | `context.push('/subscription')` or `context.go` if not in shell |
| Secondary | Dismiss only |

## Platform behavior after navigation

| Platform | User lands on |
|----------|---------------|
| Desktop | Subscription screen with purchase available |
| iOS / Android | Subscription screen with coming-soon on upgrade tap |

## Minimum wiring scope (v1)

Implement shared helper:

```dart
void showCreditsFailureWithUpgradeAction(BuildContext context, CreditsFailure failure);
```

Wire into at least:

1. One transcript/lookup AI error path (high visibility)
2. Document additional surfaces for `/speckit-tasks` follow-up if not all AI paths wired in v1

## Scenarios

### C1 — Desktop credits exhausted

- **WHEN** AI call returns 402 on Windows
- **THEN** notice shows with upgrade action → `/subscription` → purchase sheet available

### C2 — iOS credits exhausted

- **WHEN** AI call returns 402 on iOS
- **THEN** notice shows with upgrade action → `/subscription` → upgrade shows coming-soon (no external URL)

### C3 — Already Pro but credits exhausted

- **WHEN** Pro user hits daily limit (402)
- **THEN** still navigate to subscription for status/context; copy may differ (“daily limit reached” vs “upgrade”) — use server message when present
