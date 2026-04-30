# Visualizer–Planning–Narrative Flow — RISE Specification

> How artifacts flow from PDE decomposition through STC creation, narrative beat appending, coaia-planning bidirectional sync, and into the visualizer's 4-pass parse pipeline — and what coaia-agent must produce so that aspirational visualizer components can be implemented without schema changes.

**Version**: 1.0.0  
**Document ID**: visualizer-planning-narrative-flow-v1  
**Last Updated**: 2026-04-29  
**Status**: Draft (spec-only)  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Cross-references**:
- [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md) — authoritative lifecycle and entity mapping
- [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md) — package roles and adapter responsibilities
- [`prompt-skill-runtime.spec.md`](./prompt-skill-runtime.spec.md) — runtime hooks and provenance recording
- `coaia-visualizer/rispecs/pde-integration.spec.md` — aspirational visualizer PDE rendering (not yet implemented)
- `coaia-narrative/rispecs/schema-evolution-and-ecosystem-metadata.spec.md` — proposed metadata sub-objects
- `coaia-planning/rispecs/pde-bridge.spec.md` — parallel Plan→STC path
- `coaia-narrative/rispecs/bidirectional-sync.spec.md` — sync semantics
- `mia-code/rispecs/stc.rispecs.md` — miaco STC precedent (conceptual transfer)

---

## Desired Outcome

Given a completed PDE decomposition, a practitioner using coaia-agent can:
1. Create a STC session whose JSONL is immediately renderable by the existing coaia-visualizer
2. Append narrative beats that the visualizer will surface when PDE metadata rendering is activated
3. Sync the decomposition to a plan via coaia-planning's `pde_to_plan` tool
4. Receive bidirectional sync updates when the plan diverges from the STC
5. Read a `session-summary.md` that captures the full artifact trail

All of this happens without schema changes to any package. New visualizer PDE components read the same JSONL that coaia-agent produces today.

---

## Structural Tension

**Current Reality**  
coaia-visualizer ignores the `pde_session` header line completely. It does not render `fourDirections`, `implicit`, `confidence`, or `direction` on any action_step entity. coaia-planning writes `metadata.source = 'pde_decomposition'` as a flat string, not the proposed sub-object. There is no session summary output format defined. Direction casing is inconsistent across three subsystems. The two STC production paths (PDE→STC and Plan→STC) produce JSONL with different headers.

**Desired Outcome**  
coaia-agent produces JSONL today that:
- Is renderable by the visualizer's current 4-pass algorithm
- Carries all fields needed by aspirational visualizer components — so future implementation requires zero schema changes
- Exposes narrative beats in a form the visualizer can surface with minimal new parsing logic
- Is consistent enough that bidirectional sync between the STC and the plan does not corrupt entity metadata

---

## 1. End-to-End Artifact Flow

```
[PDE Decomposition in .pde/]
      │
      │ Stage 2: coaia-pde stc-mapper.ts
      ▼
[.coaia/pde/<uuid>.jsonl]
      │
      ├──▶ Line 1: pde_session header
      ├──▶ Lines 2-N: entity records (chart, desired_outcome, current_reality, action_step)
      └──▶ Lines N+1+: relation records + narrative_beat records (appended later)
             │
             ├──▶ coaia-visualizer (4-pass parse, current)
             │         renders: chart shells, desired_outcome, current_reality, action_steps
             │         ignores: pde_session header, fourDirections, implicit, confidence
             │
             └──▶ coaia-visualizer (aspirational, post pde-integration.spec.md)
                       renders all of the above
                       PLUS: direction badges, confidence bars, implicit intent flags

[PDE Decomposition in .pde/]
      │
      │ Stage 3 (parallel): coaia-planning pde_to_plan
      ▼
[PLANS_DIR/<name>.md or similar]
      │
      │ pde_to_plan tool
      ▼
[COAIA_OUTPUT_DIR/<name>.jsonl]
      │  No pde_session header
      │  metadata.source = 'pde_decomposition' (flat string, not sub-object)
      │  DIVERGES from coaia-pde JSONL — see §5
      │
      └──▶ coaia-visualizer (same 4-pass, different header)
```

---

## 2. JSONL Line-by-Line Format Contract

### 2.1 pde_session Header (Line 1)

Line 1 of every `.coaia/pde/<uuid>.jsonl` file is the `pde_session` header. coaia-agent must ensure it is written before any entity or relation line. The fields coaia-agent adds on top of coaia-pde's `initSession()` output:

```typescript
// Mandatory fields (written by coaia-pde initSession)
{
  type: 'pde_session',
  sessionId: string,          // STC session UUID
  pdeDecompositionId: string, // PDE decomposition UUID
  masterChartId: string,
  originalPrompt: string,
  createdAt: string,          // ISO-8601
  updatedAt: string,          // ISO-8601
  status: 'active' | 'completed' | 'abandoned'
}

// Additional fields coaia-agent MUST ensure are present (may require patching after init)
{
  facetCount: number,         // total secondary[] items in DecompositionResult
  implicitCount: number,      // secondary[] items where implicit === true
  pdeFolder: string,          // e.g. "2604291317--4da3f9f5-..." (Layout A folder name)
  agentSessionId: string,     // coaia-agent session UUID (≠ PDE UUID, ≠ STC session UUID)
  layoutVersion: '2' | '1',  // '2' = folder-backed, '1' = flat
}
```

**Visualizer readiness note**: `pde-integration.spec.md` specifies that the visualizer will read `pde_session.pdeDecompositionId`, `pde_session.masterChartId`, `pde_session.facetCount`, and `pde_session.implicitCount` to render PDE metadata in the chart header panel. These fields must be present in Line 1 today so that aspirational visualizer rendering requires no JSONL changes.

### 2.2 Entity Lines

Each entity line is a standalone JSON object on a single line:

```typescript
{
  type: 'entity',
  id: string,          // e.g. "<chartId>_chart"
  category: string,    // structural_tension_chart | desired_outcome | current_reality |
                       // action_step | narrative_beat
  label: string,
  metadata: EntityMetadata  // see coaia-narrative/src/types.ts
}
```

Entity lines must be valid JSON parseable by `JSON.parse()`. No trailing commas. No newlines inside the object.

### 2.3 Relation Lines

```typescript
{
  type: 'relation',
  sourceId: string,
  targetId: string,
  relationshipType: string,  // see lifecycle spec §4 for canonical list
  metadata?: RelationMetadata
}
```

### 2.4 Narrative Beat Lines

```typescript
{
  type: 'entity',
  id: string,          // e.g. "<masterChartId>_beat_<timestamp>"
  category: 'narrative_beat',
  label: string,       // one-line human summary
  metadata: {
    content: string,           // full narrative text
    beatType: 'observation' | 'reflection' | 'decision' | 'closing',
    direction?: CanonicalDirection,  // UPPERCASE
    mmotEvaluations?: MmotEvaluation[],
    source: {
      system: 'coaia-agent',
      sessionId: string,       // agentSessionId
      toolName: 'narrative-append',
      createdAt: string
    }
  }
}
```

The relation that connects a narrative beat to its chart:

```typescript
{
  type: 'relation',
  sourceId: '<masterChartId>_chart',
  targetId: '<masterChartId>_beat_<timestamp>',
  relationshipType: 'has_narrative_beat'
}
```

**Visualizer readiness note**: `pde-integration.spec.md` §6 specifies that narrative beats will be rendered in a timeline panel per chart. The `has_narrative_beat` relation type and the `narrative_beat` category are the hooks the visualizer will use to find and render them. coaia-agent must use exactly these strings.

---

## 3. Direction Normalization in JSONL Output

Direction casing is inconsistent across the ecosystem (see lifecycle spec §8, Contradictions Table). coaia-agent's normalization rule:

| Context | Canonical Form | Applied By |
|---------|----------------|-----------|
| `entity.metadata.direction` on action_step | UPPERCASE | coaia-agent ContextInjector before write |
| `entity.metadata.fourDirections` keys | Not normalized (preserve existing key names) | — |
| `entity.metadata.mmotEvaluations[].direction` | UPPERCASE | coaia-agent before appending narrative beat |
| `pde_session.direction` (if added) | UPPERCASE | coaia-agent before writing header patch |
| coaia-pde runtime direction values | Lowercase (mcp-pde types.ts native) | Not changed — coaia-agent reads; normalizes only on write |

**Warning**: `fourDirections` key names (`north_vision`, `east_intention`, `south_emotion`, `west_introspection`) are preserved as-is in v1. They represent a semantic mismatch with Medicine Wheel roles (see lifecycle spec §8.3) but are not corrected here — cultural authority review is required.

---

## 4. Narrative Beat Appending Protocol

### 4.1 When Beats Are Appended

Narrative beats are appended by the `narrative-append` skill during Stage `narrative` (see prompt-skill-runtime.spec.md §8.1). They are always appended AFTER the entity and relation block — never inserted between existing lines. JSONL is append-only.

### 4.2 Session Summary Narrative Beat

At `session-close`, coaia-agent appends a final `closing` narrative beat that contains the session summary:

```typescript
{
  type: 'entity',
  id: '<masterChartId>_beat_close',
  category: 'narrative_beat',
  label: 'Session close summary',
  metadata: {
    content: '<full session summary text — see §6>',
    beatType: 'closing',
    source: {
      system: 'coaia-agent',
      sessionId: agentSessionId,
      toolName: 'session-close',
      createdAt: ISO8601
    }
  }
}
```

---

## 5. Two Parallel STC Paths — Differences and Compatibility

### 5.1 Path A (Primary): PDE → coaia-pde → .coaia/pde/

```
.pde/<ts>--<pde-uuid>/pde-<pde-uuid>.json
        │ coaia-pde stc-mapper.ts + session-manager.ts
        ▼
.coaia/pde/<stc-uuid>.jsonl
        │ Line 1: pde_session header (see §2.1)
        │ Lines 2-N: entity/relation block
        └ Lines N+1+: narrative beats (appended)
```

**Characteristics**:
- Has `pde_session` header on Line 1
- `metadata.source` reflects coaia-pde or coaia-narrative
- Direction on action_step entities: normalized to UPPERCASE by coaia-agent adapter before write
- `fourDirections` field present on action_step `metadata`

### 5.2 Path B (Parallel): PDE → coaia-planning → COAIA_OUTPUT_DIR

```
.pde/<ts>--<pde-uuid>/pde-<pde-uuid>.json
        │ coaia-planning decompositionResultToPlan() + pde_to_plan tool
        ▼
COAIA_OUTPUT_DIR/<plan-name>.jsonl
        │ NO pde_session header on Line 1
        │ metadata.source = 'pde_decomposition' (flat string, not sub-object)
        │ metadata.plan.planId, sectionType, confidence (proposed — not yet implemented)
        └ No narrative beats
```

**Characteristics**:
- First line is an entity, not a header — the visualizer 4-pass algorithm handles this correctly because it separates entity/relation lines first
- No `fourDirections` field
- `metadata.source` is a flat string, not the structured sub-object proposed in schema-evolution spec
- **Not a bug** — this is Path B's defined behavior; implementations must not conflate the two paths

### 5.3 Detecting Which Path Produced a JSONL File

```typescript
// Parse Line 1
const firstLine = JSON.parse(lines[0]);
if (firstLine.type === 'pde_session') {
  // Path A — .coaia/pde/ file
  const stcSessionId = firstLine.sessionId;
  const pdeUuid = firstLine.pdeDecompositionId;
} else {
  // Path B — COAIA_OUTPUT_DIR file (or legacy coaia-narrative JSONL)
  // Check metadata.source for further disambiguation
}
```

---

## 6. Bidirectional Sync Integration

### 6.1 coaia-planning Sync Tools

coaia-planning exposes two bidirectional sync tools (per `pde-bridge.spec.md`):

| Tool | Direction | Trigger |
|------|-----------|---------|
| `sync_plan_to_chart` | Plan → STC JSONL | Human updates plan outside agent session |
| `sync_chart_to_plan` | STC JSONL → Plan | Human updates STC via agent or visualizer |

### 6.2 Sync Constraints for coaia-agent

coaia-agent must not invoke bidirectional sync tools during Stage 2 (`import-stc`) because the STC is still being written. Sync is only valid after Stage 2 completes and the JSONL file is closed.

```
Stage 2 complete (STC written)
        │
        ├──▶ plan-sync skill: runs pde_to_plan (one-way, initial) → COAIA_OUTPUT_DIR
        │
        └──▶ [later, if plan diverges]
                   sync_plan_to_chart → appends delta entities/relations to .coaia/pde/<uuid>.jsonl
                   sync_chart_to_plan → updates plan file
```

### 6.3 Sync-Generated Entity Metadata

Entities appended by sync operations must carry a `source.system` of `'coaia-planning'` and a `source.toolName` of `'sync_plan_to_chart'` or `'sync_chart_to_plan'`. coaia-agent does not modify sync-generated entities; they are treated as read-only once written.

### 6.4 Sync Idempotency

Sync tools must be idempotent: running `sync_plan_to_chart` twice with the same plan state must not append duplicate entities. coaia-agent does not enforce this — it delegates to the coaia-planning sync implementation. This constraint is recorded here because the visualizer 4-pass algorithm does not deduplicate entities by ID; duplicate entity IDs would corrupt chart rendering.

---

## 7. Visualizer Parsing Readiness

### 7.1 Current 4-Pass Algorithm (Recap)

The coaia-visualizer 4-pass JSONL parse algorithm (from deep-search findings):

```
Pass 1: Separate entity lines from relation lines
Pass 2: Identify chart shells (entities where category = 'structural_tension_chart')
Pass 3: Populate chart shells with child entities (desired_outcome, current_reality, action_step)
Pass 4: Build hierarchy (root vs. sub-charts via metadata.parentChart)
```

Pass 1 is resilient to the `pde_session` header — it is treated as neither an entity nor a relation and is silently skipped. This is the correct behavior and must be preserved.

### 7.2 What Is Not Rendered Today (Aspiration Gaps)

| Field | Location in JSONL | Not Rendered Because |
|-------|-------------------|---------------------|
| `direction` | action_step entity metadata | No direction badge UI |
| `implicit` | action_step entity metadata | No implicit intent marker UI |
| `confidence` | action_step entity metadata | No confidence bar UI |
| `fourDirections.*` | action_step entity metadata | No Four Directions grid UI |
| `pde_session` Line 1 | JSONL header | Header skipped in Pass 1 |
| `narrative_beat` entities | Later JSONL lines | No timeline panel UI |
| `has_narrative_beat` relations | Later JSONL lines | No relation type handler |

### 7.3 What coaia-agent Must Produce for Future Readiness

For each gap above, coaia-agent must ensure the field is present in the JSONL with the correct type and casing — regardless of whether the visualizer renders it today:

| Field | Required Value/Type | Who Writes It |
|-------|---------------------|--------------|
| `entity.metadata.direction` on action_step | `CanonicalDirection` (UPPERCASE) | coaia-agent adapter (via stc-mapper.ts output + normalizer) |
| `entity.metadata.implicit` on action_step | `boolean` | coaia-pde stc-mapper.ts (already written) |
| `entity.metadata.confidence` on action_step | `number` 0–1 | coaia-pde stc-mapper.ts (already written) |
| `entity.metadata.fourDirections` | object with 4 keys | coaia-pde stc-mapper.ts (already written) |
| `pde_session.facetCount` | `number` | coaia-agent (patched after coaia-pde init) |
| `pde_session.implicitCount` | `number` | coaia-agent (patched after coaia-pde init) |
| `pde_session.pdeFolder` | `string` | coaia-agent (patched after coaia-pde init) |
| `narrative_beat` entities | see §2.4 | coaia-agent narrative-append skill |
| `has_narrative_beat` relations | see §2.4 | coaia-agent narrative-append skill |

"Patched after coaia-pde init" means: coaia-agent calls `initSession()` via coaia-pde, then immediately appends the additional fields to the `pde_session` header line by rewriting Line 1. See session persistence contract in prompt-skill-runtime.spec.md §6.2.

**Important**: Rewriting Line 1 is the only allowed mutation of existing JSONL lines. All other writes are append-only.

---

## 8. Session Summary Output

### 8.1 Summary Location

The session summary is written to two locations:

1. As a `closing` narrative beat appended to `.coaia/pde/<stc-uuid>.jsonl` (see §4.2)
2. As a standalone markdown file: `.pde/<ts>--<pde-uuid>/session-summary.md`

The markdown file is for human consumption; the JSONL beat is for programmatic access by the visualizer.

### 8.2 session-summary.md Structure

```markdown
# Session Summary

**Agent Session ID**: <agentSessionId>
**PDE UUID**: <pdeUuid>
**PDE Folder**: <pdeFolderName>
**STC Session UUID**: <stcSessionUuid>
**Master Chart ID**: <masterChartId>
**Status**: completed | abandoned
**Created**: <ISO-8601>
**Closed**: <ISO-8601>

## Original Prompt

<originalPrompt>

## Artifacts Produced

| Artifact | Path | Type |
|----------|------|------|
| PDE JSON | `.pde/<folder>/pde-<uuid>.json` | pde-json |
| PDE Markdown | `.pde/<folder>/pde-<uuid>.md` | pde-markdown |
| STC JSONL | `.coaia/pde/<stc-uuid>.jsonl` | stc-jsonl |
| Plan JSONL (if created) | `<COAIA_OUTPUT_DIR>/<name>.jsonl` | plan-jsonl |

## Lifecycle Provenance

| Stage | Skill | Duration | Status |
|-------|-------|----------|--------|
| decompose | pde-decompose | Xms | completed |
| import-stc | stc-import | Xms | completed |
| narrative | narrative-append | Xms | completed |
| close | session-close | Xms | completed |

## Review Windows

| Stage | Opened At | Closed At | Decision |
|-------|-----------|-----------|---------|
| decompose | <ISO-8601> | <ISO-8601> | continue |
| close | <ISO-8601> | <ISO-8601> | continue |

## Known Contradictions

Direction casing: mcp-pde runtime uses lowercase; coaia-narrative mmotEvaluations uses Title-case;
spec proposals use UPPERCASE. coaia-agent normalized to UPPERCASE on write.

fourDirections key names (north_vision, east_intention, south_emotion, west_introspection):
preserved as-is; semantic mismatch with Medicine Wheel roles deferred to human cultural authority.
```

### 8.3 Summary File Ownership

The session summary file is owned exclusively by coaia-agent. No other package writes to it. If the file already exists (crash recovery scenario), it is overwritten with the completed summary at close time.

---

## 9. Acceptance Criteria

### 9.1 JSONL Output

- [ ] Line 1 of every `.coaia/pde/<uuid>.jsonl` produced by coaia-agent is a valid JSON object with `type === 'pde_session'`
- [ ] The `pde_session` object contains all mandatory fields from §2.1 including `facetCount`, `implicitCount`, `pdeFolder`, and `agentSessionId`
- [ ] Every action_step entity carries `metadata.direction` as UPPERCASE (`'EAST'|'SOUTH'|'WEST'|'NORTH'`)
- [ ] Every narrative beat entity uses `category: 'narrative_beat'` and is linked via `has_narrative_beat` relation
- [ ] Path A and Path B JSONL files can be correctly distinguished by checking `firstLine.type === 'pde_session'`

### 9.2 Visualizer Compatibility

- [ ] The JSONL produced by coaia-agent is parseable by the coaia-visualizer 4-pass algorithm without modification
- [ ] Charts, desired outcomes, current realities, and action steps render correctly in the current visualizer
- [ ] The `pde_session` header is silently skipped (not causing a parse error) in the current 4-pass algorithm
- [ ] No schema changes are required to implement the aspirational components from `pde-integration.spec.md`

### 9.3 Planning Integration

- [ ] `plan-sync` skill runs only after Stage 2 completes (STC JSONL closed)
- [ ] Sync-generated entities carry `metadata.source.system = 'coaia-planning'`
- [ ] Duplicate entity IDs from idempotent sync are the responsibility of coaia-planning; coaia-agent documents this boundary in the closing summary

### 9.4 Session Summary

- [ ] `session-summary.md` is written to `.pde/<ts>--<pde-uuid>/session-summary.md` at close time
- [ ] A `closing` narrative beat is appended to the JSONL at close time
- [ ] Crash recovery: if the agent session JSON exists at resume time, the summary overwrites any incomplete prior summary
- [ ] The Contradictions section of `session-summary.md` always lists the direction casing contradiction and the `fourDirections` key name mismatch
