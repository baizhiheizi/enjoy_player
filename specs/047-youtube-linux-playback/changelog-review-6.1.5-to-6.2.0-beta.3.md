# Changelog review: flutter_inappwebview 6.1.5 → 6.2.0-beta.3

**Date**: 2026-10-02 · **Task**: T035 (specs/047) · **Gate**: contracts/platform-smoke-checklist.md C1–C12 on Android/iOS/macOS/Windows must pass with `behaviorDiff: none`.

Source: github.com/pichillilorenzo/flutter_inappwebview/releases (beta.1 2025-11-05, beta.2 2025-11-26, beta.3 2026-02-04).

## Items that touch surfaces the app uses

| Change | Version | App surface | Risk | Covered by |
|--------|---------|-------------|------|------------|
| JS-bridge security settings (`javaScriptBridgeEnabled`, origin allow-lists) | beta.1 | Page→Dart `callHandler('onVideoEvent'/'onAdReload')` from m.youtube.com — the engine's event spine | If defaults tightened, events stop → playback dead | C1 (open+play), C5/C6 (captions) — events failing is immediately visible |
| `JavaScriptHandlerCallback` deprecated → `JavaScriptHandlerFunction` | beta.1 | `addJavaScriptHandler` callbacks in `youtube_webview_controller.dart` | Deprecated-but-working (analyze clean); migrate in a follow-up | — (no behavior) |
| Event-handler return types `Future` → `FutureOr` | beta.2 | `shouldOverrideUrlLoading` (sign-in nav cancel, ADR-0025) | Compatible (async still allowed) | C8 |
| Windows transparent-background fix (#2391) | beta.1 | Player sets `transparentBackground: true` | Intended fix; Windows player background may change appearance | C1/C2 visual |
| Windows WebView2 SDK bumps (1.0.2849.39 → 1.0.3650.58) | beta.2/3 | Whole Windows webview | SDK-refresh risk | C1–C12 |
| Windows `scrollMultiplier` default 6 → 1 | beta.1 | In-webview scrolling feel | Minor UX | C1 |
| Windows `WebViewEnvironment` dispose crash fix (#2433) | beta.3 | We share one environment app-wide (positive) | Positive | C11 |
| iOS windowId JS-handler callbacks fix (#2393) | beta.3 | iOS YouTube engine | Positive | C1 |
| iOS/macOS Swift Package Manager support | beta.3 | iOS/macOS build system | Build-level, not runtime | CI (T036) + C1–C12 |
| Minimums raised: Dart ^3.8 / Flutter ≥3.32 | beta.3 | Repo pins Flutter 3.44 / Dart 3.12 ✓ | None | — |
| Headless/`requestFocus`/`onProcessFailed` additions | beta.1–3 | Not used by the engine today | None (future: requestFocus for the ADR-0066 focus policy) | — |

## Verdict

No change found that alters the app's contract on the four healthy platforms by
itself; the two watch items are the JS-bridge security defaults (C1 catches any
event-pipeline break immediately) and the Windows SDK bump (broad but covered by
the full checklist). Merge gate stays: CI matrix green + C1–C12 `behaviorDiff:
none` on all four platforms (US5).
