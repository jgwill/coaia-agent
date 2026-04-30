# 00 — Source Survey: coaia-agent RISE Integration

**Version**: 0.1.0  
**Status**: Draft  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Lane**: NORTH N1  
**Date**: 2026-04-29  
**Cross-references**: [`01-reverse-engineer.md`](./01-reverse-engineer.md), [`03-specify.md`](./03-specify.md)

---

## Purpose

This document summarizes every repository surveyed to produce the coaia-agent RISE spec
pack, what each contributes to the integration design, and whether that contribution is
**required** (the first useful demo does not function without it) or **optional** (adds
value but can be deferred).

SOUTH lane findings that ground this survey:
- [`findings-runtime-archaeology.md`](../../.pde/2604291305-coaia-agent-rispecs/deep-search/findings-runtime-archaeology.md)
- [`findings-data-provenance-chain.md`](../../.pde/2604291305-coaia-agent-rispecs/deep-search/findings-data-provenance-chain.md)
- [`findings-miaco-precedent.md`](../../.pde/2604291305-coaia-agent-rispecs/deep-search/findings-miaco-precedent.md)
- [`findings-governance-and-evaluation.md`](../../.pde/2604291305-coaia-agent-rispecs/deep-search/findings-governance-and-evaluation.md)
- [`findings-orchestration-next-session.md`](../../.pde/2604291305-coaia-agent-rispecs/deep-search/findings-orchestration-next-session.md)

---

## Repositories Surveyed

### 1. `coaia-agent` (Hermes 0.11.0)

**Path**: `/a/src/coaia-agent/`  
**Origin**: Fork of `NousResearch/Hermes-Agent` at 0.11.0  
**Status in integration**: Integration host — all COAIA additions land here or in `HERMES_HOME`

**Contributes**:
- `run_agent.py` — `AIAgent` conversation loop; the primary extension surface
- `tools/registry.py` — auto-discovery tool registration (`registry.register()`)
- `hermes_constants.py:get_hermes_home()` — profile isolation via `HERMES_HOME` env var
- `hermes_cli/plugins.py` — lifecycle hooks: `on_session_start`, `on_session_end`, `post_tool_call`
- `agent/memory_provider.py` — `MemoryProvider` ABC for pluggable memory backends
- `hermes_cli/skin_engine.py` — skin YAML for brand identity without source edits
- `agent/skill_commands.py` — slash-command skill loading from `HERMES_HOME/skills/`
- `cron/`, `gateway/run.py` — scheduled and webhook-triggered agent runs

**Required for demo**: Yes — it is the runtime  
**Identity tension**: Currently branded `hermes-agent` throughout. No rebrand decision has been made. See `contradictions.md`.

---

### 2. `mcp-pde`

**Path**: `/a/src/mcp-pde/`  
**Rispecs**: `/a/src/mcp-pde/rispecs/` (7 specs surveyed)  
**Status in integration**: Required (first leg of the demo flow)

**Contributes**:
- `pde_decompose` MCP tool — prompt → `DecompositionResult` → `.pde/<timestamp>--<uuid>/pde-<uuid>.md`
- Canonical `DecompositionResult` TypeScript types (authoritative; all downstream packages copy from here)
- `DIRECTION_META` with Four Directions theme descriptions (lowercase `Direction` type)
- `.pde/` folder layout — the persistent artifact root for every decomposition
- `pde-parent-child-schema.rispec.md` — folder-backed PDE tree (miaco-convergent)

**Required for demo**: Yes — without mcp-pde, no PDE folder artifact is created  
**MCP connection**: Declare server in `HERMES_HOME/config.yaml` MCP block; no adapter code needed  
**Note**: Type schema (`DecompositionResult`, `Direction`) is copied — not imported — by coaia-pde. Schema drift is a live risk documented in `contradictions.md`.

---

### 3. `coaia-pde`

**Path**: `/a/src/coaia-pde/`  
**Rispecs**: `/a/src/coaia-pde/rispecs/` (4 specs surveyed)  
**Status in integration**: Required (PDE → STC JSONL transform)

**Contributes**:
- `stc-mapper.ts:mapDecompositionToChart()` — transforms `DecompositionResult` into `Entity[]` + `Relation[]`
- `session-manager.ts` — writes `.coaia/pde/<uuid>.jsonl` with `pde_session` header
- `import <pde-id>` CLI command — reads a `.pde/` StoredDecomposition and writes the JSONL
- Local copy of `Entity`/`Relation` schema (copied from `coaia-narrative/src/types.ts`)

**Required for demo**: Yes — it produces the JSONL that coaia-visualizer reads  
**Known limitation**: `fourDirections` key suffixes (`south_emotion`, `west_introspection`) are semantically misaligned with Medicine Wheel role language. Named in `contradictions.md`, deferred to human cultural authority.

---

### 4. `coaia-narrative`

**Path**: `/a/src/coaia-narrative/`  
**Rispecs**: `/a/src/coaia-narrative/rispecs/` (17 specs surveyed)  
**Status in integration**: Required (canonical schema authority)

**Contributes**:
- `src/types.ts` — **authoritative** `Entity`, `Relation`, `Observation` JSONL schema
- MCP server with `create_stc`, `perform_mmot_evaluation`, `add_action_step`, and narrative beat tools
- Three creative pillars: Creative Orientation, Structural Tension, Advancing Patterns
- `schema-evolution-and-ecosystem-metadata.spec.md` — proposed UPPERCASE Direction canonical and typed `metadata.source` sub-objects

**Required for demo**: Schema authority is required; the MCP server itself is optional for the narrow demo  
**Note**: Do not invent a new JSONL format. The coaia-narrative Entity/Relation schema is the correct evolution path.

---

### 5. `coaia-visualizer`

**Path**: `/a/src/coaia-visualizer/`  
**Rispecs**: `/a/src/coaia-visualizer/rispecs/` (13 specs surveyed)  
**Status in integration**: Required for demo (visualizer load is the demo's fourth step)

**Contributes**:
- `--memory-path` flag — reads any `.coaia/pde/*.jsonl` file; renders STC chart hierarchy
- 4-pass JSONL parse: entity/relation separation → chart assembly → child population → hierarchy
- `pde-integration.spec.md` — aspirational Four Directions quadrant view and PDE source badge (not yet implemented; referenced for future metadata compatibility)
- `chart-editing-workflow.spec.md` — MCP-backed editing surface for chart entities

**Required for demo**: Yes — the visualizer load step is part of the first useful demo  
**Gap**: visualizer currently renders PDE-sourced JSONL identically to hand-authored JSONL; PDE-specific metadata display is a future spec.

---

### 6. `coaia-planning`

**Path**: `/a/src/coaia-planning/`  
**Rispecs**: `/a/src/coaia-planning/rispecs/` (6 specs surveyed)  
**Status in integration**: Optional (parallel input path, not required for first demo)

**Contributes**:
- `plan_to_stc`, `sync_plan_to_chart`, `sync_chart_to_plan` bidirectional sync tools
- `pde-bridge.spec.md` — PDE → Plan → STC alternative input path
- `decompositionResultToPlan()` bridge function
- Layout C JSONL output (`COAIA_OUTPUT_DIR/<plan-name>.jsonl`) without `pde_session` header

**Required for demo**: No — PDE → STC direct path is sufficient  
**Note**: Layout C JSONL lacks the `pde_session` header and `pdeDecompositionId` link; provenance tracing across planning integration requires a source discriminator (not yet implemented).

---

### 7. `mia-code` / miaco

**Path**: `/a/src/mia-code/miaco/`  
**Rispecs**: `/a/src/mia-code/rispecs/` (101 files surveyed)  
**Status in integration**: Optional (precedent reference, not a runtime dependency)

**Contributes**:
- Folder-backed PDE tree precedent: `.pde/<timestamp>--<uuid>/` with `meta.json` v2 contract
- `child-kind` taxonomy (`milestone`, `issue`, `sub-task`, `follow-up`, `refinement`, `sibling`)
- Inquiry enrichment chain: PDE → clarifications → QMD queries → four-questions → STC JSONL (all in PDE folder)
- `pde-to-st` four-stage structural thinking pipeline
- `--format json` scrape contract for downstream consumers
- Engine adapter pattern (artifact contract stable regardless of engine)

**Required for demo**: No — miaco's PDE folder convention is a precedent, not a dependency  
**Influence on spec**: The folder-backed PDE layout and `meta.json` parent/child linkage are the preferred artifact root for coaia-agent; coaia-agent should **not** create flat `.pde/*.json` files.

---

### 8. `veritas`

**Path**: `/workspace/repos/jgwill/veritas/`  
**Rispecs**: 11 + 3 proposal specs surveyed  
**Status in integration**: Optional (requires explicit config opt-in)

**Contributes**:
- Type 2 Performance Review model: State × Trend → Priority matrix (deterministic)
- `veritas_mmot_evaluate` LOCAL_TOOLS mode (no API key required for evaluation)
- STC–Veritas companion bond: action steps → Veritas elements → MMOT cycle
- Seed loop: Veritas Critical/Warning → next PDE cycle input

**Required for demo**: No — all Veritas hooks are behind `veritas.enabled: false` default  
**Critical constraint**: First MMOT evaluation is demonstration, not trusted verdict (bootstrap paradox). See `contradictions.md`.

---

### 9. `medicine-wheel`

**Path**: `/workspace/repos/jgwill/medicine-wheel/`  
**Rispecs**: 22 specs surveyed  
**Status in integration**: Optional (governance annotation layer, not behavioral gate)

**Contributes**:
- Ceremony phase annotation mapping: session lifecycle → East/South/West/North phases
- Protected path governance: `formatGovernanceWarning()` — advisory, non-blocking
- Consent lifecycle state machine: `pending → granted → active → expired/withdrawn`
- OCAP flags (Ownership, Control, Access, Possession) on JSONL data
- Canonical Direction type: lowercase `'east' | 'south' | 'west' | 'north'` (ontology-core)

**Required for demo**: No  
**Authority boundary**: coaia-agent is an **unentitled actor** in ceremony-protocol governance — it surfaces warnings and awaits human direction; it does not self-authorize writes to protected paths.

---

### 10. `miadi-orchestration-kit`

**Path**: `/workspace/repos/jgwill/miadi-orchestration-kit/`  
**Rispecs**: Kit present; no `.spec.md`/`.rispec.md` files at root level  
**Status in integration**: Optional (session pack for implementation ceremony)

**Contributes**:
- Rispec folder shape precedent (`security-remediation-orchestration/`)
- Conductor skill pattern (issue-aware, reading-order, path ledger)
- Session charter template for replayable implementation sessions
- `--add-dir` vs `--plugin-dir` contract
- Artefact folder naming convention

**Required for demo**: No — kit usage is for the implementation session ceremony, not the first demo

---

## Required vs Optional Summary

| Repo | Required for first demo | Required for production |
|------|------------------------|------------------------|
| `coaia-agent` (Hermes) | ✅ Runtime host | ✅ |
| `mcp-pde` | ✅ PDE decomposition | ✅ |
| `coaia-pde` | ✅ STC JSONL production | ✅ |
| `coaia-narrative` | ✅ Schema authority | ✅ |
| `coaia-visualizer` | ✅ Demo visualization step | ✅ (or equivalent consumer) |
| `coaia-planning` | ❌ Optional input path | Optional |
| `mia-code/miaco` | ❌ Precedent only | Optional |
| `veritas` | ❌ Config opt-in | Optional |
| `medicine-wheel` | ❌ Annotation layer | Optional |
| `miadi-orchestration-kit` | ❌ Session ceremony | Optional |
