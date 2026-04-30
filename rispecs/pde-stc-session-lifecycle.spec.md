# PDE → STC Session Lifecycle — RISE Specification

> How coaia-agent initializes, advances, and closes a full Prompt Decomposition Engine → Structural Tension Chart session, treating the `.pde/<timestamp>--<uuid>/` folder-backed artifact as the canonical organizing contract.

**Version**: 1.0.0  
**Document ID**: pde-stc-session-lifecycle-v1  
**Last Updated**: 2026-04-29  
**Status**: Draft (spec-only; no runtime code exists)  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Cross-references**:
- [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md) — package roles, storage ownership
- [`visualizer-planning-narrative-flow.spec.md`](./visualizer-planning-narrative-flow.spec.md) — downstream artifact flow
- [`prompt-skill-runtime.spec.md`](./prompt-skill-runtime.spec.md) — runtime invocation of lifecycle steps
- `mcp-pde/src/storage.ts` — `.pde/` folder layout implementation
- `coaia-pde/src/session-manager.ts` — `.coaia/pde/` write path
- `coaia-pde/src/stc-mapper.ts` — DecompositionResult → Entity/Relation transform
- `coaia-narrative/rispecs/schema-evolution-and-ecosystem-metadata.spec.md` — typed sub-objects proposal

---

## Desired Outcome

Practitioners and implementation teams have a single authoritative diagram for how coaia-agent advances a prompt through decomposition, STC creation, and downstream consumption. Each lifecycle step produces a named artifact at a named filesystem path. An implementation team can rebuild any step by reading this spec alone.

---

## Structural Tension

**Current Reality**  
The artifact flow from prompt to visualization crosses four independent packages (`mcp-pde` → `coaia-pde` → `coaia-narrative` schema → `coaia-visualizer`) with no single document describing the full lifecycle. Artifacts exist at three independent storage roots with only field-level links between them. Three layout patterns co-exist (folder-backed, flat-json, plan-output) with no single document declaring which is preferred and how compatibility works.

**Desired Outcome**  
coaia-agent defines a canonical lifecycle contract. Every step has a named input, a named output artifact, and a declared relationship to the step before and after it. The folder-backed `.pde/<timestamp>--<uuid>/` pattern is the preferred organizing root. Compatibility rules for the two legacy layouts are explicit, not inferred.

**Tension**  
The gap is not about missing code — most transformation logic exists in `mcp-pde` and `coaia-pde`. The gap is a missing lifecycle boundary document that coaia-agent can enforce and that implementation teams can test against.

---

## 1. Preferred Artifact Layout: Folder-Backed PDE Tree

### 1.1 Canonical Structure

```
<workdir>/
├── .pde/
│   └── <YYMMDDHHMI>--<pde-uuid>/          ← preferred organizing root (Layout A)
│       ├── pde-<pde-uuid>.json             ← StoredDecomposition (full JSON)
│       ├── pde-<pde-uuid>.md              ← markdown export (Four Directions first)
│       ├── meta.json                       ← (optional) miaco-compatible tree metadata
│       └── <child-ts>--<child-uuid>/       ← child PDEs nested here (mcp-pde v2.1)
│           ├── pde-<child-uuid>.json
│           └── pde-<child-uuid>.md
└── .coaia/
    └── pde/
        └── <session-uuid>.jsonl           ← STC session (Layout B)
```

### 1.2 The Folder Name Contract

The folder `<YYMMDDHHMI>--<pde-uuid>` carries two pieces of information in one path segment:

| Part | Format | Meaning |
|------|--------|---------|
| `<YYMMDDHHMI>` | `yyMMddHHmm` (10 chars) | Sortable creation timestamp |
| `<pde-uuid>` | UUID v4 | Globally unique decomposition identity |

Lookup by UUID is folder-suffix search: `endsWith('--<uuid>')`. This is implemented in `mcp-pde/src/storage.ts:findFolderByUuid()` and must be used by any code that loads a StoredDecomposition from disk.

### 1.3 Import Compatibility for Legacy Layouts

coaia-agent **must accept** these layouts on read and **must not produce** them on write:

| Layout | Path pattern | Detection | Notes |
|--------|-------------|-----------|-------|
| **A (preferred)** | `.pde/<ts>--<uuid>/pde-<uuid>.json` | Folder suffix `--<uuid>` | Canonical for all new PDE writes |
| **B-flat (legacy)** | `.pde/<uuid>.json` | File name equals `<uuid>.json` | `mcp-pde` pre-v2.1 output; still readable |
| **C-nested (miaco)** | `.pde/<ts>--<parent-uuid>/<ts>--<child-uuid>/pde-<child-uuid>.json` | Recursive folder search | miaco child PDEs; same lookup algorithm as A |
| **D-plan (coaia-planning)** | `COAIA_OUTPUT_DIR/<plan-name>.jsonl` | Configurable env var | No `pde_session` header; plan-sourced, not PDE-sourced |

When loading by UUID, try in order: A → B-flat → C-nested. If none found, return `null` (no crash).

---

## 2. Lifecycle Stages and Artifacts

### 2.1 Full Lifecycle Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        coaia-agent Lifecycle Contract                        │
└──────────────────────────────────────────────────────────────────────────────┘

User Prompt
    │
    ▼
[Stage 1: Decompose]
    mcp-pde.pde_decompose(prompt, workdir, parent_pde_id?)
    │   Writes: .pde/<ts>--<pde-uuid>/pde-<pde-uuid>.json   (StoredDecomposition)
    │           .pde/<ts>--<pde-uuid>/pde-<pde-uuid>.md     (markdown, Four Directions first)
    │   Returns: StoredDecomposition { id, result: DecompositionResult, folder_name }
    │
    ▼
[Stage 2: Import → STC]          ← PRIMARY PATH (PDE → STC)
    coaia-pde: import <pde-uuid>
    │   Reads:  .pde/<ts>--<pde-uuid>/pde-<pde-uuid>.json
    │   Calls:  stcMapper.mapDecompositionToChart(result, prompt, { pdeId })
    │   Writes: .coaia/pde/<session-uuid>.jsonl
    │           Line 1: { type: 'pde_session', sessionId, pdeDecompositionId, masterChartId, ... }
    │           Line N: { type: 'entity', ...Entity }     (chart, desired_outcome, current_reality, action_step)
    │           Line M: { type: 'relation', ...Relation } (has_desired_outcome, creates_tension_with, etc.)
    │   Returns: PdeSession { sessionId, masterChartId, pdeDecompositionId }
    │
    ├──▶ [Stage 3a: Visualize]
    │       coaia-visualizer --memory-path .coaia/pde/<session-uuid>.jsonl
    │       Reads: JSONL file (4-pass algorithm: separate → chart shells → populate → hierarchy)
    │       Note: pde_session header currently ignored; fourDirections not yet rendered
    │             (see visualizer-planning-narrative-flow.spec.md for readiness spec)
    │
    ├──▶ [Stage 3b: Plan Sync]   ← PARALLEL PATH (PDE → Plan → STC)
    │       coaia-planning.pde_to_plan(pde_id: "<pde-uuid>")
    │       Reads:  .pde/<ts>--<pde-uuid>/pde-<pde-uuid>.json
    │       Writes: COAIA_OUTPUT_DIR/<plan-name>.jsonl
    │               (same entity/relation schema; no pde_session header; metadata.source='pde_decomposition')
    │       Then:   sync_plan_to_chart / sync_chart_to_plan for bidirectional sync
    │
    └──▶ [Stage 3c: Narrative]
            coaia-narrative MCP tools read .coaia/pde/<session-uuid>.jsonl
            append narrative_beat entities, MMOT evaluations, accountability annotations
            write back to same JSONL file (append-only by default)

[Stage 4: Session Close / Summary]
    coaia-agent updates PdeSession.status → 'completed'
    writes session summary artifact under .pde/<ts>--<pde-uuid>/session-summary.md
    (optional: Veritas Type 2 review triggered here — see veritas-mmot-companion.spec.md)
```

### 2.2 Artifacts per Stage

| Stage | Artifact | Path Pattern | Owned by | Consumed by |
|-------|----------|-------------|----------|-------------|
| 1. Decompose | `StoredDecomposition` JSON | `.pde/<ts>--<uuid>/pde-<uuid>.json` | mcp-pde | coaia-pde, coaia-planning |
| 1. Decompose | Markdown export | `.pde/<ts>--<uuid>/pde-<uuid>.md` | mcp-pde | humans, miaco, SOUTH survey lanes |
| 2. Import STC | JSONL session | `.coaia/pde/<session-uuid>.jsonl` | coaia-pde | coaia-visualizer, coaia-narrative |
| 3a. Visualize | (read-only) | `.coaia/pde/<session-uuid>.jsonl` | coaia-visualizer | practitioners |
| 3b. Plan Sync | Plan JSONL | `COAIA_OUTPUT_DIR/<name>.jsonl` | coaia-planning | coaia-visualizer, coaia-narrative |
| 3c. Narrative | Narrative beats | `.coaia/pde/<session-uuid>.jsonl` (appended) | coaia-narrative | coaia-visualizer |
| 4. Close | Session summary | `.pde/<ts>--<uuid>/session-summary.md` | coaia-agent | humans, Veritas |

---

## 3. STC Entity/Relation Mapping Contract

### 3.1 Entity Types

This table is the authoritative mapping contract for coaia-agent v1. It aligns `mcp-pde/src/types.ts` (input) with `coaia-narrative/src/types.ts` (output schema).

| PDE Input Field | STC Entity Name Pattern | entityType | Key Metadata |
|----------------|------------------------|------------|-------------|
| `primary.action + primary.target` | `<chartId>_chart` | `structural_tension_chart` | `chartId`, `dueDate` (from urgency), `phase: 'germination'`, `pdeId`, `fourDirections` |
| `primary` + `outputs.*` | `<chartId>_desired_outcome` | `desired_outcome` | `chartId`, `confidence` |
| `context` + `ambiguities` | `<chartId>_current_reality` | `current_reality` | `chartId` |
| `secondary[N]` | `<chartId>_action_<N>` | `action_step` | `chartId`, `implicit`, `confidence`, `dueDate` (distributed), `direction` (UPPERCASE — see §4) |
| `actionStack[M]` | `<chartId>_action_<N+M>` | `action_step` | `chartId`, `direction` (UPPERCASE), `completionStatus`, `dueDate` |

### 3.2 Relation Types

| relationType | From | To | When Present |
|-------------|------|----|-------------|
| `has_desired_outcome` | chart | desired_outcome | Always |
| `has_current_reality` | chart | current_reality | Always |
| `has_action_step` | chart | action_step | Per action step |
| `advances_toward` | action_step | desired_outcome | Per action step |
| `creates_tension_with` | current_reality | desired_outcome | Always |
| `depends_on` | action_step | action_step | When dependency text matches an existing action |

### 3.3 `fourDirections` Key Naming

The `stc-mapper.ts` currently writes:

```typescript
fourDirections: {
  north_vision:      string | null,  // ← directions.north items joined
  east_intention:    string | null,  // ← directions.east items joined
  south_emotion:     string | null,  // ← directions.south items joined (key name mismatch — see §5)
  west_introspection: string | null, // ← directions.west items joined (key name mismatch — see §5)
}
```

coaia-agent **must write and read** this exact key structure for v1 compatibility. Key name alignment with Medicine Wheel role language is deferred to human cultural authority review (see `contradictions.md`).

### 3.4 JSONL Line Format

Every line in `.coaia/pde/<session-uuid>.jsonl` is a self-contained JSON object:

```
Line 1:  { "type": "pde_session", "sessionId": "...", "pdeDecompositionId": "...", "masterChartId": "...", ... }
Line 2:  { "type": "entity", "name": "<chartId>_chart", "entityType": "structural_tension_chart", "observations": [...], "metadata": {...} }
Line 3:  { "type": "entity", "name": "<chartId>_desired_outcome", ... }
Line 4:  { "type": "entity", "name": "<chartId>_current_reality", ... }
Lines 5+: { "type": "entity", "name": "<chartId>_action_N", ... }
Lines N+: { "type": "relation", "from": "...", "to": "...", "relationType": "...", ... }
Lines M+: (appended narrative_beat entities, MMOT evaluations, Veritas notes — Stage 3c/4)
```

---

## 4. URGENCY → dueDate Mapping

coaia-agent inherits `URGENCY_DAYS` from `coaia-pde/src/types.ts`:

| PrimaryIntent.urgency | Days to dueDate |
|----------------------|-----------------|
| `immediate` | 1 |
| `session` | 7 |
| `persistent` | 30 |

Action step due dates are distributed evenly between session start and chart dueDate.

---

## 5. Contradictions This Spec Does Not Resolve

These are documented in `contradictions.md` and **must not** be silently resolved by implementation:

| Contradiction | Status in v1 |
|--------------|-------------|
| Direction casing: lowercase (runtime) vs. Title-case (mmot) vs. UPPERCASE (rispecs proposal) | coaia-agent **must normalize to UPPERCASE on write** (see `coaia-package-consumption.spec.md §5`) |
| `fourDirections` key suffix semantics (`south_emotion` ≠ Planning&Growth) | **Preserve existing keys in v1**; flag for cultural authority review |
| `pde_session` line not recognized by coaia-visualizer | **Write it anyway** for future visualizer readiness; visualizer silently skips it today |
| Schema drift between `mcp-pde/src/types.ts` and `coaia-pde/src/types.ts` | **Document as risk**; coaia-agent must use `mcp-pde` types as authoritative |
| No source provenance discriminator in JSONL (coaia-narrative vs. coaia-pde vs. coaia-planning vs. manual) | **Write `metadata.source.system`** per `schema-evolution-and-ecosystem-metadata.spec.md` proposal |

---

## 6. `pde_session` Header — Full Field Contract

coaia-agent must write the `pde_session` header with these fields so that when `coaia-visualizer/rispecs/pde-integration.spec.md` is implemented, no schema change is needed:

```typescript
interface PdeSessionHeader {
  type: 'pde_session';
  sessionId: string;           // UUID of this JSONL session (coaia-pde generated)
  pdeDecompositionId: string;  // UUID of the source StoredDecomposition in .pde/
  masterChartId: string;       // chartId of the root structural_tension_chart entity
  originalPrompt: string;      // The original user prompt (from StoredDecomposition.prompt)
  facetCount: number;          // secondary.length + actionStack.length
  implicitCount: number;       // count of secondary[].implicit === true
  createdAt: string;           // ISO-8601
  updatedAt: string;           // ISO-8601
  status: 'active' | 'completed' | 'abandoned';
  pdeFolder: string;           // folder_name: e.g. "2604291317--4da3f9f5-..."
}
```

Fields `facetCount`, `implicitCount`, `originalPrompt`, and `pdeFolder` are not written by the current `coaia-pde/session-manager.ts` — coaia-agent adds them. The visualizer's future `PdeSourceBadge` component depends on `facetCount`, `implicitCount`, and `originalPrompt`.

---

## 7. Parallel Paths: PDE→STC vs. Plan→STC

Two paths produce coaia-narrative-compatible JSONL:

```
Path A (Primary)                    Path B (Parallel)
───────────────                     ────────────────
User prompt                         Plan markdown
    │                                   │
mcp-pde.pde_decompose                coaia-planning.plan_to_stc
    │                                   │
StoredDecomposition                  StructuralTensionPlan
    │                                   │
coaia-pde.stc-mapper                 coaia-planning.planToSTC()
    │                                   │
.coaia/pde/<uuid>.jsonl              COAIA_OUTPUT_DIR/<name>.jsonl
(with pde_session header)            (no pde_session header)
(metadata.source.system='coaia-pde') (metadata.source.system='coaia-planning')
```

A combined path is also valid: `pde_decompose` → `pde_to_plan` → `sync_plan_to_chart`. When a JSONL file has been produced by this combined path, both `pde_session` and `metadata.plan.*` should be present (pending `schema-evolution-and-ecosystem-metadata.spec.md` Phase 2 adoption).

---

## 8. Acceptance Criteria

- [ ] A JSONL file produced by coaia-agent passes the 4-pass parse in `coaia-visualizer/lib/jsonl-parser.ts` without errors
- [ ] Every `action_step` entity carries `metadata.direction` in UPPERCASE
- [ ] The `pde_session` header line includes `pdeDecompositionId`, `masterChartId`, `facetCount`, `implicitCount`, `originalPrompt`, and `pdeFolder`
- [ ] `loadDecomposition(workdir, pde-uuid)` succeeds for Layout A, B-flat, and C-nested inputs
- [ ] `metadata.source.system` is set on every entity produced by coaia-agent
- [ ] Closing a session writes `session-summary.md` under the `.pde/<ts>--<uuid>/` folder
- [ ] No new JSONL format is invented — all output conforms to the `coaia-narrative/src/types.ts` Entity/Relation schema
