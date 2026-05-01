# COAIA Profile Setup Guide

This guide walks you through creating an isolated COAIA profile for `coaia-agent`
using the zero-core-edit path: profile isolation, MCP config, and RISE skills.
No Hermes source files are modified.

**Spec reference**: `rispecs/install-and-first-demo.spec.md`

---

## Prerequisites

| Requirement | Check command |
|---|---|
| Python ≥ 3.10 | `python --version` |
| Node.js ≥ 18 | `node --version` |
| npx (bundled with Node.js) | `npx --version` |
| hermes-agent installed | `hermes --version` |
| mcp optional extra | `pip show hermes-agent | grep -i mcp` |
| At least one LLM API key | `echo $OPENAI_API_KEY` (or equivalent) |

Install hermes-agent with MCP support if needed:

```bash
pip install "hermes-agent[mcp]"
# or from this repo:
pip install -e ".[mcp]"
```

---

## Step 1 — Initialize COAIA Profile

```bash
export HERMES_HOME=~/.coaia-agent
mkdir -p ~/.coaia-agent/skills/coaia

hermes --setup
# Interactive: enter your API key and accept defaults.
# Creates ~/.coaia-agent/config.yaml and ~/.coaia-agent/.env
```

**Expected artifact**: `~/.coaia-agent/config.yaml` exists.

Verify the profile isolation:

```bash
echo $HERMES_HOME   # must print: ~/.coaia-agent (or the expanded path)
```

---

## Step 2 — Configure MCP Servers

Append the COAIA MCP server block to `~/.coaia-agent/config.yaml`:

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

**Verify** (optional — starts MCP servers and lists tools):

```bash
export HERMES_HOME=~/.coaia-agent
hermes tools list
# Expected tools: pde_decompose, pde_list, pde_get, create_stc, perform_mmot_evaluation, ...
```

---

## Step 3 — Install COAIA RISE Skills

Copy the bundled COAIA skills from the repo into your COAIA profile:

```bash
export HERMES_HOME=~/.coaia-agent

# From the coaia-agent repo root:
cp -r skills/coaia/* ~/.coaia-agent/skills/coaia/
```

**Expected artifacts**: four `*.md` skill files in `~/.coaia-agent/skills/coaia/`.

```
~/.coaia-agent/skills/coaia/
├── DESCRIPTION.md
├── pde-decompose.md      → /pde
├── stc-create.md         → /stc
├── session-summary.md    → /summary
└── rise-pde-session.md   → /rise
```

---

## Step 4 — (Optional) Install the Lifecycle Plugin

For Phase 1 automation (artifacts created and finalized without manual `/pde` `/stc` `/summary` invocations), install the bundled lifecycle plugin:

```bash
mkdir -p ~/.coaia-agent/plugins/coaia-lifecycle
cp -r plugins/coaia-lifecycle/* ~/.coaia-agent/plugins/coaia-lifecycle/
```

The plugin wires `on_session_start`, `post_tool_call`, and `on_session_end` hooks
to track PDE and STC artifacts automatically.

---

## Step 5 — Run the First Demo Session

```bash
export HERMES_HOME=~/.coaia-agent
cd /your/project/dir    # working directory where .pde/ and .coaia/ will be created
hermes
```

At the prompt, run the full RISE ceremony:

```
> /rise
```

The agent will:
1. Call `pde_decompose` on your current session context
2. Write `.pde/<timestamp>--<uuid>/pde-<uuid>.md`
3. Call `create_stc` to produce `.coaia/pde/<session-uuid>.jsonl`
4. Write `.pde/<timestamp>--<uuid>/session-summary.md`
5. Report all artifact paths

**Alternative — step by step:**

```
> Decompose this session into a RISE structural tension chart
> /pde
> /stc
> /summary
```

---

## Step 6 — Load in coaia-visualizer

```bash
npx @jgwill/coaia-visualizer --memory-path .coaia/pde/<session-uuid>.jsonl
```

Open `http://localhost:3000` (default port). The visualizer displays the STC with
`structural_tension_chart`, `desired_outcome`, `current_reality`, and `action_step` entities.

---

## Expected Artifacts

After a successful demo:

```
<workdir>/
├── .pde/
│   └── <YYMMDDHHMI>--<pde-uuid>/
│       ├── pde-<pde-uuid>.md          ← Human-readable PDE (Four Directions)
│       ├── pde-<pde-uuid>.json        ← StoredDecomposition JSON
│       ├── .coaia-agent-session.json  ← Session state (lifecycle plugin)
│       └── session-summary.md        ← Session close narrative
└── .coaia/
    └── pde/
        └── <session-uuid>.jsonl       ← STC JSONL (visualizer-ready)
```

No `.hermes/` folders are created (profile isolated in `~/.coaia-agent/`).
No Hermes core source files are modified.

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---|---|---|
| `pde_decompose` not found | MCP block missing or mcp-pde failed | Check `config.yaml` MCP block; run `npx -y @jgwill/mcp-pde --version` |
| `.pde/` not created | mcp-pde returned an error | Check `~/.coaia-agent/logs/errors.log` |
| `.coaia/pde/` JSONL not created | coaia-narrative MCP not reachable | Verify coaia-narrative in `hermes tools list` |
| Visualizer shows empty chart | JSONL path wrong or malformed | `cat .coaia/pde/<uuid>.jsonl \| head -5` — first line must be `{"type":"pde_session",...}` |
| Slash commands not found | Skills not in profile | Verify `~/.coaia-agent/skills/coaia/*.md` exists |
| Wrong profile loaded | `HERMES_HOME` not exported | `echo $HERMES_HOME` must equal `~/.coaia-agent` |

---

## Phase 0 Exit Criteria

- [ ] `HERMES_HOME=~/.coaia-agent` creates an isolated COAIA profile
- [ ] `hermes tools list` shows `pde_decompose` and `create_stc`
- [ ] `/pde` produces `.pde/<ts>--<uuid>/pde-<uuid>.md`
- [ ] `/stc` produces `.coaia/pde/<session-uuid>.jsonl` (passes 4-pass visualizer parse)
- [ ] `/summary` writes `session-summary.md` to the PDE folder
- [ ] No Hermes core file (`run_agent.py`, `cli.py`, `model_tools.py`, etc.) was modified

## Phase 1 Exit Criteria

- [ ] `coaia-lifecycle` plugin installed and `register()` loads without errors
- [ ] `on_session_start` creates session state in memory
- [ ] `post_tool_call` captures PDE UUID and STC session UUID from tool results
- [ ] `on_session_end` persists `.coaia-agent-session.json` and writes summary stub
- [ ] Session can be recovered from `.coaia-agent-session.json` after a crash
- [ ] All `action_step` direction values are normalized to UPPERCASE
- [ ] JSONL parses in coaia-visualizer without schema changes
