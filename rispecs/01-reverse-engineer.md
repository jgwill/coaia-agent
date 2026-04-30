# 01 — Reverse Engineering: Hermes Runtime → COAIA Integration Surfaces

**Version**: 0.1.0  
**Status**: Draft  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Lane**: NORTH N1  
**Date**: 2026-04-29  
**Cross-references**: [`00-source-survey.md`](./00-source-survey.md), [`02-intent.md`](./02-intent.md), [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md)  
**SOUTH grounding**: [`findings-runtime-archaeology.md`](../../.pde/2604291305-coaia-agent-rispecs/deep-search/findings-runtime-archaeology.md)

---

## Purpose

This document maps every confirmed Hermes 0.11.0 runtime surface to its corresponding
COAIA integration surface. It is the engineering foundation for the component specs
authored by other lanes. Read it before reading `03-specify.md`.

The integration principle throughout: **extend, do not modify**. Every COAIA capability
attaches via an existing extension point. The constraint (AGENTS.md, Teknium May 2026):
plugins MUST NOT modify core files.

---

## Hermes Runtime Architecture (as-found)

```
hermes_constants.py          ← HERMES_HOME resolution (profile isolation root)
    │
    ├── run_agent.py          ← AIAgent conversation loop (max_iterations=90)
    │       ├── model_tools.py    ← triggers tool auto-discovery at import
    │       │       └── tools/registry.py   ← register() + toolsets.py
    │       ├── hermes_cli/plugins.py       ← lifecycle hooks
    │       └── agent/memory_manager.py     ← pluggable memory backends
    │
    ├── hermes_cli/main.py    ← interactive CLI; profile override; skin loading
    │       ├── agent/skill_commands.py     ← slash commands; skill injection
    │       └── hermes_cli/skin_engine.py   ← HERMES_HOME/skins/*.yaml
    │
    ├── mcp_serve.py          ← MCP server (10 tools for conversation access)
    ├── batch_runner.py       ← parallel trajectory generation
    ├── cron/                 ← scheduled agent runs
    ├── gateway/run.py        ← webhook-triggered agent runs
    ├── acp_adapter/          ← VS Code / Zed / JetBrains ACP surface
    └── hermes_state.py       ← SessionDB (SQLite FTS5; join key for genealogy)
```

---

## Surface-by-Surface Mapping

### 1. Profile / Home Isolation

**Hermes surface**: `hermes_constants.py:get_hermes_home()`

```python
def get_hermes_home() -> Path:
    val = os.environ.get("HERMES_HOME", "").strip()
    return Path(val) if val else Path.home() / ".hermes"
```

**COAIA integration surface**: `HERMES_HOME=~/.coaia-agent`

Setting this env var before any import creates a fully isolated COAIA profile:
config, secrets, sessions, memory, skills, logs, skins, plugins, and gateway state.
No source file change is required.

```
~/.coaia-agent/
├── config.yaml           ← COAIA runtime config (MCP servers, skin, toolsets)
├── .env                  ← Secrets only (OPENAI_API_KEY, COAIA_MCP_PDE_URL, etc.)
├── skins/coaia.yaml      ← COAIA brand skin
├── skills/coaia/         ← COAIA RISE skills (/pde, /stc, /rise, /coaia)
├── plugins/coaia-lifecycle/  ← Lifecycle hooks (on_session_start/end)
└── logs/                 ← agent.log, errors.log, gateway.log
```

**Spec owner**: [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md) (other lane)

---

### 2. Tool Registration

**Hermes surface**: `tools/registry.py` + `toolsets.py`

Any `tools/*.py` calling `registry.register()` at import time is auto-discovered via
`model_tools.py`. A new `"coaia"` toolset can be added to `toolsets.py` as opt-in.

**COAIA integration surface**: `tools/coaia_pde_tool.py`, `tools/coaia_stc_tool.py`

```python
registry.register(
    name="pde_decompose",
    toolset="coaia",
    schema={ "name": "pde_decompose", "description": "...", "parameters": {...} },
    handler=lambda args, **kw: call_mcp_pde(args),
    check_fn=lambda: bool(os.getenv("COAIA_MCP_PDE_URL")),
    requires_env=["COAIA_MCP_PDE_URL"],
)
```

**Alternative** (no new tool file): declare `mcp-pde` in the MCP config block; the
existing MCP client handles tool exposure transparently.

**Spec owner**: [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md)

---

### 3. MCP Client Configuration

**Hermes surface**: `hermes_cli/config.py` + `pyproject.toml[mcp]` optional dependency

`mcp>=1.2.0,<2` is an optional dependency. MCP servers are declared in `HERMES_HOME/config.yaml`
under the MCP servers block. The existing client loads them automatically when
`hermes-agent[mcp]` is installed.

**COAIA integration surface**: Config block in `~/.coaia-agent/config.yaml`

```yaml
mcp:
  servers:
    mcp-pde:
      command: npx
      args: ["-y", "@jgwill/mcp-pde"]
      env:
        PDE_STORAGE_PATH: "${COAIA_PDE_PATH:-.pde}"
    coaia-narrative:
      command: npx
      args: ["-y", "@avadisabelle/coaia-narrative"]
      env:
        MEMORY_PATH: "${COAIA_NARRATIVE_PATH:-.coaia}"
```

No adapter code is required. mcp-pde and coaia-narrative tools become available to the
conversation loop as first-class tools.

**Spec owner**: [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md)

---

### 4. Lifecycle Plugin Hooks

**Hermes surface**: `hermes_cli/plugins.py`

Plugins discovered from:
- `HERMES_HOME/plugins/`
- `./.hermes/plugins/` (repo-local)
- pip entry points

Each plugin exposes `register(ctx)` and may call `ctx.register_hook(event, handler)`.
Available events: `on_session_start`, `on_session_end`, `pre_tool_call`, `post_tool_call`,
`pre_llm_call`, `post_llm_call`.

**COAIA integration surface**: `~/.coaia-agent/plugins/coaia-lifecycle/__init__.py`

```python
def register(ctx):
    ctx.register_hook("on_session_start", coaia_session_start)
    ctx.register_hook("on_session_end",   coaia_session_end)
    ctx.register_hook("post_tool_call",   coaia_capture_context)
```

| Hook | COAIA action |
|------|-------------|
| `on_session_start(session_id, ...)` | Create `.pde/<timestamp>--<session_id>/`; write `meta.json` (miaco v2 contract); initialize STC chart |
| `on_session_end(session_id, messages, ...)` | Invoke coaia-pde STC mapper; write `.coaia/pde/<session_id>.jsonl`; finalize narrative beat |
| `post_tool_call(tool_name, result, ...)` | Capture tool result context for `current_reality` accumulation in the STC |

**Spec owner**: [`skill-and-plugin-authoring.spec.md`](./skill-and-plugin-authoring.spec.md) (other lane),
[`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md) (other lane)

---

### 5. Memory Provider

**Hermes surface**: `agent/memory_provider.py` (`MemoryProvider` ABC)

Required methods: `sync_turn(turn_messages)`, `prefetch(query)`, `shutdown()`.
Optional: `post_setup(hermes_home, config)`.

**COAIA integration surface**: `CoaiaNarrativeMemoryProvider`

Implements `MemoryProvider`; on each `sync_turn()` appends relational context as a
narrative beat to `.coaia/pde/<session_id>.jsonl`. On `prefetch()` reads prior JSONL
sessions for cross-session continuity. Join key: `SessionDB` session ID ↔ PDE folder
`session_id` field.

**Spec owner**: [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md)

---

### 6. Skill System

**Hermes surface**: `agent/skill_commands.py` + `HERMES_HOME/skills/`

Slash commands scan `HERMES_HOME/skills/`, inject `SKILL.md` content as a **user message**
(not system prompt) to preserve prompt caching. Frontmatter controls discoverability.

**COAIA integration surface**: `~/.coaia-agent/skills/coaia/`

| Skill file | Slash command | COAIA function |
|-----------|---------------|----------------|
| `rise-pde-session.md` | `/coaia-rise` | Full RISE PDE session ceremony |
| `pde-decompose.md` | `/pde` | Decompose current prompt via mcp-pde |
| `stc-create.md` | `/stc` | Create STC from current decomposition |
| `session-summary.md` | `/summary` | Generate session summary narrative beat |

**SKILL.md frontmatter shape** (required fields):

```yaml
---
name: rise-pde-session
description: "Full RISE PDE session ceremony via mcp-pde and coaia-pde"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, rise, pde, stc]
    category: coaia
---
```

**Spec owner**: [`skill-and-plugin-authoring.spec.md`](./skill-and-plugin-authoring.spec.md)

---

### 7. Skin Engine

**Hermes surface**: `hermes_cli/skin_engine.py` + `HERMES_HOME/skins/*.yaml`

Skins customize: banner colors, spinner faces/verbs/wings, tool prefix, response box
label, agent name, welcome message, and prompt symbol. Active skin set via
`display.skin: coaia` in `config.yaml`.

**COAIA integration surface**: `~/.coaia-agent/skins/coaia.yaml`

```yaml
name: coaia
branding:
  agent_name: "COAIA Agent"
  welcome: "Structural Tension. Creative Orientation. Welcome."
  response_label: " ◈ COAIA "
  prompt_symbol: "◇"
colors:
  banner: "#4A9EFF"
spinner:
  faces: ["◇", "◈", "◉", "◈"]
  verb: "weaving"
```

**Identity tension**: This skin does not constitute a rebrand decision. It is a display
layer only. The `hermes` and `hermes-agent` binary names, `pyproject.toml`, and upstream
attribution remain unchanged until a human steward makes the rebrand decision.
See `contradictions.md`.

---

### 8. Slash Commands

**Hermes surface**: `hermes_cli/commands.py:COMMAND_REGISTRY`

Each entry is a `CommandDef(name, description, category, aliases, args_hint)`.

**COAIA integration surface**: Add `CommandDef` entries for COAIA slash commands.
This is a **source edit** (not zero-core-edit), so it is deferred to a later phase
or implemented as a plugin-registered CLI extension via `ctx.register_cli_command()`.

| Slash | Alias | Category | Maps to |
|-------|-------|----------|---------|
| `/pde` | `/decompose` | COAIA | `pde_decompose` tool or mcp-pde |
| `/stc` | | COAIA | `create_stc` via coaia-narrative MCP |
| `/rise` | `/coaia-rise` | COAIA | `rise-pde-session` skill |
| `/summary` | | COAIA | `session-summary` skill |

---

### 9. Cron and Webhook Automation

**Hermes surface**: `cron/jobs.py`, `cron/scheduler.py`, `hermes webhook subscribe`

**COAIA integration surface**: Scheduled nightly RISE sessions; GitHub issue-triggered
coaia-agent sessions (Miadi-compatible).

```bash
hermes cron create "0 2 * * *" \
  "Run COAIA RISE session on open STCs" \
  --skills "coaia-rise" \
  --name "nightly-stc-review"

hermes webhook subscribe github.issue_opened \
  --filter 'body contains "COAIA:"' \
  --skills "coaia-rise" \
  --name "coaia-issue-trigger"
```

No new runtime code. Available immediately after install.

---

### 10. ACP Adapter

**Hermes surface**: `acp_adapter/`, `hermes-acp` entry point

Exposes ACP server for VS Code, Zed, JetBrains. Tools: conversation access, permission
management, event polling.

**COAIA integration surface**: PDE folder and STC JSONL sessions surfaced in VS Code
sidebar via ACP without a new server architecture. The `acp_adapter/tools.py` extension
surface allows adding PDE-aware tool handlers.

**Spec owner**: [`acp-and-gateway-surfaces.spec.md`](./acp-and-gateway-surfaces.spec.md) (other lane)

---

### 11. Session Storage — Join Key

**Hermes surface**: `hermes_state.py:SessionDB` (SQLite FTS5)

Stores complete conversation histories. Session IDs are the primary identity key.

**COAIA integration surface**: `SessionDB.session_id` ↔ `.pde/<timestamp>--<session_id>/meta.json.session_id`

This field-level join (not filesystem) is the bridge between Hermes session recall and
COAIA PDE genealogy. An implementation can query `SessionDB` for session context and
load the corresponding `.pde/` folder for STC provenance — without a new index.

---

### 12. Context Files (AGENTS.md)

**Hermes surface**: `AGENTS.md` loaded from CWD at session start (`skip_context_files=False` default)

**COAIA integration surface**: `AGENTS.md` in working directory or project root

Place ceremony context, STC constraints, and RISE phase guidance in `AGENTS.md`. The
runtime injects these as context at every session start, making COAIA orientation
automatic without any config change.

---

## Zero-Core-Edit Path Summary

The following integration surfaces require **zero source file edits** to Hermes core:

| Surface | Mechanism |
|---------|-----------|
| Profile isolation | `HERMES_HOME=~/.coaia-agent` env var |
| MCP server connection | `config.yaml` MCP block |
| RISE skills | Files in `~/.coaia-agent/skills/coaia/` |
| Lifecycle hooks | Plugin in `~/.coaia-agent/plugins/coaia-lifecycle/` |
| Brand skin | `~/.coaia-agent/skins/coaia.yaml` + `display.skin: coaia` |
| Ceremony context | `AGENTS.md` in working directory |
| Cron/webhook automation | `hermes cron create` / `hermes webhook subscribe` |

The following require **source additions** (new files, not modifications to existing files):

| Surface | New file |
|---------|---------|
| COAIA tool registration | `tools/coaia_pde_tool.py`, `tools/coaia_stc_tool.py` |
| COAIA toolset | Addition to `toolsets.py` (new entry, not edit of existing) |
| Slash command entries | Addition to `commands.py` `COMMAND_REGISTRY` (new entries) |

Slash command additions are the only surface that touches an existing list — they append
entries and do not modify existing `CommandDef` objects, maintaining the MUST NOT modify
core files constraint.

---

## Surfaces Authored by Other Lanes

The following surfaces are catalogued here but fully specified by other NORTH lanes:

| Surface | Spec file |
|---------|-----------|
| PDE → STC JSONL lifecycle (3 input paths) | `pde-stc-session-lifecycle.spec.md` |
| JSONL metadata for visualizer compatibility | `visualizer-planning-narrative-flow.spec.md` |
| Governance annotation, OCAP, consent | `medicine-wheel-governance.spec.md` |
| Veritas companion and MMOT loop | `veritas-mmot-companion.spec.md` |
| Kinship hub relation | `relation-to-mcp-structural-thinking.kin.md` |
