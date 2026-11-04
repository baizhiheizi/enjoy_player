# Network proxy

Dart-side HTTP (`dart:io` `HttpClient`, and so `package:http`, `Image.network`)
follows the OS system proxy on desktop. See
[ADR-0103](../decisions/0103-proxy-aware-http-stack.md).

| Platform | Source |
| --- | --- |
| macOS | `scutil --proxy` (`HTTP*`/`HTTPS*` + `ExceptionsList`) |
| Windows | `HKCU\…\Internet Settings` (`ProxyEnable`, `ProxyServer` single or per-protocol, `ProxyOverride`) |
| Linux | `http(s)_proxy` / `all_proxy` env via Dart's default resolution |
| Android / iOS | not readable; direct (route-level VPNs apply) |

Rules: `localhost` / loopback always direct; exception list honored (`*.x`,
`.x`, exact host, `<local>`); SOCKS-only and PAC proxies are unsupported; the
system proxy is re-read every 60 s.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Video plays, captions unavailable | VPN in system-proxy mode before this fix; now follows the proxy. If still failing, check the log line `network proxy: …` and try TUN mode |
| `network proxy: direct source=none` while a proxy is set | SOCKS-only or PAC proxy |
