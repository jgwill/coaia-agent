# GitHub Project Runtime Memory Consumption — RISE Specification

> How `coaia-agent` should consume the newly released `coaia-narrative` and `coaia-visualizer` GitHub runtime-memory surfaces without introducing a competing metadata shape.

**Version**: 1.0.0
**Document ID**: github-project-runtime-memory-consumption-v1
**Last Updated**: 2026-05-09
**Status**: Draft (spec-only)
**Cross-references**:
- [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md) — package roles and adapter responsibilities
- [`visualizer-planning-narrative-flow.spec.md`](./visualizer-planning-narrative-flow.spec.md) — JSONL artifact flow and visualizer readiness
- `coaia-narrative/rispecs/coaia-github/github-project-runtime-memory-schema-bridge.spec.md` — additive narrative-side schema bridge
- `coaia-visualizer/rispecs/github-project-runtime-memory-integration.spec.md` — additive visualizer rendering plan
- `avadisabelle/coaia-narrative#34` — narrative implementation/release issue
- `jgwill/coaia-visualizer#18` — visualizer implementation/release issue
- `jgwill/coaia-agent#18` — runtime/visualizer relationship context

---

## Desired Outcome

A `coaia-agent` session can write structural-tension-chart JSONL that:
1. remains valid for existing readers,
2. uses canonical `metadata.github` provenance rather than inventing a rival field family,
3. can be projected into GitHub Project custom fields,
4. can be rendered by `coaia-visualizer@1.6.0`, and
5. leaves clear accountability about which runtime wrote or synced the artifact.

---

## Structural Tension

**Current Reality**
- `coaia-agent` rispecs already describe source provenance, direction normalization, PDE/session flow, and visualizer readiness.
- Prior exploratory work used legacy aliases such as `metadata.sync_target` and `metadata.github_ref`.
- Live GitHub Project experiments already rely on a specific custom-field family, including:
  - `goal`
  - `current_reality`
  - `observations`
  - `question`
  - `Status`
  - `phase`
  - `session_id`
  - `four_dir_east`
  - `four_dir_south`
  - `four_dir_west`
  - `four_dir_north`
  - `relational_assessed`
  - `relational_principles`
- Without an explicit runtime contract, `coaia-agent` could accidentally emit a third metadata shape that neither released package expects.

**Desired Outcome**
- `coaia-agent` treats GitHub Project state as projected runtime memory.
- `coaia-agent` emits canonical `metadata.github` first, while dual-reading legacy aliases for migration.
- `coaia-agent` is accountable for when a chart is synced, diverged, project-only, or chart-only.

---

## 1. Runtime Boundary Decision

`coaia-agent` does not own GitHub Project authority directly.

It owns:
- deciding when a session/chart/action should carry GitHub provenance,
- writing canonical `metadata.github` into JSONL artifacts,
- preserving source/runtime accountability in `metadata.source`,
- asking a GitHub-facing integration surface to sync or reconcile fields.

It does not own:
- inventing a separate visualizer-only metadata block,
- replacing `coaia-narrative` as schema authority,
- treating GitHub Project field values as the sole source of truth.

This keeps the existing package boundary intact:
- `coaia-narrative` = schema authority and projection helpers
- `coaia-visualizer` = rendering/inspection surface
- `coaia-agent` = runtime writer/orchestrator
- GitHub integration surface (`coaia-github` / equivalent) = sync transport

---

## 2. Canonical Metadata Shape

`coaia-agent` should write this additive shape when GitHub runtime-memory linkage exists:

```typescript
metadata: {
  source: {
    system: 'coaia-agent',
    toolName?: string,
    sessionId?: string,
    createdAt?: string,
    version?: string,
  },
  github: {
    issue?: {
      owner: string,
      repo: string,
      number: number,
      nodeId?: string,
      url?: string,
    },
    projectItem?: {
      projectOwner: string,
      projectNumber: number,
      projectTitle?: string,
      itemId: string,
      url?: string,
    },
    projectItems?: [...],
    syncState?: 'synced' | 'diverged' | 'conflict' | 'project-only' | 'chart-only',
    lastSyncedAt?: string,
    fieldHash?: string,
    authoritativeOnLastSync?: 'jsonl' | 'project',
  }
}
```

Migration rule:
- read `metadata.github`, `metadata.sync_target`, and `metadata.github_ref`
- write `metadata.github`
- never create new records that only use legacy aliases

---

## 3. Project Field Contract

When `coaia-agent` prepares a chart for GitHub Project synchronization, the runtime must assume the following field family is the minimum contract:

| Field | Meaning | Expected source inside chart memory |
|---|---|---|
| `goal` | desired outcome / aim | desired outcome entity or chart summary |
| `current_reality` | present tension | current reality entity |
| `observations` | chart observations snapshot | chart observations |
| `question` | framing question / inquiry prompt | chart narrative/question source |
| `Status` | workflow status | projected from phase + completion state |
| `phase` | lifecycle phase | chart metadata |
| `session_id` | runtime or sync session trace | source/session metadata |
| `four_dir_east` | intention | fourDirections east |
| `four_dir_south` | emotion / relation | fourDirections south |
| `four_dir_west` | introspection | fourDirections west |
| `four_dir_north` | vision | fourDirections north |
| `relational_assessed` | whether relational review occurred | relational alignment metadata |
| `relational_principles` | governing principles | relational alignment metadata |

Constraint from live experiments:
- these names must be preserved exactly unless a future schema migration is explicitly coordinated across runtime, narrative, visualizer, and GitHub Project templates.

---

## 4. Relation Contract for Visualizer Readiness

When `coaia-agent` wants charts to become visually accountable in the visualizer, it should prefer explicit bridge relations that the visualizer can surface:

- `synced_to_github`
- `linked_to_issue`
- `project_lens_of`

These may live either as direct `relationType` values or as semantic context in relation metadata, but runtime writers should prefer the explicit form whenever they control new writes.

Virtual GitHub mirror nodes such as `gh:owner/repo#123` are allowed when they clarify relation-graph context, but they are optional. The important contract is that bridge relations remain additive and do not replace existing STC relations.

---

## 5. Accountability Rules

After each GitHub sync attempt, `coaia-agent` should be able to answer:
- What issue is this chart linked to?
- Which project item(s) currently lens the chart?
- Which side was authoritative on the last sync?
- Was the chart synced, diverged, conflicted, project-only, or chart-only?
- Which session/tool/runtime version produced the current state?

Minimum accountability writeback:
- `metadata.github.syncState`
- `metadata.github.lastSyncedAt`
- `metadata.github.authoritativeOnLastSync`
- `metadata.source.system = 'coaia-agent'` with tool/session/version details where available

---

## 6. Non-Goals

This spec does not require `coaia-agent` to:
- mutate GitHub Projects directly from every runtime path,
- rewrite older JSONL files in bulk,
- treat visualizer badges as a substitute for real sync provenance,
- solve GitHub auth/distribution policy inside the runtime spec.

---

## 7. Initial Acceptance Criteria

- `coaia-agent` writes canonical `metadata.github` on new GitHub-linked chart artifacts.
- `coaia-agent` dual-reads legacy aliases without failing old sessions.
- runtime-generated chart artifacts can be projected to the required GitHub Project field family listed above.
- runtime-generated artifacts can be rendered by `coaia-visualizer@1.6.0` without additional schema invention.
- runtime logs or summaries can explain the last known GitHub sync/accountability state.

---

## 8. Immediate Follow-on Suggestion

Implementation work that follows this spec should be scoped as an additive adapter layer inside `coaia-agent`, not as a rewrite of chart semantics. The first thin slice should:
1. normalize incoming legacy aliases,
2. write canonical `metadata.github`,
3. expose a projection helper call/use-site for the required field family,
4. record sync accountability in session-close artifacts.
