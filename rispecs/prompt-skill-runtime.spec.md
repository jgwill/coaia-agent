# Prompt Skill Runtime — RISE Specification

> How coaia-agent's Hermes-derived runtime discovers, invokes, and records the lifecycle of prompt-bound skills — from context injection through provenance recording, plugin hooks, long review windows, and stable artifact contracts across backend changes.

**Version**: 1.0.0  
**Document ID**: prompt-skill-runtime-v1  
**Last Updated**: 2026-04-29  
**Status**: Draft (spec-only)  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Cross-references**:
- [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md) — lifecycle stages the runtime executes
- [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md) — package roles and adapters the runtime uses
- [`visualizer-planning-narrative-flow.spec.md`](./visualizer-planning-narrative-flow.spec.md) — downstream artifacts the runtime produces
- `mia-code/rispecs/pde.rispecs.md` — miaco PDE tree precedent (conceptual transfer)
- `mia-code/rispecs/stc.rispecs.md` — miaco STC conversion precedent (conceptual transfer)

---

## Desired Outcome

The coaia-agent runtime enables practitioners to invoke named prompt skills that carry full context awareness, emit provenance breadcrumbs, support long review windows between stages, and maintain a stable JSONL artifact contract regardless of which backend LLM or MCP server handles the decomposition. A team that did not attend the design session can implement any runtime component from this spec alone.

---

## Structural Tension

**Current Reality**  
coaia-agent is a fork of Hermes Agent with Hermes branding intact. No COAIA skill integration exists. No context injection protocol, lifecycle hook system, or provenance breadcrumb trail has been defined. The existing Hermes runtime provides agent orchestration, tool routing, and session management — but it treats every tool call as stateless. COAIA sessions are inherently stateful: a PDE decomposition must be available when its STC is created; an STC session must be open when narrative beats are appended.

**Desired Outcome**  
coaia-agent extends the Hermes runtime with a COAIA skill layer that:
1. Discovers prompt skills from a configurable registry
2. Injects session context (PDE UUID, STC session UUID, workdir, direction normalization) before invoking each skill
3. Records provenance at each skill boundary so the artifact trail is auditable
4. Respects long review windows without losing state
5. Exposes plugin hooks so optional packages (veritas, medicine-wheel) can participate without hard-wiring

---

## 1. Hermes Runtime Foundation

coaia-agent inherits the Hermes Agent architecture:

```
Hermes Runtime
├── AgentLoop                    ← turn-based conversation management
│   ├── ToolRouter               ← dispatches tool calls to handlers
│   ├── SessionStore             ← persists conversation state
│   └── PluginRegistry           ← loads optional plugins at startup
│
COAIA Skill Layer (new — this spec)
├── SkillRegistry                ← discovers and registers prompt skills
├── ContextInjector              ← enriches skill input with COAIA session context
├── ProvenanceRecorder           ← writes breadcrumb records on each skill invocation
├── LifecycleHooks               ← pre/post hooks for each lifecycle stage
└── ReviewWindowManager          ← pauses between stages for human review
```

The COAIA skill layer does not replace Hermes routing — it wraps it. Hermes `ToolRouter` dispatches to either a native Hermes tool handler or a COAIA skill handler, depending on the tool name.

---

## 2. Skill Definition Contract

### 2.1 Prompt Skill Interface

```typescript
interface PromptSkill {
  /** Unique skill identifier, e.g. 'pde-decompose', 'stc-import', 'plan-sync' */
  id: string;

  /** Human-readable name for logging and UI */
  name: string;

  /** Which lifecycle stage this skill belongs to */
  stage: 'decompose' | 'import-stc' | 'plan-sync' | 'narrative' | 'visualize' | 'close';

  /** Required packages for this skill (checked before invocation) */
  requires: PackageRef[];

  /** Optional packages this skill can use if available */
  optional?: PackageRef[];

  /** Whether this skill must wait for human review before proceeding */
  reviewWindowRequired: boolean;

  /** Execute the skill with injected context */
  execute(context: SkillContext): Promise<SkillResult>;
}

interface PackageRef {
  packageId: 'mcp-pde' | 'coaia-pde' | 'coaia-narrative' | 'coaia-visualizer' |
             'coaia-planning' | 'veritas' | 'medicine-wheel';
  minimumVersion?: string;
}

interface SkillContext {
  /** COAIA session state injected by ContextInjector */
  session: CoaiaSessionState;

  /** Raw tool call arguments from the user or orchestrator */
  args: Record<string, unknown>;

  /** Available package clients (populated by PackageConsumption adapter) */
  packages: AvailablePackages;

  /** Direction normalizer — use this for all direction values */
  normalizeDirection: (raw: string) => CanonicalDirection;
}

interface SkillResult {
  success: boolean;
  artifact?: ArtifactRef;     // What was produced
  provenance: ProvenanceRecord;
  nextStage?: string;          // Suggested next stage for the orchestrator
  reviewRequired: boolean;     // Whether a review window should be opened
  summary: string;             // Human-readable one-line summary
}
```

### 2.2 COAIA Session State

The `CoaiaSessionState` is the central context object that flows through every skill invocation:

```typescript
interface CoaiaSessionState {
  /** Session UUID for the coaia-agent run (not the PDE UUID, not the STC session UUID) */
  agentSessionId: string;

  /** Working directory where .pde/ and .coaia/ roots live */
  workdir: string;

  /** PDE decomposition UUID (set after Stage 1) */
  pdeUuid?: string;

  /** PDE folder name, e.g. "2604291317--4da3f9f5-..." (set after Stage 1) */
  pdeFolderName?: string;

  /** STC session UUID (set after Stage 2) */
  stcSessionUuid?: string;

  /** Master chart ID (set after Stage 2) */
  masterChartId?: string;

  /** Lifecycle stage the session is currently in */
  currentStage: LifecycleStage;

  /** Review windows that have been opened and closed */
  reviewWindows: ReviewWindow[];

  /** Provenance breadcrumb trail */
  provenance: ProvenanceRecord[];

  /** Active session status */
  status: 'initializing' | 'decomposing' | 'importing' | 'reviewing' |
          'narrative' | 'planning' | 'closing' | 'completed' | 'abandoned';
}

type LifecycleStage = 'decompose' | 'import-stc' | 'plan-sync' |
                      'narrative' | 'visualize' | 'close';
```

---

## 3. Context Injection Protocol

The `ContextInjector` runs before every skill `execute()` call. It enriches the raw tool call arguments with the current session state:

```
User/Orchestrator tool call
        │
        ▼
ContextInjector.inject(rawArgs, sessionState)
        │  merges:
        │    workdir → rawArgs.workdir (if not already set)
        │    pdeUuid → rawArgs.pde_id (if not already set and stage ≥ import-stc)
        │    stcSessionUuid → rawArgs.session_id (if not already set and stage ≥ narrative)
        │    direction normalizer → context.normalizeDirection
        ↓
Enriched SkillContext
        │
        ▼
SkillRegistry.execute(skill, context)
```

### 3.1 Injection Rules by Stage

| Stage | Fields Injected |
|-------|----------------|
| `decompose` | `workdir`, `agentSessionId` |
| `import-stc` | + `pdeUuid`, `pdeFolderName` |
| `plan-sync` | + `pdeUuid`, `stcSessionUuid` |
| `narrative` | + `pdeUuid`, `stcSessionUuid`, `masterChartId` |
| `visualize` | + `stcSessionUuid` (JSONL path) |
| `close` | + full session state for summary generation |

### 3.2 Preventing Double-Injection

If the user or orchestrator has already provided a context field (e.g., an explicit `pde_id`), the injector must not override it. Injection is additive, not overwriting.

---

## 4. Provenance Recording

Every skill invocation appends a `ProvenanceRecord` to `CoaiaSessionState.provenance`. This trail becomes the source for `session-summary.md` at close time.

```typescript
interface ProvenanceRecord {
  /** ISO-8601 timestamp */
  timestamp: string;

  /** Skill ID that produced this record */
  skillId: string;

  /** Lifecycle stage */
  stage: LifecycleStage;

  /** What was produced: artifact type and path/id */
  artifact?: ArtifactRef;

  /** Brief human-readable description */
  description: string;

  /** Whether a review window was opened after this step */
  reviewWindowOpened: boolean;

  /** Duration in milliseconds */
  durationMs: number;
}

interface ArtifactRef {
  type: 'pde-json' | 'pde-markdown' | 'stc-jsonl' | 'plan-jsonl' |
        'narrative-beat' | 'session-summary' | 'veritas-review';
  path: string;       // Relative to workdir
  id?: string;        // UUID, if applicable
}
```

### 4.1 Provenance Breadcrumb in JSONL

For every entity that coaia-agent creates directly (e.g., the session-summary `narrative_beat`), the provenance record is embedded in `metadata.source`:

```typescript
metadata: {
  source: {
    system: 'coaia-agent',
    sessionId: agentSessionId,
    toolName: 'close-session',
    createdAt: timestamp,
  }
}
```

For entities created by delegated packages (coaia-pde, coaia-narrative), the `source.system` reflects the delegating package — coaia-agent does not override it.

---

## 5. Lifecycle and Plugin Hooks

### 5.1 Hook Points

The runtime exposes lifecycle hooks at each stage transition and at each skill boundary:

```typescript
interface LifecycleHooks {
  // Stage-level hooks
  onStageBegin(stage: LifecycleStage, session: CoaiaSessionState): Promise<void>;
  onStageComplete(stage: LifecycleStage, result: SkillResult, session: CoaiaSessionState): Promise<void>;
  onStageError(stage: LifecycleStage, error: Error, session: CoaiaSessionState): Promise<void>;

  // Skill-level hooks (more granular)
  onSkillBegin(skill: PromptSkill, context: SkillContext): Promise<void>;
  onSkillComplete(skill: PromptSkill, result: SkillResult, context: SkillContext): Promise<void>;

  // Review window hooks
  onReviewWindowOpen(stage: LifecycleStage, session: CoaiaSessionState): Promise<void>;
  onReviewWindowClose(stage: LifecycleStage, session: CoaiaSessionState): Promise<ReviewDecision>;

  // Session hooks
  onSessionInit(session: CoaiaSessionState): Promise<void>;
  onSessionClose(session: CoaiaSessionState): Promise<void>;
}

type ReviewDecision = 'continue' | 'abort' | 'restart-stage';
```

### 5.2 Plugin Registration

Optional packages register their hooks at startup:

```typescript
// Example: medicine-wheel plugin registration
agentRuntime.pluginRegistry.register({
  packageId: 'medicine-wheel',
  hooks: {
    onStageBegin: async (stage, session) => {
      if (stage === 'decompose') {
        // Open ceremony context; record consent
      }
    },
    onSessionClose: async (session) => {
      // Close ceremony; record closing protocol
    }
  }
});

// Example: veritas plugin registration
agentRuntime.pluginRegistry.register({
  packageId: 'veritas',
  hooks: {
    onStageComplete: async (stage, result, session) => {
      if (stage === 'close' && result.success) {
        // Trigger Type 2 MMOT review
      }
    }
  }
});
```

### 5.3 Hook Execution Order

Hooks execute in registration order. A hook failure must log and continue — optional packages must not block the core lifecycle. Hook failures are recorded in `CoaiaSessionState.provenance` as error entries.

```
onStageBegin: [medicine-wheel hook, ...user hooks]
↓
skill.execute()
↓
onStageComplete: [...user hooks, veritas hook]
```

---

## 6. Long Review Windows

### 6.1 The Review Window Problem

A RISE session involves human review between lifecycle stages — often 15–90 minutes. The Hermes session context must survive this pause without losing PDE or STC state.

### 6.2 Session Persistence Contract

coaia-agent persists `CoaiaSessionState` to disk at every stage boundary:

```
.pde/<ts>--<pde-uuid>/
└── .coaia-agent-session.json   ← CoaiaSessionState snapshot (gzip optional)
```

This file is rewritten (not appended) at each stage boundary. It enables:
- `coaia-agent resume <agentSessionId>` — resume from last persisted stage
- Review windows that span beyond Hermes session TTL
- Crash recovery — restart from the last completed stage

### 6.3 Review Window State Machine

```
Stage N completes
      │
      ▼
ReviewWindowManager.open(stage, session)
      │
      ├── Writes stage-N summary to stdout
      ├── Calls onReviewWindowOpen() hooks
      ├── Persists CoaiaSessionState to disk
      └── WAITS (blocking or async, depending on runtime mode)
                │
                │ Human reviews; decides:
                │
                ├─ 'continue' → ReviewWindowManager.close() → Stage N+1
                ├─ 'abort'    → onSessionClose(); status='abandoned'
                └─ 'restart-stage' → re-execute Stage N with same session state
```

### 6.4 Non-Interactive Mode

When `COAIA_REVIEW_WINDOWS=false` (default in automation/CI), review windows are skipped and execution proceeds automatically. The `reviewWindowOpened: false` flag is recorded in each `ProvenanceRecord`.

---

## 7. Stable Artifact Contract Across Backend Changes

### 7.1 The Stability Problem

coaia-agent may use different LLM backends (GPT-5.x, Claude, Gemini) or different MCP server versions across sessions. The artifact contract — what JSONL schema and file paths downstream packages expect — must not change when the backend changes.

### 7.2 Stability Guarantees

| Contract Layer | Stable Across | Mechanism |
|----------------|---------------|-----------|
| JSONL entity/relation schema | Any backend change | Schema owned by `coaia-narrative/src/types.ts`; coaia-agent does not extend it without adopting schema-evolution spec |
| `.pde/<ts>--<uuid>/` folder structure | Any backend change | mcp-pde storage.ts owns this; coaia-agent reads via UUID lookup only |
| `pde_session` header fields | Any backend change | Defined in this spec §2 of lifecycle spec; coaia-agent writes all required fields regardless of backend |
| Direction casing | Any backend change | `normalizeDirection()` adapter applied before any write |
| `metadata.source.system` | Any backend change | Always written; value is `'coaia-agent'` for coaia-agent-generated, or delegating package system string |

### 7.3 What Is NOT Stable (Explicitly Documented)

| Element | Not Stable Because | Mitigation |
|---------|-------------------|------------|
| `fourDirections` key names | Semantically mismatched with Medicine Wheel roles; deferred to human authority | Document as known contradiction; preserve in v1 |
| LLM-extracted content within DecompositionResult | LLM outputs vary | Test against schema shape, not content |
| Confidence scores | Model-dependent | Treat as heuristics, not hard thresholds |

---

## 8. Skill Registry — Core Skills

These skills are the coaia-agent v1 core. Each must be implemented before the first useful demo (see `install-and-first-demo.spec.md`).

| Skill ID | Stage | Required Packages | Review Window |
|----------|-------|------------------|---------------|
| `pde-decompose` | `decompose` | mcp-pde | Yes (before Stage 2) |
| `stc-import` | `import-stc` | coaia-pde, coaia-narrative | No |
| `stc-visualize` | `visualize` | coaia-visualizer (optional) | No |
| `plan-sync` | `plan-sync` | coaia-planning (optional) | No |
| `narrative-append` | `narrative` | coaia-narrative | No |
| `session-close` | `close` | coaia-agent (self) | Yes (before close) |

### 8.1 Skill Sequence Diagram

```
[pde-decompose]
       │ reviewWindowRequired=true
       │ (human reviews DecompositionResult before STC creation)
       ▼
[stc-import]
       │
       ├──▶ [stc-visualize]   (if coaia-visualizer available)
       │
       ├──▶ [plan-sync]       (if coaia-planning available)
       │
       └──▶ [narrative-append] (if practitioner adds narrative beats)
                │
                ▼
        [session-close]
               │ reviewWindowRequired=true
               │ (human reviews session summary before close)
               ▼
        session-summary.md written
```

---

## 9. Acceptance Criteria

- [ ] Every skill invocation populates `SkillResult.provenance` with a valid `ProvenanceRecord`
- [ ] `ContextInjector` injects `workdir`, `pdeUuid`, and `stcSessionUuid` based on current stage without overriding user-provided values
- [ ] `normalizeDirection()` is called before any direction value is written to an entity's metadata
- [ ] `CoaiaSessionState` is serialized to `.pde/<ts>--<uuid>/.coaia-agent-session.json` at each stage boundary
- [ ] A crashed session can be resumed via `coaia-agent resume <agentSessionId>` from the last persisted stage
- [ ] Plugin hooks registered by optional packages (veritas, medicine-wheel) run in registration order; a hook failure does not abort the stage
- [ ] Skill failures that meet the fallback conditions defined in `coaia-package-consumption.spec.md §4` produce a graceful log and continue (or halt appropriately)
- [ ] The JSONL artifact produced by any core skill is parseable by `coaia-visualizer/lib/jsonl-parser.ts` 4-pass algorithm
- [ ] Skill execution in `COAIA_REVIEW_WINDOWS=false` mode completes without any wait prompts
