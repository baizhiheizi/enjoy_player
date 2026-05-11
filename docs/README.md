# Documentation index

Maintainers and agents should keep these files **accurate** when behavior or architecture changes.

| Path | Audience | Update when |
|------|----------|-------------|
| [AGENTS.md](../AGENTS.md) | AI agents | Global rules change |
| [architecture.md](architecture.md) | Everyone | Layers, providers, or DB schema change |
| [tech-stack.md](tech-stack.md) | Everyone | Dependencies or versions change |
| [conventions.md](conventions.md) | Contributors | Style / lint / folder rules change |
| [packaging.md](packaging.md) | Release | Platform build / signing / store prep |
| [testing.md](testing.md) | Contributors | Test strategy or CI commands change |
| [decisions/](decisions/) | Architects | Irreversible technical choices |
| [features/](features/) | Product + dev | Feature behavior changes |
| [features/app-ui.md](features/app-ui.md) | Product + dev | Shell, navigation chrome, or design tokens change |
| [features/hotkeys.md](features/hotkeys.md) | Product + dev | Keyboard shortcuts or customization behavior changes |
| [features/auth.md](features/auth.md) | Product + dev | Sign-in, profile, API base URL, or settings sync behavior changes |
| [features/ai.md](features/ai.md) | Product + dev | AI worker capabilities, playground, or provider matrix behavior changes |
| [features/sync.md](features/sync.md) | Product + dev | Cloud metadata sync (library + recordings + queue) behavior changes |
| [features/cloud.md](features/cloud.md) | Product + dev | Remote media index (add-to-library) behavior changes |

## How to add an ADR

1. Copy the template in [decisions/README.md](decisions/README.md).  
2. Use the next number: `000N-short-title.md`.  
3. **Do not rewrite old ADRs** — supersede with a new one.

## How to update a feature spec

Edit the matching file under [features/](features/) in the **same PR** as the code change.
