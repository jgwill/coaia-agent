# COAIA RISE Skills

Prompt skills for the COAIA RISE (Reflective Iterative Session Engine) ceremony workflow.

These skills work with the `mcp-pde` and `coaia-narrative` MCP servers to guide a
practitioner through a full Prompt Decomposition Engine → Structural Tension Chart session.

## Skills

| Skill file | Slash command | Stage |
|---|---|---|
| `pde-decompose.md` | `/pde` | Stage 1 — Decompose |
| `stc-create.md` | `/stc` | Stage 2 — Import STC |
| `session-summary.md` | `/summary` | Stage 4 — Session Close |
| `rise-pde-session.md` | `/rise` | Full ceremony (all stages) |

## Prerequisites

- `HERMES_HOME=~/.coaia-agent` must be set before starting the agent
- `mcp-pde` and `coaia-narrative` MCP servers declared in `config.yaml`
- At least one LLM API key configured

See `rispecs/install-and-first-demo.spec.md` for the complete setup guide.
