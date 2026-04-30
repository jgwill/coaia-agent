# KINSHIP — coaia-agent

**Lane**: NORTH N3 | **Session UUID**: 2604291305-coaia-agent-rispecs | **PDE UUID**: 4da3f9f5-4fe4-4b92-9e9f-f4fead872780
**Model**: claude-sonnet-4.6 (approved fallback — claude-opus-4.6 not available in environment)
**Authored**: 2026-04-29

---

## 1. Identity and Purpose

- **Name**: coaia-agent (`/a/src/coaia-agent/`)
- **Repository**: fork of `NousResearch/hermes-agent` (Hermes Agent v0.11.0)
- **Local role in this system**: Terminal integration gateway — brings the COAIA ceremony/STC ecosystem into the conversation-loop agent context. It is the surface where a human operator or Miadi orchestrator invokes PDE decomposition, STC creation, MMOT evaluation, and governance annotation through a single agent interface.
- **What this place tends / protects**: The relational boundary between raw agentic execution and the ceremony-aware COAIA methodology. It ensures that structural tension — Desired Outcome ↔ Current Reality — is present in agent sessions, not just task lists.
- **What this place offers (its gifts)**: Hermes conversation-loop runtime (90-iteration, interrupt-capable), ACP adapter for VS Code/Zed/JetBrains, batch runner, tool registry, skill system, and the hook points (`tools/`, `toolsets.py`) where COAIA tool families can register without touching core runtime.

---

## 2. Lineage and Relations

### Ancestor / Lineage

**Hermes Agent (NousResearch)** is the direct ancestor — a production-grade terminal agent providing the runtime substrate: conversation loop, tool registry, profile/home system, config loaders, ACP protocol server. This lineage is honored as the engineering foundation that makes COAIA-agent possible without building a runtime from scratch.

**Hermes** (the messenger god, etymological ancestor) names a principle this fork must maintain: Hermes carries messages between worlds without becoming a world unto itself. coaia-agent carries COAIA semantics into agent sessions; it is not the ceremony itself.

Within the COAIA ecosystem, the lineage chain is:

```
mcp-pde (PDE engine)
  ↓
coaia-pde (PDE → STC bridge)
  ↓
coaia-narrative (STC schema authority)
  ↓
coaia-agent (agent session gateway — THIS PLACE)
```

coaia-agent is a **downstream consumer** of the full COAIA chain. It does not own any schema, does not store canonical JSONL (that is coaia-narrative's role), and does not decompose prompts (that is mcp-pde's role).

### Descendants

None at the time of authoring. If the ACP adapter (hermes-acp) is extended with a COAIA-native protocol surface, that may become a descendant project.

### Siblings (peers in the COAIA ecosystem)

| Sibling | Role relative to coaia-agent |
|---|---|
| `/a/src/coaia-pde/` | Produces STC JSONL via PDE → STC bridge; coaia-agent calls its MCP tools |
| `/a/src/coaia-narrative/` | Schema authority and JSONL storage; coaia-agent reads and writes through its MCP server |
| `/a/src/coaia-planning/` | Plan → STC path; coaia-agent may call `plan_to_stc` for markdown-based sessions |
| `/a/src/coaia-visualizer/` | Web UI for STC state; coaia-agent surfaces chart IDs for human inspection |
| `/a/src/mcp-pde/` | Upstream PDE engine; coaia-agent calls `pde_decompose` via MCP or env-gated tool |
| `/workspace/repos/jgwill/veritas/` | Optional companion evaluator; coaia-agent calls Veritas tools only when `veritas.enabled: true` in config |
| `/workspace/repos/jgwill/medicine-wheel/` | Governance and ceremony ontology; coaia-agent consumes governance functions as annotation surface — it does not hold authority |

### Related Hubs

- **Miadi** (`/a/src/Miadi/`) — webhook-driven orchestration that can invoke coaia-agent sessions via `hermes-acp`
- **miadi-orchestration-kit** — session-pack and plugin container for orchestrating coaia-agent implementation waves
- **IAIP** (`/a/src/IAIP/`) — canonical PDE types at `lib/pde/types.ts`; coaia-agent should use these via mcp-pde, not fork them

---

## 3. Responsibilities and Boundaries

### Responsibilities

1. Integrate COAIA toolsets (coaia-pde, coaia-narrative MCP, mcp-pde) into the Hermes tool registry as opt-in toolset families
2. Surface STC creation, MMOT evaluation, PDE decomposition, and governance annotation as callable tools within agent sessions
3. Respect the `HERMES_HOME` / `COAIA_HOME` profile boundary — config and secrets must not bleed between profiles
4. Pass OCAP flags through all data operations without modification; surface consent-state warnings; halt and await human direction when `withdrawn` or `expired` consent is encountered
5. Surface Medicine Wheel governance warnings (`formatGovernanceWarning`) when operating on ceremony-annotated paths; do not self-authorize writes to `ceremony_required`, `restricted`, or `sacred` paths

### Boundaries and NOs

- Does **NOT** define STC schema — that is coaia-narrative's responsibility
- Does **NOT** decompose prompts autonomously — decomposition belongs to mcp-pde; coaia-agent calls the tool
- Does **NOT** store canonical JSONL — it invokes storage through coaia-narrative MCP or coaia-pde session manager
- Does **NOT** hold ceremony authority — it is an **unentitled actor** in Medicine Wheel governance; it surfaces, awaits, does not authorize
- Does **NOT** initiate Veritas evaluation without explicit `veritas.enabled: true` in config and human-authorized model creation
- Does **NOT** rebrand itself away from `hermes-agent` identity in this spec-authoring session; identity normalization is a future decision gated by `contradictions.md` resolution

### Special Protocols

- `HERMES_HOME` override to `~/.coaia-agent` creates COAIA-isolated profile without modifying source
- COAIA tools register as a distinct `"coaia"` toolset; enabling is opt-in via config `toolsets.coaia: true`
- Bootstrap paradox rule applies: the first Veritas MMOT evaluation of any new companion model is demonstration-only; it must not seed the next PDE cycle until at least two complete evaluation cycles have run

---

## 4. Gifts This Place Offers

- **To mcp-pde**: A conversational, interactive session surface where PDE results can be inspected, refined, and acted upon mid-loop
- **To coaia-pde**: An agent loop that can call `import <pde-id>` and advance STC state in the same session that created the decomposition
- **To coaia-narrative**: A runtime that can invoke MMOT evaluation and emit narrative beats as part of a structured agent conversation
- **To Miadi**: An ACP-compatible agent that Miadi can orchestrate without requiring a custom runtime
- **To Medicine Wheel**: A surface that annotates sessions with directional ceremony phase metadata, making agent work traceable to ceremonial context

---

## 5. Reciprocity Expectations

- coaia-agent **receives** the runtime substrate from Hermes/NousResearch; it reciprocates by preserving upstream compatibility and not forking incompatible tool registry or config structures
- coaia-agent **receives** governance and ceremony protocol from medicine-wheel; it reciprocates by surfacing warnings accurately, halting at unentitled-actor boundaries, and producing session JSONL that medicine-wheel session-reader can parse
- coaia-agent **receives** STC schema from coaia-narrative; it reciprocates by never writing JSONL that breaks coaia-narrative schema expectations
- coaia-agent **receives** Veritas evaluation from veritas; it reciprocates by enforcing the element-origin invariant (only STC action steps become Veritas elements) and the bootstrap paradox rule

---

## 6. Review Expectations

This KINSHIP.md should be reviewed:
- When the `hermes-agent` upstream releases a new major version (identity / protocol changes)
- When any sibling repo changes its MCP tool surface (tool schema diffs may require toolset registration updates)
- When the Medicine Wheel governance tier structure changes (unentitled-actor status may need re-evaluation)
- When the Veritas companion spec transitions from Draft to Implemented status
- After the coaia-agent implementation session completes its first wave, to verify stated responsibilities match actual integration

**Relational change log**:

| Date | Author | Change |
|---|---|---|
| 2026-04-29 | copilot/N3 | Initial KINSHIP.md authored as part of RISE PDE session 2604291305-coaia-agent-rispecs |
