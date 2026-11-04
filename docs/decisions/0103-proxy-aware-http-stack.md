# ADR-0103: Proxy-aware Dart HTTP stack via `HttpOverrides.global`

**Status**: Accepted (2026-11-04)
**Related**: [#1220](https://github.com/baizhiheizi/enjoy_player/issues/1220),
[docs/features/network-proxy.md](../features/network-proxy.md),
[docs/features/transcript.md](../features/transcript.md)

## Context

Dart's `dart:io` `HttpClient` ignores the OS system proxy on macOS and Windows.
Webview playback and the browser extension honor it. Behind a system-proxy-only
VPN (Clash / sing-box without TUN) video plays but every Dart-side request —
the YouTube InnerTube caption fetch, worker cache GETs, oEmbed, thumbnails,
BYOK endpoints — connects directly and fails (#1220).

## Decision

- `lib/core/network/proxy/` resolves the system proxy (macOS `scutil --proxy`,
  Windows `reg query` of Internet Settings) with pure parsers and a 60 s
  refresh, exposed synchronously through `SystemProxyCoordinator.findProxy`.
- `ProxyHttpOverrides` is installed as `HttpOverrides.global` in `main()`, so
  every `dart:io`-backed client is proxy-aware with no call-site sweep.
- Loopback hosts and the system exception list always bypass. When no system
  proxy is found, resolution falls back to
  `HttpClient.findProxyFromEnvironment` (Linux env vars, unchanged behavior).
- The effective proxy is logged (`network proxy: …`) at startup and on change,
  host:port only.

## Deferred

Manual / direct modes with a Settings → Network section, test-connection and
the transport-failure hint on caption errors are follow-ups from the #1220
design; the OS-proxy path here fixes the reported failure on its own.
