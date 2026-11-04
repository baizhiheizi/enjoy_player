# Network proxy

Dart-side HTTP (`dart:io` `HttpClient`, and so `package:http`, `Image.network`)
follows the OS system proxy on desktop. See
[ADR-0103](../decisions/0103-proxy-aware-http-stack.md).

| Platform | Source |
| --- | --- |
| macOS | `scutil --proxy` (`HTTP*`/`HTTPS*` + `ExceptionsList`) |
| Windows | `HKCU\…\Internet Settings` (`ProxyEnable`, `ProxyServer` single or per-protocol, `ProxyOverride`) |
| Linux | `http_proxy` / `https_proxy` / `no_proxy` environment variables via Dart's default resolution (per-scheme: `https_proxy` must be set for HTTPS requests such as captions) |
| Android / iOS | not readable; direct (route-level VPNs apply) |

## Settings → Network

Mode selector, stored device-scope in `network.proxyMode` / `network.proxyUrl`:

| Mode | Behavior |
| --- | --- |
| System (default) | Follow the OS proxy per the table above |
| Manual | Use the saved `host:port` / `http://host:port` for every host except loopback; SOCKS addresses are rejected |
| Direct | Never use a proxy, even if the OS or environment sets one |

Precedence: manual → direct → system → none (direct). The section also shows
the effective proxy (endpoint and source) and a **Test connection** button that
re-resolves, then probes the Enjoy API base and YouTube and reports the route
and latency of each.

When every InnerTube caption profile fails at the transport level
(socket / TLS / timeout), the caption error gains a `Hint:` line that names the
current mode and suggests TUN mode or a manual proxy.

Rules: `localhost` / loopback always direct; exception list honored (`*.x`,
`.x`, exact host, `<local>`); SOCKS-only and PAC proxies are unsupported; the
system proxy is re-read every 60 s. In Manual mode the bypass list is loopback only.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Video plays, captions unavailable | VPN in system-proxy mode before this fix; now follows the proxy. If still failing, check the log line `network proxy: …` and try TUN mode |
| `network proxy: direct source=none` while a proxy is set | SOCKS-only or PAC proxy |
