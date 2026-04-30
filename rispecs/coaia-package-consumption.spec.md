# COAIA Package Consumption — RISE Specification

> How coaia-agent declares, consumes, and adapts the COAIA package ecosystem: required vs. optional packages, storage root ownership, adapter responsibilities, direction normalization, and fallback behavior.

**Version**: 1.0.0  
**Document ID**: coaia-package-consumption-v1  
**Last Updated**: 2026-04-29  
**Status**: Draft (spec-only)  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Cross-references**:
- [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md) — lifecycle stages that activate each package
- [`prompt-skill-runtime.spec.md`](./prompt-skill-runtime.spec.md) — runtime invocation and plugin hooks
- [`visualizer-planning-narrative-flow.spec.md`](./visualizer-planning-narrative-flow.spec.md) — downstream artifact consumption
- `coaia-narrative/rispecs/schema-evolution-and-ecosystem-metadata.spec.md` — proposed typed sub-objects

---

## Desired Outcome

coaia-agent's implementation team can determine, from this document alone, which packages must be installed, which are optional enhancements, who owns each storage root, what adapters coaia-agent must supply, and what fallback behavior is required when an optional package is absent.

---

## Structural Tension

**Current Reality**  
No document defines the coaia-agent package boundary. Existing packages (`mcp-pde`, `coaia-pde`, `coaia-narrative`, `coaia-visualizer`, `coaia-planning`) each have their own type definitions, storage conventions, and direction casing — with no runtime enforcing compatibility. Direction normalization is inconsistent across three casings. Schema drift is managed by convention. Source provenance has no standard discriminator.

**Desired Outcome**  
coaia-agent declares an explicit package contract: required dependencies with minimum surface, optional integrations with activation checks and fallback, and a direction normalization adapter that operates at the coaia-agent boundary — normalizing on write so downstream packages receive consistent UPPERCASE direction strings.

---

## 1. Package Registry

### 1.1 Required Packages

These packages must be available for coaia-agent to function. Their absence is a startup error.

| Package | Role | Minimum Surface Used |
|---------|------|---------------------|
| **`mcp-pde`** | Canonical prompt decomposition source | `pde_decompose`, `pde_get`, `pde_parse_response`, `pde_export_markdown`, `.pde/` storage |
| **`coaia-pde`** | PDE → STC mapper; `.coaia/pde/` writer | `StcMapper.mapDecompositionToChart()`, `SessionManager.initSession()`, `appendEntity()`, `appendRelation()` |
| **`coaia-narrative`** | Authoritative JSONL entity/relation schema | `Entity`, `Relation`, `EntityMetadata` types; MCP tools for append/read |

Rationale: Without `mcp-pde`, there is no decomposition. Without `coaia-pde`, there is no STC output. Without `coaia-narrative`, there is no authoritative schema to conform to.

### 1.2 Optional Packages

These packages enhance coaia-agent but must not be required for core function. Their absence must be handled by explicit fallback (see §4).

| Package | Role | Activation Condition | Fallback if Absent |
|---------|------|---------------------|-------------------|
| **`coaia-visualizer`** | STC inspection and editing UI | `COAIA_VISUALIZER_URL` env set, or MCP server reachable | Log path to JSONL; advise manual inspection |
| **`coaia-planning`** | Plan ↔ STC bidirectional sync | `COAIA_PLANNING_ENABLED=true` or `pde_to_plan` tool available | Skip plan sync; complete with PDE→STC path only |
| **`veritas`** | Type 2 MMOT performance review | `VERITAS_ENABLED=true` or Veritas MCP server reachable | Skip review; mark session as self-assessed |
| **`medicine-wheel`** | Ceremony, consent lifecycle, governance | `MEDICINE_WHEEL_ENABLED=true` | Session proceeds without ceremony framing; governance annotations skipped |
| **`miaco`** (mia-code) | PDE tree lifecycle precedent; inquiry enrichment | Runtime-only reference — no code import | Not needed; miaco is a conceptual transfer, not a runtime dependency |

### 1.3 Miaco Precedent Note

miaco (`/a/src/mia-code/miaco/`) is **not a runtime dependency**. It is a conceptual precedent for:
- Folder-backed PDE tree layout (`.pde/<ts>--<uuid>/` with `meta.json`)
- Deterministic fallback when LLM conversion fails
- `stc convert` CLI pattern (PDE → JSONL without a live LLM)
- Parent-aware child decomposition (`--parent <uuid>`)

coaia-agent borrows these patterns. No code import from `mia-code` is required or expected.

---

## 2. Storage Root Ownership

### 2.1 Storage Roots Table

| Root | Owned by | What it Holds | Link Mechanism |
|------|----------|---------------|----------------|
| `.pde/` | **mcp-pde** | `StoredDecomposition` JSON + markdown exports (folder-backed Layout A) | `StoredDecomposition.id` (UUID) |
| `.coaia/pde/` | **coaia-pde** | STC JSONL sessions (`PdeSession` + Entity + Relation lines) | `pde_session.pdeDecompositionId` → `.pde/` |
| `.coaia/` (general) | **coaia-narrative** | All JSONL memory files; narrative beats; MMOT evaluations | Chart entity `name` fields |
| `PLANS_DIR` (default `~/.claude/plans/`) | **coaia-planning** | Source plan markdown files | `metadata.plan.planId` (file path) |
| `COAIA_OUTPUT_DIR` (default `coaia-planning/output/`) | **coaia-planning** | Plan-derived STC JSONL (no `pde_session` header) | `metadata.source.system = 'coaia-planning'` |
| `.pde/<ts>--<uuid>/session-summary.md` | **coaia-agent** | Session close artifact | Co-located with `StoredDecomposition` folder |

### 2.2 Cross-Root Links

The only enforced link between storage roots is the `pdeDecompositionId` field on the `pde_session` header line. There is **no filesystem symlink or index** between roots. coaia-agent is responsible for maintaining this field when it writes a JSONL session.

```
.pde/<ts>--<pde-uuid>/pde-<pde-uuid>.json
                            ↑
                  pde_session.pdeDecompositionId
                            ↓
.coaia/pde/<session-uuid>.jsonl  (Line 1: pde_session header)
```

The reverse link (from `mcp-pde` back to a session) does not exist in the current implementation. coaia-agent may add `sessionUuids[]` to `StoredDecomposition` if needed for multi-session support.

### 2.3 Writing Rules

- coaia-agent **must not write** into `.pde/` directly — all writes go through `mcp-pde` MCP tools.
- coaia-agent **must not write** into `.coaia/` directly — all writes go through `coaia-pde` or `coaia-narrative` MCP tools.
- coaia-agent **may write** session summary artifacts under `.pde/<ts>--<uuid>/session-summary.md` using direct file I/O, since mcp-pde does not provide a summary artifact tool.

---

## 3. Adapter Responsibilities

### 3.1 Direction Normalization Adapter (Cross-Cutting)

Direction casing is the most pervasive cross-cutting concern in the COAIA ecosystem. Three casings co-exist and are incompatible:

| Casing | Source | Example |
|--------|--------|---------|
| **lowercase** | `mcp-pde/src/types.ts` (runtime) | `"east"`, `"south"`, `"west"`, `"north"` |
| **Title-case** | `coaia-narrative/src/types.ts` `mmotEvaluations[].direction` | `"South"`, `"East"` |
| **UPPERCASE** | `schema-evolution-and-ecosystem-metadata.spec.md` (proposed canonical) | `"SOUTH"`, `"EAST"` |

**coaia-agent v1 normalization rule**: Normalize to UPPERCASE on write. Accept any casing on read.

```typescript
// Adapter: normalize Direction to UPPERCASE on write
export type CanonicalDirection = 'EAST' | 'SOUTH' | 'WEST' | 'NORTH';

export function normalizeDirection(raw: string): CanonicalDirection {
  const upper = raw.toUpperCase() as CanonicalDirection;
  if (!['EAST', 'SOUTH', 'WEST', 'NORTH'].includes(upper)) {
    throw new Error(`Unknown direction: ${raw}`);
  }
  return upper;
}

// Read-side: accept any casing, normalize before processing
export function readDirection(raw: string | undefined): CanonicalDirection | undefined {
  if (!raw) return undefined;
  return normalizeDirection(raw);
}
```

This adapter must be applied:
1. When coaia-agent writes `metadata.direction` on `action_step` entities
2. When coaia-agent reads `direction` from a DecompositionResult (lowercase → UPPERCASE before passing to stcMapper)
3. When coaia-agent reads MMOT evaluations from `coaia-narrative` (Title-case → UPPERCASE before internal use)

The adapter does **not** modify existing JSONL files — normalization is on write only.

### 3.2 Source Provenance Adapter

coaia-agent adds `metadata.source` to every entity it produces, enabling downstream consumers to distinguish between production paths:

```typescript
// Per schema-evolution-and-ecosystem-metadata.spec.md §4
interface SourceProvenance {
  system: 'coaia-agent' | 'coaia-pde' | 'coaia-planning' | 'coaia-narrative' | 'mcp-pde' | 'manual';
  version?: string;
  toolName?: string;   // MCP tool that created this entity, if applicable
  sessionId?: string;  // PDE session UUID
  createdAt?: string;  // ISO-8601
}
```

When coaia-agent delegates to `coaia-pde` for entity creation, the resulting entities will carry `source.system = 'coaia-pde'` implicitly. coaia-agent should not override this — it is a faithful record of the producing system.

### 3.3 Schema Version Adapter

coaia-pde's `types.ts` is a **copy** of `mcp-pde/src/types.ts`, not an import. Schema drift is a live risk. coaia-agent must treat `mcp-pde/src/types.ts` as authoritative and validate that coaia-pde's copy matches at runtime startup (or document the drift explicitly in startup logs).

Recommended approach: compare `DecompositionResult` field names between the two files at startup; emit a warning (not an error) if they diverge. Do not fail startup over a structural drift warning.

---

## 4. Normalization Responsibilities by Package

| Concern | Responsible Package | Implementation Status |
|---------|--------------------|-----------------------|
| PDE decomposition (prompt → DecompositionResult) | mcp-pde | Implemented |
| DecompositionResult → Entity/Relation | coaia-pde (stcMapper) | Implemented |
| JSONL schema (Entity, Relation, EntityMetadata types) | coaia-narrative | Implemented |
| Direction normalization (lowercase → UPPERCASE on write) | **coaia-agent adapter** | **Not yet implemented** |
| Source provenance (`metadata.source`) | **coaia-agent adapter** | **Not yet implemented** |
| PDE metadata sub-object (`metadata.pde.*`) | coaia-pde (Phase 2) | Proposed in schema-evolution spec |
| Plan metadata sub-object (`metadata.plan.*`) | coaia-planning (Phase 2) | Proposed in schema-evolution spec |
| `fourDirections` key suffix alignment | Human cultural authority | Not automatable |
| Visualizer PDE rendering | coaia-visualizer (future) | Aspirational spec only |

---

## 5. Direction Normalization as Boundary Enforcement

Direction normalization is not a documentation decision — it is an **implementation boundary decision**. The schema-evolution spec proposes UPPERCASE as canonical. coaia-agent adopts this and enforces it at the output boundary:

```
mcp-pde produces:     direction: "east"  (lowercase)
                              │
                    coaia-agent adapter
                              │ normalizeDirection("east") → "EAST"
                              ↓
coaia-pde writes:     metadata.direction: "EAST"  (UPPERCASE)
                              │
coaia-narrative reads: direction: "EAST"
coaia-visualizer reads: metadata.direction: "EAST"
```

The adapter sits between the mcp-pde output (lowercase) and the coaia-pde input. It is a one-line transformation that must not be skipped.

The `mmotEvaluations[].direction` field in `coaia-narrative/src/types.ts` currently uses Title-case (`'South' | 'East' | 'West' | 'North'`). coaia-agent normalizes these to UPPERCASE when reading MMOT evaluations for internal use. When writing new MMOT evaluations, coaia-agent writes UPPERCASE. This is an in-flight migration — existing JSONL with Title-case values remain valid and must not be rejected.

---

## 6. Fallback Behavior Contracts

### 6.1 coaia-visualizer absent

```
IF COAIA_VISUALIZER_URL is not set AND visualizer MCP not reachable:
  THEN log: "coaia-visualizer not available. STC JSONL written to: .coaia/pde/<uuid>.jsonl"
       log: "Inspect manually or start coaia-visualizer with: coaia-visualizer --memory-path <path>"
  SKIP all visualizer MCP calls
  CONTINUE with narrative and planning if available
```

### 6.2 coaia-planning absent

```
IF COAIA_PLANNING_ENABLED != 'true' AND pde_to_plan tool not reachable:
  THEN log: "coaia-planning not available. Skipping Plan↔STC sync."
  SKIP plan bridge, bidirectional sync
  CONTINUE with PDE→STC path only
  NOTE in session-summary.md: "Planning sync not activated"
```

### 6.3 mcp-pde unavailable (unrecoverable)

```
IF mcp-pde MCP server not reachable:
  THEN emit: ERROR "mcp-pde is required. Ensure mcp-pde MCP server is running."
  HALT session initialization
  (No fallback — coaia-agent cannot decompose without mcp-pde)
```

### 6.4 coaia-pde unavailable (unrecoverable)

```
IF coaia-pde 'import' command not available:
  THEN emit: ERROR "coaia-pde is required for STC creation."
  HALT after decomposition; do not produce partial JSONL
```

### 6.5 Schema drift detected at startup

```
IF coaia-pde/src/types.ts DecompositionResult fields diverge from mcp-pde/src/types.ts:
  THEN emit: WARN "Schema drift detected between mcp-pde and coaia-pde types. Fields: <list>"
  CONTINUE (not a blocking error in v1)
  RECORD drift warning in session-summary.md
```

---

## 7. Package Interface Surface

### 7.1 mcp-pde MCP Tools Used

| Tool | Purpose | Input | Output |
|------|---------|-------|--------|
| `pde_decompose` | Decompose a prompt | `{ prompt, workdir?, parent_pde_id? }` | `StoredDecomposition` |
| `pde_get` | Load a stored decomposition | `{ id, workdir? }` | `StoredDecomposition \| null` |
| `pde_export_markdown` | Export markdown artifact | `{ id, workdir? }` | Markdown string |
| `pde_list` | List recent decompositions | `{ workdir?, limit? }` | `StoredDecomposition[]` |

### 7.2 coaia-pde CLI/API Used

| Operation | Purpose | Input | Output |
|-----------|---------|-------|--------|
| `import <pde-id>` | Trigger PDE→STC; write JSONL | PDE UUID, workdir | `PdeSession` |
| `StcMapper.mapDecompositionToChart()` | Transform DecompositionResult | `DecompositionResult`, prompt, `{ pdeId? }` | `{ entities, relations, chartId }` |
| `SessionManager.initSession()` | Write `pde_session` header line | `originalPrompt, masterChartId, pdeDecompositionId` | `PdeSession` |
| `SessionManager.appendEntity()` | Append entity line to JSONL | `sessionId, Entity` | void |
| `SessionManager.appendRelation()` | Append relation line to JSONL | `sessionId, Relation` | void |

### 7.3 coaia-narrative Types Used

coaia-agent treats `coaia-narrative/src/types.ts` as the schema authority for:
- `Entity` and `Relation` interfaces
- `EntityMetadata` (current flat form; extended form from schema-evolution spec when adopted)
- `KnowledgeGraph` (for batch operations)

### 7.4 coaia-planning Tools Used (Optional)

| Tool | Purpose | Input | Output |
|------|---------|-------|--------|
| `pde_to_plan` | PDE → Plan JSONL (parallel path) | `{ pde_id, workdir? }` | JSONL string or file |
| `sync_plan_to_chart` | Plan markdown → chart update | `{ plan_path, charts_path, dry_run? }` | Change list |
| `sync_chart_to_plan` | Chart state → plan markdown | `{ charts_path, plan_path, dry_run? }` | Markdown string |

---

## 8. Acceptance Criteria

- [ ] coaia-agent starts successfully with only mcp-pde, coaia-pde, and coaia-narrative available
- [ ] Absence of coaia-visualizer produces a graceful log message and does not halt the session
- [ ] Absence of coaia-planning produces a graceful log message and does not halt the session
- [ ] All `action_step` entities written by coaia-agent carry `metadata.direction` in UPPERCASE
- [ ] `normalizeDirection()` adapter is applied before any direction value is written to JSONL
- [ ] Schema drift between mcp-pde and coaia-pde types is detected and logged as a warning, not an error
- [ ] `metadata.source.system` is set on every entity produced by coaia-agent (value: `'coaia-agent'` for coaia-agent-generated entities, or the delegating package's system string)
- [ ] Storage root ownership is respected: coaia-agent writes only through the owning package's API or to its own session-summary artifact
