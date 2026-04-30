# 04 — Export: Handoff Sequence and Validation Notes

**Version**: 0.1.0  
**Status**: Draft  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Lane**: NORTH N1  
**Date**: 2026-04-29  
**Cross-references**: [`02-intent.md`](./02-intent.md), [`03-specify.md`](./03-specify.md), [`install-and-first-demo.spec.md`](./install-and-first-demo.spec.md)

---

## Purpose

This document gives the implementation team the **ordered handoff sequence**, install and
run expectations, export conventions, and validation checkpoints needed to begin
implementation without attending the authoring session.

---

## Handoff Sequence

### Step 1 — Read the RISE Pack (before touching any code)

Read in order:

1. [`README.md`](./README.md) — scope and reading order
2. [`00-source-survey.md`](./00-source-survey.md) — repo map; required vs optional
3. [`01-reverse-engineer.md`](./01-reverse-engineer.md) — Hermes surfaces → COAIA surfaces
4. [`02-intent.md`](./02-intent.md) — desired outcome, current reality, non-goals, human-gated decisions
5. [`03-specify.md`](./03-specify.md) — architecture overview and component spec index
6. [`04-export.md`](./04-export.md) ← you are here
7. [`install-and-first-demo.spec.md`](./install-and-first-demo.spec.md) — narrow first demo with commands
8. [`contradictions.md`](./contradictions.md) — named contradictions; do not silently resolve

Read component specs (other lanes) as relevant to the surface being implemented.

### Step 2 — Validate Environment

Before writing any integration code, confirm all required services are reachable:

```bash
# Confirm mcp-pde is available
npx -y @jgwill/mcp-pde --version

# Confirm coaia-pde CLI is available
npx -y coaia-pde --version

# Confirm coaia-visualizer is available
npx -y @jgwill/coaia-visualizer --version

# Confirm Hermes is installed
hermes --version   # or: python -m hermes_cli.main --version
```

If any of these fail, resolve the dependency before proceeding. The first demo requires
all four.

### Step 3 — Run the First Demo

Follow the full command sequence in [`install-and-first-demo.spec.md`](./install-and-first-demo.spec.md).
The demo does not require any source code changes to `coaia-agent`. It uses profile
isolation + MCP config + skills only.

Expected artifacts on success:
- `.pde/<timestamp>--<uuid>/pde-<uuid>.md`
- `.coaia/pde/<uuid>.jsonl`
- Visualizer loads the JSONL and displays at least one `structural_tension_chart` entity
- `session-summary.md` written to the PDE folder

### Step 4 — Implement Lifecycle Plugin (Phase 1)

After demo success, implement the `coaia-lifecycle` plugin per
[`skill-and-plugin-authoring.spec.md`](./skill-and-plugin-authoring.spec.md).

Install location: `~/.coaia-agent/plugins/coaia-lifecycle/`

Validate by confirming that `on_session_start` creates the `.pde/` folder automatically
and `on_session_end` writes the JSONL without a manual `/stc` invocation.

### Step 5 — Implement Memory Provider (Phase 2)

Implement `CoaiaNarrativeMemoryProvider` per
[`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md).

Validate by confirming that `prefetch()` returns relevant STC context from prior sessions.

### Step 6 — Optional Surfaces (Phase 3+)

Implement governance, Veritas companion, and ACP surfaces in order of priority per
human-authority decisions. Read `contradictions.md` before beginning Phase 3 work.

---

## Install Expectations

### Hermes Installation (coaia-agent profile)

```bash
# Install Hermes with MCP support
pip install "hermes-agent[mcp]"

# Or from the cloned repo
cd /a/src/coaia-agent
pip install -e ".[mcp]"

# Initialise COAIA profile
export HERMES_HOME=~/.coaia-agent
hermes --setup   # interactive setup; creates HERMES_HOME structure
```

### MCP Servers

```bash
# mcp-pde (Node.js, available via npx — no global install required)
# Declared in config.yaml MCP block; Hermes spawns it automatically

# coaia-narrative (Node.js)
# Same pattern — declared in config.yaml, auto-spawned

# coaia-visualizer (Node.js, run separately for demo)
npx @jgwill/coaia-visualizer --memory-path .coaia/pde/<uuid>.jsonl
```

### COAIA Profile Structure

```
~/.coaia-agent/
├── config.yaml              ← Primary config (see below)
├── .env                     ← Secrets (never committed)
├── skins/
│   └── coaia.yaml           ← COAIA brand skin
├── skills/
│   └── coaia/
│       ├── rise-pde-session.md
│       ├── pde-decompose.md
│       ├── stc-create.md
│       └── session-summary.md
└── plugins/
    └── coaia-lifecycle/
        └── __init__.py      ← Phase 1 and later
```

### Minimal `config.yaml`

```yaml
display:
  skin: coaia

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

toolsets:
  - core
  - coaia   # activates COAIA-specific tools when coaia tool files are present
```

---

## Run Expectations

### Starting the Agent

```bash
export HERMES_HOME=~/.coaia-agent
hermes
```

The agent opens with the COAIA skin (if configured), loads MCP servers from config,
and makes `/pde`, `/stc`, `/rise`, and `/summary` slash commands available.

### Session Lifecycle (Phase 0 — manual)

```
User: "Decompose this prompt into a RISE session"
Agent: [calls mcp-pde.pde_decompose] → .pde/<timestamp>--<uuid>/pde-<uuid>.md
User: /stc
Agent: [calls coaia-pde import or coaia-narrative.create_stc] → .coaia/pde/<uuid>.jsonl
User: /summary
Agent: [writes session-summary.md to PDE folder]
```

### Session Lifecycle (Phase 1 — automatic via plugin)

```
Session start:  plugin creates .pde/<timestamp>--<session_id>/meta.json
  During session: /pde invocations accumulate in .pde/ folder
  post_tool_call: context captured for current_reality accumulation
Session end:   plugin invokes coaia-pde mapper; writes .coaia/pde/<session_id>.jsonl
```

### Visualizer Load

```bash
npx @jgwill/coaia-visualizer --memory-path .coaia/pde/<uuid>.jsonl
```

Open `http://localhost:3000` (or the reported port). The STC chart should appear.

---

## Export Conventions

### PDE Folder Artifact

Follows the miaco `meta.json` v2 contract. Required fields for coaia-agent sessions:

```json
{
  "schema_version": 2,
  "root_pde_id": "<uuid>",
  "parent_pde_id": null,
  "child_kind": "milestone",
  "children": [],
  "provenance": {
    "repository": "jgwill/coaia-agent",
    "session_id": "<hermes-session-id>"
  },
  "engine": "coaia-agent",
  "model": "<model-used>",
  "session_id": "<hermes-session-id>",
  "session_id_source": "engine"
}
```

The `session_id` field is the join key to `SessionDB` and to the `.coaia/pde/` JSONL filename.

### STC JSONL Export

Produced by `coaia-pde import <pde-id>`. The JSONL file:
- **Line 1**: `pde_session` type with `pdeDecompositionId`, `masterChartId`, `status`
- **Lines 2–N**: `entity` and `relation` lines conforming to `coaia-narrative/src/types.ts`

On export to a different environment, transfer the entire `.pde/<uuid>/` folder and
the corresponding `.coaia/pde/<uuid>.jsonl` together. The `pdeDecompositionId` field
maintains provenance across environments.

### Session Summary Export

`session-summary.md` written to `.pde/<timestamp>--<uuid>/session-summary.md`.
Format: free-form markdown with section headers for Desired Outcome, Actions Taken,
Open Questions, and Next Session Inputs.

---

## Validation and Handoff Notes

### Validation Checkpoints

| Checkpoint | Pass condition |
|-----------|----------------|
| mcp-pde reachable | `pde_decompose` tool visible in `hermes` tool list |
| PDE artifact created | `.pde/<timestamp>--<uuid>/pde-<uuid>.md` exists after `/pde` invocation |
| JSONL produced | `.coaia/pde/<uuid>.jsonl` exists; first line is `{"type":"pde_session",...}` |
| Visualizer loads | JSONL renders at least one `structural_tension_chart` entity in the UI |
| Session summary written | `.pde/<uuid>/session-summary.md` exists after `/summary` |

### Handoff Notes for Implementation Team

1. **Start narrow**: Run the first demo per `install-and-first-demo.spec.md` before
   any plugin or memory provider work. The demo path is the validation baseline.

2. **Do not resolve contradictions silently**: Read `contradictions.md` before any
   implementation decision touching Direction casing, `fourDirections` key names,
   binary naming, or Veritas activation defaults. Surface the contradiction to the
   human steward and await direction.

3. **Plugin code goes in `HERMES_HOME`**: Do not modify Hermes core files. If a needed
   extension point does not exist in the plugin system, open an issue against coaia-agent
   and implement via the nearest available hook.

4. **Schema authority is coaia-narrative**: Do not invent a parallel JSONL schema.
   Extend `coaia-narrative/src/types.ts` via the `schema-evolution-and-ecosystem-metadata.spec.md`
   proposed path.

5. **Veritas is opt-in**: The default config disables all Veritas hooks. Any session
   that uses Veritas must have `veritas.enabled: true` explicitly set. Do not change
   this default without human authority.

6. **Medicine Wheel governance is advisory**: Do not translate `formatGovernanceWarning()`
   warnings into behavioral blocks. Surface them; await human direction.

7. **OCAP is a real soft gate**: Data with `withdrawn` or `expired` consent must not be
   forwarded to external evaluation engines. This is the one governance-adjacent boundary
   that can be automated as a halt-and-escalate pattern. See
   [`medicine-wheel-governance.spec.md`](./medicine-wheel-governance.spec.md).

8. **Document human-gated decisions as they are resolved**: When a human steward makes a
   decision on any item in `02-intent.md`'s human-gated table, record the decision in
   `contradictions.md` alongside the now-resolved contradiction. Do not silently incorporate
   the decision into code without an audit trail.

---

## Next-Session Inputs

The following items are the recommended starting inputs for the implementation session
that follows this spec-authoring session:

1. This full rispecs pack (read in README order)
2. The orchestration kit session pack at
   `/workspace/repos/jgwill/miadi-orchestration-kit/rispecs/coaia-agent-orchestration-session/`
   (to be authored separately)
3. The SOUTH findings at `/a/src/.pde/2604291305-coaia-agent-rispecs/deep-search/`
4. Live STC session at `/a/src/.coaia/pde/48b47ec4-6244-46ae-955b-3724a1b4e071.jsonl`
5. The active PDE decomposition at
   `/a/src/.pde/2604291317--4da3f9f5-4fe4-4b92-9e9f-f4fead872780/pde-4da3f9f5-4fe4-4b92-9e9f-f4fead872780.md`
