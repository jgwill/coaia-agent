# COAIA-Agent Structural Tension Owner Plan

Date: 2026-05-18
Lane: tmux 52 / Coaia-Agent / Asterion
Scope: `/workspace/coaia-agent` only. Host mirror is `/src/coaia-agent`. Do not touch `/src/Miadi`.

## Current chart source

Canonical live chart source should remain:

- Memory: `/workspace/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl`
- MCP server: `coaia-agent-chart`
- Active chart: `chart_1778353216690`
- Desired outcome: COAIA-agent becomes a visibly self-evolving creative partner whose development work is captured as structural tension charts, narrative beats, and implementation traces that future sessions can inspect and advance.

Decision: reuse and upgrade the existing chart, not create a parallel master chart. It already has the correct north star, current-reality history, five strategic actions, and early narrative beats. Upgrade by adding telescope subcharts, current-reality observations, source refs, and session-closure intake rules.

Supporting artifacts inspected:

- `/workspace/coaia-agent/asterion-system-design/CHECKPOINT-coaia-agent-operating-model-260517.md`
- `/workspace/coaia-agent/asterion-system-design/lib/asterion/types.ts`
- `/workspace/coaia-agent/rispecs/README.md`
- `/workspace/coaia-agent/rispecs/github-project-runtime-memory-consumption.spec.md`
- `/workspace/coaia-agent/.coaia/drop/2026-05-15--tmux-hermes-navigator--futureCycleClosingOrMoonClosingCycle4Sessions.md`
- `/workspace/coaia-agent/.coaia/narrative/2026-05-13-coaia-visualizer-mcp-release-handoff.md`
- resumable sessions: `asterion-system-design/RESUME--COMMITER--2605160752.sh`, `scripts/RESUME--gitcommiter--2605121118--c0ce2cad-7af2-4dfc-b720-9ad931f63b2f.sh`

## Proposed canonical chart schema

Keep `coaia-narrative` JSONL as storage authority, and map it additively into Asterion runtime shapes:

```yaml
chart:
  chart_id: string
  title: string
  desired_outcome: string
  current_reality: string[]
  phase: germination | assimilation | completion
  telescope_depth: number
  parent_chart_id: string | null
  source_action_step_id: string | null
  status: active | paused | resolved | archived
  due_date: iso8601 | null
  progress: number
  elements_of_performance:
    - type: DESIGN | EXECUTION
      description: string
  metadata:
    source:
      system: coaia-agent
      session_title: string
      tmux_lane: string | null
      created_at: iso8601
    github:
      issue: { owner: string, repo: string, number: number, url?: string } | null
      projectItem: object | null
      syncState: synced | diverged | conflict | project-only | chart-only | null
      lastSyncedAt: iso8601 | null
      authoritativeOnLastSync: jsonl | project | null
    asterion:
      layer: runtime | memory | governance | pde | docs | security | operator
      thread_id: string | null
      source_refs: string[]

action_step:
  action_id: string
  chart_id: string
  title: string
  current_reality: string
  status: pending | in_progress | completed | blocked | skipped
  telescoped_to_chart_id: string | null
  evidence_refs: string[]

narrative_beat:
  beat_id: string
  chart_id: string
  title: string
  beat_type: session_close | orientation_shift | implementation_trace | mmot | handoff
  content: string
  source_refs: string[]
  lessons: string[]
  created_at: iso8601
```

Minimum bridge relation vocabulary:

- `contains`
- `advances_toward`
- `creates_tension_with`
- `telescopes_to`
- `linked_to_issue`
- `synced_to_github`
- `project_lens_of`

## Session-closure intake protocol

At the end of any meaningful Coaia-Agent/Asterion lane:

1. Identify lane metadata: session title, tmux pane/lane, repo path, branch/worktree, operator intent.
2. Classify the closure: observation only, action progress, completed action, narrative beat, MMOT, or new telescope candidate.
3. Write one short current-reality observation if the chart’s factual state changed.
4. Create one narrative beat when the lane changes orientation, creates an implementation trace, or reveals a reusable operating rule.
5. Attach source refs: file paths, issue URLs, resume scripts, session titles, chart/action IDs.
6. If implementation work should continue, telescope the relevant action step instead of creating a new master chart.
7. If GitHub sync exists, update `metadata.github.syncState`, `lastSyncedAt`, and `authoritativeOnLastSync`.
8. Drop a concise handoff artifact in `.coaia/drop/` when another lane or future session must resume.

## Next 5 actions

1. Telescope `chart_1778353216690_action_1` into “Session-closure intake writes structured COAIA narrative memory.”
2. Telescope `chart_1778353216690_action_3` into “Narrative beats capture implementation traces and orientation shifts.”
3. Add a current-reality observation linking the Asterion prototype types (`Tension`, `ActionStep`, `NarrativeBeat`, `Project`, `AsterionEvent`) to the canonical JSONL chart schema.
4. Create a rispec or adapter note for mapping COAIA JSONL + `metadata.github` into Asterion runtime projection helpers.
5. Open issue-backed work in `jgwill/coaia-agent` only after the telescoped subcharts name exact ownership; route visualizer/schema requirements to `jgwill/coaia-visualizer` or `avadisabelle/coaia-narrative` only when the chart proves they belong there.

## Container rebuild/restart prerequisites

Before container rebuild or runtime restart:

- Preserve `/workspace/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl` and `.coaia/drop/` artifacts.
- Preserve active Hermes config mounted as `/opt/data/config.yaml` (`/home/mia/.coaia-agent/config.yaml` on host).
- Ensure MCP config still defines `coaia-agent-chart` using `npx -y coaia-narrative@0.13.0 --memory-path /workspace/coaia-agent/.coaia/narrative/coaia-agent-memory.jsonl`.
- After restart, run `/reload-mcp` or start a fresh Hermes session before expecting chart tools.
- For visual observation, restart `/workspace/coaia-agent/.coaia/narrative/start-visualizer.sh` and expose/use port `4422`.
- If using the Asterion prototype, provide `DATABASE_URL`, Upstash Redis env, Node/pnpm dependencies, and Next.js port `3000` without exposing GitHub tokens to public UI containers.
- Keep writes scoped to `/workspace/coaia-agent`; never use `/src/Miadi` for this lane.
