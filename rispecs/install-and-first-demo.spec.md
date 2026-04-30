# install-and-first-demo — Narrow First Demo Path

**Version**: 0.1.0  
**Status**: Draft  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Lane**: NORTH N1  
**Date**: 2026-04-29  
**Cross-references**: [`02-intent.md`](./02-intent.md), [`03-specify.md`](./03-specify.md), [`04-export.md`](./04-export.md)

---

## Desired Outcome

A practitioner runs the five commands below and sees a structural tension chart load in
coaia-visualizer, with a PDE markdown file, an STC JSONL, and a session summary as
artifacts on disk. No Hermes core file is edited. No governance, Veritas, or rebrand
decision is required.

---

## Zero-Core-Edit Path

The first demo uses **only** these three integration surfaces (see [`01-reverse-engineer.md`](./01-reverse-engineer.md)):

1. Profile isolation (`HERMES_HOME=~/.coaia-agent`)
2. MCP config block (mcp-pde + coaia-narrative declared in `config.yaml`)
3. COAIA RISE skills (installed in `~/.coaia-agent/skills/coaia/`)

No lifecycle plugin, no skin, no memory provider, no source edits.

**Grounding**: Runtime archaeology finding — "Setting `HERMES_HOME=~/.coaia-agent` before
any import creates a completely isolated COAIA profile … without changing a single line of
source code. This is the lowest-friction identity boundary available."

---

## Prerequisites

| Requirement | Check command |
|------------|---------------|
| Python ≥ 3.10 | `python --version` |
| Node.js ≥ 18 | `node --version` |
| npx (bundled with Node.js) | `npx --version` |
| Hermes installed (any method) | `hermes --version` OR `python -m hermes_cli.main --version` |
| mcp optional extra installed | `pip show hermes-agent \| grep mcp` |
| At least one LLM API key | `echo $OPENAI_API_KEY` or equivalent |

Install Hermes with MCP support if not already present:

```bash
pip install "hermes-agent[mcp]"
# or from the coaia-agent repo clone:
cd /a/src/coaia-agent && pip install -e ".[mcp]"
```

---

## Step 1 — Initialize COAIA Profile

```bash
export HERMES_HOME=~/.coaia-agent
mkdir -p ~/.coaia-agent/skills/coaia

hermes --setup
# Interactive setup: enter API key and accept defaults.
# Creates ~/.coaia-agent/config.yaml and ~/.coaia-agent/.env
```

**Expected artifact**: `~/.coaia-agent/config.yaml` exists.

---

## Step 2 — Configure MCP Servers

Append the MCP block to `~/.coaia-agent/config.yaml`:

```bash
cat >> ~/.coaia-agent/config.yaml << 'EOF'

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
EOF
```

**Expected artifact**: `config.yaml` contains both MCP server entries.

**Verify** (optional — starts servers and lists tools):

```bash
hermes tools list
# Output should include: pde_decompose, pde_list, pde_get,
#                        create_stc, perform_mmot_evaluation, etc.
```

---

## Step 3 — Install COAIA RISE Skills

Create the four skills that power the slash commands.

### `/pde` — PDE Decompose Skill

```bash
cat > ~/.coaia-agent/skills/coaia/pde-decompose.md << 'EOF'
---
name: pde-decompose
description: "Decompose current prompt via mcp-pde into a PDE folder artifact"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, pde, decomposition]
    category: coaia
---

# PDE Decompose

Call `pde_decompose` with the user's current prompt.
Store the result in the `.pde/` folder.
Report the PDE UUID and the path to `pde-<uuid>.md`.
EOF
```

### `/stc` — STC Create Skill

```bash
cat > ~/.coaia-agent/skills/coaia/stc-create.md << 'EOF'
---
name: stc-create
description: "Create a Structural Tension Chart JSONL from the current PDE decomposition"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, stc, structural-tension]
    category: coaia
---

# STC Create

Given the most recent PDE UUID from `.pde/`, call `coaia-pde import <pde-id>`
or `create_stc` via coaia-narrative MCP.
Report the path to the produced `.coaia/pde/<uuid>.jsonl`.
EOF
```

### `/summary` — Session Summary Skill

```bash
cat > ~/.coaia-agent/skills/coaia/session-summary.md << 'EOF'
---
name: session-summary
description: "Write a session summary narrative to the current PDE folder"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, summary, narrative]
    category: coaia
---

# Session Summary

Write a `session-summary.md` file to the current session's `.pde/<uuid>/` folder.
Include sections: Desired Outcome, Actions Taken, Open Questions, Next Session Inputs.
EOF
```

### `/rise` — Full RISE Session Skill

```bash
cat > ~/.coaia-agent/skills/coaia/rise-pde-session.md << 'EOF'
---
name: rise-pde-session
description: "Full RISE PDE session ceremony: decompose → STC → summary"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, rise, pde, stc, ceremony]
    category: coaia
---

# RISE PDE Session

Full ceremony sequence:
1. Call `/pde` to decompose the current prompt
2. Call `/stc` to create the STC JSONL
3. Call `/summary` to write the session summary
4. Report all artifact paths and invite the practitioner to load the JSONL in coaia-visualizer
EOF
```

**Expected artifacts**: Four `*.md` files in `~/.coaia-agent/skills/coaia/`.

---

## Step 4 — Run the First Demo Session

Open coaia-agent with the COAIA profile from the project working directory:

```bash
export HERMES_HOME=~/.coaia-agent
cd /a/src   # or any project working directory
hermes
```

At the prompt, run the full RISE ceremony:

```
> /rise
```

The agent will:
1. Call `pde_decompose` on the current conversation context
2. Write `.pde/<timestamp>--<uuid>/pde-<uuid>.md`
3. Call `coaia-pde import <pde-id>` or `create_stc`
4. Write `.coaia/pde/<uuid>.jsonl`
5. Write `.pde/<uuid>/session-summary.md`
6. Report all artifact paths

**Alternative — manual step-by-step**:

```
> Decompose this session into a RISE structural tension chart
> /pde
> /stc
> /summary
```

---

## Step 5 — Load in coaia-visualizer

Using the JSONL path reported in Step 4:

```bash
JSONL_PATH=".coaia/pde/<uuid>.jsonl"   # replace <uuid> with actual UUID
npx @jgwill/coaia-visualizer --memory-path "$JSONL_PATH"
```

Open the URL reported in the terminal (default: `http://localhost:3000`).

**Expected**: The coaia-visualizer displays a `structural_tension_chart` entity with at
least a `desired_outcome`, `current_reality`, and one or more `action_step` entities.

---

## Expected Artifacts

After a successful demo run, the following artifacts exist on disk:

```
.pde/
└── <YYYYMMDDHHMI>--<uuid>/
    ├── pde-<uuid>.md           ← Human-readable PDE decomposition (Four Directions)
    └── session-summary.md      ← Session narrative (Desired Outcome, Actions, Questions)

.coaia/
└── pde/
    └── <uuid>.jsonl            ← STC JSONL:
                                    line 1: pde_session (pdeDecompositionId link)
                                    line 2: entity (structural_tension_chart)
                                    line 3: entity (desired_outcome)
                                    line 4: entity (current_reality)
                                    lines 5–N: entity (action_step × N)
                                    lines N+1–M: relation lines
```

No `.hermes/` folders are created (profile is isolated in `~/.coaia-agent/`).  
No Hermes core source files are modified.

---

## Veritas (Optional — Not Required for Demo)

If Veritas evaluation is desired after the demo succeeds, add to `config.yaml`:

```yaml
veritas:
  enabled: true
  auto_create_companion: false   # set to true to create Veritas model at STC creation
  mmot_use_veritas: false        # set to true to route MMOT through Veritas
  local_eval_fallback: true      # no API key required for local evaluation
  api_base: "https://veritas.sanctuaireagentique.com"
```

**Important**: The first Veritas MMOT evaluation is demonstration, not trusted verdict
(bootstrap paradox). Do not surface the first result as a governance output.
See [`veritas-mmot-companion.spec.md`](./veritas-mmot-companion.spec.md) and `contradictions.md`.

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| `pde_decompose` not found in tool list | MCP block missing or mcp-pde spawn failed | Verify config.yaml MCP block; run `npx -y @jgwill/mcp-pde --version` manually |
| `.pde/` folder not created | mcp-pde returned an error | Check `~/.coaia-agent/logs/errors.log`; confirm `PDE_STORAGE_PATH` is writable |
| `.coaia/pde/` JSONL not created | coaia-narrative MCP not reachable | Verify coaia-narrative in tool list; check errors.log |
| Visualizer shows empty or no chart | JSONL path is wrong or JSONL is malformed | `cat .coaia/pde/<uuid>.jsonl \| head -5` — first line must be `{"type":"pde_session",...}` |
| Slash commands not found | Skills not installed in `HERMES_HOME/skills/coaia/` | Verify four `*.md` files exist in `~/.coaia-agent/skills/coaia/` |
| Wrong profile loaded | `HERMES_HOME` not exported | Run `echo $HERMES_HOME`; must equal `~/.coaia-agent` or the expanded path |

---

## What This Demo Does NOT Prove

- Lifecycle plugin automation (no plugin installed)
- Memory provider cross-session continuity
- Governance annotation or OCAP propagation
- Veritas companion bond
- ACP editor surface
- Any rebrand of Hermes binary names or `pyproject.toml`

These are Phase 1+ capabilities per [`03-specify.md`](./03-specify.md). The demo proves
the zero-core-edit integration path is viable. That is sufficient for this milestone.
