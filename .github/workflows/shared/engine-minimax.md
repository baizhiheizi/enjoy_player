---
max-ai-credits: -1
engine:
  id: claude
  env:
    ANTHROPIC_BASE_URL: "https://api.minimaxi.com/anthropic"
    ANTHROPIC_MODEL: "MiniMax-M3"
    API_TIMEOUT_MS: "3000000"
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
    CLAUDE_CODE_AUTO_COMPACT_WINDOW: "512000"
network:
  allowed:
    - defaults
    - api.minimaxi.com
---

## Outbound network

Agentic workflows that import this component route inference through the **MiniMax Anthropic-compatible proxy** ([ADR-0028](../../docs/decisions/0028-agentic-engine-choice.md)):

| Endpoint | Purpose |
|----------|---------|
| `api.minimaxi.com` | LLM inference (`ANTHROPIC_BASE_URL`) |
| `defaults` (gh-aw) | GitHub API, container registries, MCP servers, OS package mirrors |

Additional ecosystem identifiers (`dart`, `node`, etc.) may be declared per workflow. Egress outside the compiled allow-list is blocked by the Agent Workflow Firewall (AWF).

## Known risk

Inference requests may include issue/PR text and repository source. Zero-retention guarantees from the proxy provider have **not** been independently verified — treat as **medium** data-egress risk (ADR-0028).
