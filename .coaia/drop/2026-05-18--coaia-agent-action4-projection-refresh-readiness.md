# Coaia-Agent Action 4 — Canonical Center Projection / Refresh Readiness

Date: 2026-05-18
Chart: `chart_1778353216690`
Action: `chart_1778353216690_action_4`
Telescope: `chart_1778353216690_action_4_telescope_260518`
Scope: `/src/coaia-agent` only

## Readiness decision

Action 4 is now concrete enough to become a Canonical Center Projection / Refresh Readiness lane.

The center is still `.coaia/narrative/coaia-agent-memory.jsonl`. Asterion, GitHub Projects, and visualizer views are projections/lenses over that memory, not replacement sources of truth.

## Canonical memory remains authoritative

Authoritative path:

```bash
/src/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl
```

Rules:

1. Treat COAIA JSONL records as chart truth: chart, desired outcome, current reality, action steps, narrative beats, and relations.
2. Write additive metadata only; do not flatten or replace existing rich fields.
3. Preserve these metadata families when present:
   - `metadata.narrative`
   - `metadata.fourDirections`
   - source refs
   - `metadata.github`
   - `metadata.asterion.*`
4. Run the repo-local validator before and after any JSONL write:

```bash
cd /src/coaia-agent
./scripts/validate-coaia-memory.py .coaia/narrative/coaia-agent-memory.jsonl
```

## How `coaia-narrative@0.13.1` helps writes / MCP

Published package fact inspected with `npm view coaia-narrative@0.13.1`:

- package: `coaia-narrative`
- version: `0.13.1`
- description: Creative Orientation AI Agentic Memories - Narrative Beat Extension with IAIP relational integration
- bins:
  - `coaia-narrative` -> `dist/index.js`
  - `cnarrative` -> `dist/cli.js`

Implication for the canonical center:

- It remains the package-side authority for narrative JSONL schema and MCP/CLI writes.
- The new package fact should replace older `coaia-narrative@0.13.0` command references in deployed MCP/container config before any refresh.
- Coaia-Agent should still wrap package writes with `scripts/validate-coaia-memory.py` because previous tooling may flatten rich metadata.

## How `coaia-visualizer@1.6.1` helps human/chart viewing

Published package fact inspected with `npm view coaia-visualizer@1.6.1`:

- package: `coaia-visualizer`
- version: `1.6.1`
- description: dedicated client-side application for visualizing and interacting with `coaia-narrative` JSONL data representing Structural Tension Charts and Multi-Universe Narrative
- bin:
  - `coaia-visualizer` -> `dist/cli.js`
- exports include:
  - `./lib/types`
  - `./lib/jsonl-parser`
  - `./lib/utils`
  - hooks/components/styles

Implication for the canonical center:

- It can render/inspect the canonical JSONL without becoming the writer of record.
- Its JSONL parser/types/components are useful for human-visible chart validation and projection smoke tests.
- Existing repo docs still mention `coaia-visualizer@1.6.0`; those references need a scoped doc/config update to `1.6.1` before Docker refresh.

## How `asterion-system-design` helps projection/schema

Inspected key local files:

- `asterion-system-design/CHECKPOINT-coaia-agent-operating-model-260517.md`
- `asterion-system-design/lib/asterion/types.ts`
- `asterion-system-design/lib/asterion/tensions.ts`
- `asterion-system-design/lib/asterion/data.ts`
- `asterion-system-design/package.json`

Asterion concepts useful for projection:

| COAIA JSONL center | Asterion projection concept | Notes |
|---|---|---|
| `structural_tension_chart` entity | `Tension` | map `desired_outcome`, `current_reality`, phase/status/progress, parent/source action lineage |
| `action_step` entity | `ActionStep` | map status, order, `telescopedToChartId` -> `telescoped_to_tension_id` |
| `telescopes_to` relation | `telescopeActionStep()` / parent-child tension | preserve lineage from parent chart and source action step |
| `narrative_beat` | `NarrativeBeat` | preserve orientation shifts and implementation traces |
| `metadata.github` | Tension GitHub bridge fields + `github_sync_state` | project as accountability state, not authority |
| entity/relation records | Asterion `Entity` / `Relation` graph | useful for graph inspection and docs links |
| session-close facts | `AsterionEvent` / observation | event timeline can mirror, not replace, JSONL memory |
| GitHub Project views | `Project` / `ProjectTension` lens | projects are lenses over tensions, not containers |

Asterion checkpoint line of force:

- GitHub Projects are projected operating memory.
- Coaia-Agent writes canonical `metadata.github` and preserves exact project field names.
- Asterion exposes tensions/action steps/beats/projects/entities/relations as graphable surfaces.
- Acceptance is one chart projecting into fields/rendering without inventing a new metadata family.

## Exact package-upgrade deltas still needed

No `package.json` in `/src/coaia-agent` currently imports `coaia-narrative` or `coaia-visualizer` directly.

Known scoped deltas before refresh:

1. Deployed MCP command/config:
   - old documented command: `npx -y coaia-narrative@0.13.0`
   - target: `npx -y coaia-narrative@0.13.1`
2. Visualizer docs/runtime command references:
   - old repo references: `coaia-visualizer@1.6.0`
   - target: `coaia-visualizer@1.6.1`
3. Container image/package install path:
   - ensure the Docker build installs or can `npx` the exact versions above.
4. Runtime smoke checks:
   - `npx -y coaia-narrative@0.13.1 --help` or MCP stdio startup check
   - `npx -y coaia-visualizer@1.6.1 --help` or visualizer startup check
5. Validator hook:
   - run `scripts/validate-coaia-memory.py` before and after any package-mediated memory write.

## Docker refresh prerequisites

Do not rebuild/restart yet. Refresh only after:

1. `.coaia/narrative/coaia-agent-memory.jsonl` validates cleanly.
2. Drop artifacts are present and backed up.
3. MCP config points at `coaia-narrative@0.13.1` and the mounted memory path.
4. Visualizer command/docs point at `coaia-visualizer@1.6.1`.
5. Container has the same `/workspace/coaia-agent` memory mount as host `/src/coaia-agent`.
6. The validator script is present in the container or mount.
7. GitHub tokens stay out of public UI containers; any sync worker remains separately accountable.

## JSONL update performed

Added/updated Action 4 telescope state in the canonical memory:

- updated `chart_1778353216690_action_4` with `metadata.telescopedToChartId = chart_1778353216690_action_4_telescope_260518`
- added `chart_1778353216690_action_4_telescope_260518`
- added `chart_1778353216690_action_4_telescope_260518_current_reality`
- added telescope/contains relations

Pre-write validator result:

```text
COAIA memory validation OK
records parsed: 40
stable named records: 23
relations: 17
records with protected rich metadata: 3
baseline: HEAD:.coaia/narrative/coaia-agent-memory.jsonl (23 records)
```

Post-write validator result:

```text
COAIA memory validation OK
records parsed: 45
stable named records: 25
relations: 20
records with protected rich metadata: 5
baseline: HEAD:.coaia/narrative/coaia-agent-memory.jsonl (23 records)
```

## Next 3 executable moves

1. Add a tiny projection helper spec/test inside `/src/coaia-agent` that maps one COAIA chart JSONL into an Asterion-shaped object without writing to Asterion storage.
2. Update scoped repo docs/config references from `coaia-narrative@0.13.0` / `coaia-visualizer@1.6.0` to `0.13.1` / `1.6.1`, then rerun the JSONL validator.
3. Perform a no-Docker smoke plan: verify package CLIs/MCP startup commands and container mount assumptions, then decide whether a guarded Docker rebuild/restart is warranted.
