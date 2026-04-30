# RISPEC: Veritas MMOT Companion Pattern for coaia-agent

> When an STC is created in a coaia-agent session, a Veritas Type 2 Performance Review model may be born alongside it — if and only if the operator has opted in. They are companions through the full STC lifecycle. This spec makes the companion relationship rich and fully specifiable while keeping the dependency activation explicitly opt-in and config-gated.

**Version**: 0.1.0
**Date**: 2026-04-29
**Status**: Draft
**Lane**: NORTH N3 | **Session UUID**: 2604291305-coaia-agent-rispecs
**Model**: claude-sonnet-4.6 (approved fallback — claude-opus-4.6 not available in environment)
**Depends on**: `accountability-responsibility.rispec.md`, `medicine-wheel-governance.spec.md`
**External**:
- `coaia-narrative/rispecs/stc-veritas-companion.rispec.md` (primary source)
- `veritas/rispecs/performance_review_model.spec.md`
- `veritas/rispecs/mcp_server.spec.md`
- `veritas/rispecs/mmot_generation.spec.md`
- `coaia-narrative/rispecs/structural_tension_chart_creation.spec.md`
- `coaia-narrative/rispecs/mmot_evaluation_loop.spec.md`

---

## Current Reality

- coaia-agent is an unmodified fork of Hermes Agent 0.11.0 with no COAIA integration
- No connection exists between STC creation (via coaia-pde or coaia-narrative MCP) and Veritas model creation
- `coaia-narrative/rispecs/stc-veritas-companion.rispec.md` specifies the companion relationship in detail but is not wired to any agent runtime
- Veritas has MCP tools (`veritas_generate_model`, `veritas_mmot_evaluate`, `veritas_get_model`) and a CLI, including an offline-capable local evaluation path
- The Hermes tool registry allows `check_fn` and `requires_env` guards — the registration hook for opt-in Veritas toolsets exists

## Desired Outcome

A coaia-agent session can optionally create a Veritas companion model alongside any STC, evaluate MMOT state at session midpoints and completion, and feed Critical/Warning element seeds back into the next PDE cycle. All of this is **invisible unless the operator sets `veritas.enabled: true`** — the STC chain works identically without Veritas.

---

## Activation Contract (Read This First)

> **Activation always precedes companion richness. If you are implementing this spec, the activation contract governs. Ignore it and the companion relationship becomes de facto required.**

### Config Block

```json
{
  "veritas": {
    "enabled": false,
    "auto_create_companion": false,
    "mmot_use_veritas": false,
    "local_eval_fallback": true,
    "api_base": "https://veritas.sanctuaireagentique.com",
    "min_eval_cycles_for_seed": 2
  }
}
```

All fields default to `false` / disabled. No coaia-agent default configuration ever sets `enabled: true` silently.

### Environment Guards

| Config field | Required env var | Behavior when absent |
|---|---|---|
| `veritas.enabled: true` | `VERITAS_API_KEY` | CRUD tools unavailable; local eval path only |
| `veritas.local_eval_fallback: true` | none | Offline evaluation via `veritas mmot evaluate --file` |
| `veritas.auto_create_companion: true` | `VERITAS_API_KEY` | Falls back to skipping companion creation; logs warning |

Tool registration uses Hermes `check_fn`:

```python
registry.register(
    name="veritas_create_companion",
    toolset="veritas",
    schema={...},
    handler=...,
    check_fn=lambda: (
        config.get("veritas.enabled") and
        config.get("veritas.auto_create_companion") and
        bool(os.getenv("VERITAS_API_KEY"))
    ),
    requires_env=["VERITAS_API_KEY"],
)
```

The `veritas` toolset is never loaded unless `config.toolsets.veritas: true` is also set.

---

## The Companion Relationship

> *"When an STC is created, a Veritas Type 2 Performance Review model is born alongside it."* — coaia-narrative companion rispec
>
> In coaia-agent, this birth is conditional on the activation contract above.

### Phase 1: STC Creation Hook

When `coaia_create_stc` or `coaia_pde_import` produces a new STC chart, and `veritas.auto_create_companion: true` is active:

1. Extract STC action steps as Veritas model elements
2. Call `veritas_generate_model` with:
   - `model_name` = STC chart title or `desired_outcome.title`
   - `elements` = one entry per action step, with `acceptable_criteria` derived from desired-outcome context
   - `state = 'unevaluated'`, `trend = 'unevaluated'`
3. Store returned Veritas model ID in STC chart metadata as `veritasModelId`
4. Emit audit log entry: `"[veritas] companion model created: <model-id> for chart: <chart-id>"`

If companion creation fails (API unreachable, quota exceeded), the STC is created without a companion. The failure is logged but does not block STC creation. The operator may manually create the companion later using `veritas_generate_model`.

### Element Mapping

```
STC Action Step  →  Veritas Element
─────────────────────────────────────────────────────────────────
title            →  element.name
description      →  element.description (what achieving this looks like)
desired_outcome  →  element.acceptable_criteria (what "Acceptable" means)
status           →  element.state (pending → unevaluated)
```

**Element-origin invariant**: Elements originate exclusively from STC action steps. The companion creator does not add, remove, or modify elements independent of the STC. The evaluator cannot add elements at evaluation time. This invariant is checked at runtime: if `veritas_generate_model` returns a model with elements that do not map 1:1 to STC action steps, the companion is flagged for human review and not used as seed material.

### Phase 2: MMOT Evaluation Hook

The `coaia_mmot_evaluate` tool in coaia-agent extends the coaia-narrative evaluation pattern with an optional Veritas path:

```
coaia_mmot_evaluate({
  chartId: "stc-abc123",
  use_veritas: false   ← default; must match config.mmot_use_veritas
})
```

| `use_veritas` value | Behavior |
|---|---|
| `false` (default) | Self-contained DESIGN/EXECUTION assessment within coaia-narrative; no Veritas call |
| `true` | Calls `veritas_mmot_evaluate` on companion model; integrates State×Trend×Priority into narrative beat emission |
| `true` + no companion model | Falls back to `false` behavior; logs warning: *"veritas.mmot_use_veritas: true but no companion model found for chart"* |
| `true` + no API key + local_eval_fallback | Uses `veritas mmot evaluate --file <local-model.json>`; offline path |

#### Evaluation Cycle (Four Steps)

When `veritas_mmot_evaluate` is called, it runs:

1. **Acknowledge** — confirm element list matches current STC action steps (drift check)
2. **Analyze** — apply State × Trend → Priority matrix per element
3. **Plan** — extract Critical and Warning elements as candidate seeds
4. **Document** — return MMOT record with priority matrix, seed candidates, and evaluation metadata

The MMOT record is emitted as a narrative beat in the STC JSONL session.

### Phase 3: STC Completion Signal

When an STC reaches `status: completed`, if a companion model exists and `mmot_use_veritas: true`:

- A final `veritas_mmot_evaluate` call runs
- The result is marked `"final_record": true` in the companion model
- Critical and Warning elements are extracted as **seed signal** for the next PDE cycle — see [Bootstrap Paradox Rule](#bootstrap-paradox-rule)

---

## Priority Matrix (Veritas Type 2)

| State | Trend | Priority | coaia-agent behavior |
|---|---|---|---|
| ❌ Unacceptable | ⬇️ Declining | 🔴 Critical | Surfaces as high-priority seed for next PDE |
| ❌ Unacceptable | ➡️ Stable | 🟠 Important | Surfaces as seed candidate |
| ❌ Unacceptable | ⬆️ Improving | 🟡 Watch | Surfaces as monitoring note |
| ✅ Acceptable | ⬇️ Declining | 🟡 Prevent Regression | Surfaces as monitoring note |
| ✅ Acceptable | ➡️ Stable | 🟢 Maintain | No action required |
| ✅ Acceptable | ⬆️ Improving | 🟢 Success | Archived as evidence of advancement |

Priority scores annotate STC action step performance dimensions. They do **not** measure relational accountability (Wilson alignment). See [C4 in contradictions.md](./contradictions.md).

---

## Bootstrap Paradox Rule

> *"The first evaluation of any new Veritas model is demonstration, not trusted verdict."* — `mmot_generation.spec.md`

**Concrete rule for coaia-agent**:

1. The companion model created at STC inception has `evaluation_cycle_count: 0`
2. Each completed `veritas_mmot_evaluate` call increments `evaluation_cycle_count`
3. Evaluation results are marked `"demonstration": true` when `evaluation_cycle_count < min_eval_cycles_for_seed` (default: 2)
4. Seed extraction for the next PDE cycle is **blocked** when `demonstration: true`
5. The operator is shown a notice: *"Veritas result is demonstration-only (cycle N of min. 2). Not used as PDE seed."*

This rule applies to the STC-completion evaluation as well. If the STC completes before `min_eval_cycles_for_seed` have run, the final record carries `"demonstration": true` and is archived, not seeded.

The minimum cycle count (`min_eval_cycles_for_seed: 2`) is provisional — see [C5 in contradictions.md](./contradictions.md) for the human decision needed.

---

## Offline Fallback Path

When `VERITAS_API_KEY` is absent and `veritas.local_eval_fallback: true`:

```bash
# coaia-agent spawns as subprocess:
veritas mmot evaluate --file ~/.coaia-agent/veritas/<model-id>.json
```

The model is serialized to local JSON at companion creation time. The offline path supports full Acknowledge → Analyze → Plan → Document cycle using local LLM inference. Seed extraction is supported in offline mode but `"offline": true` is added to the result metadata.

Offline mode does not support `veritas_update_model`, `veritas_export_model`, or `veritas_get_schema` (NETWORK_TOOLS require API key).

---

## Anti-Patterns (from coaia-narrative companion rispec)

| Anti-Pattern | Why It Is Prohibited |
|---|---|
| Making Veritas required for STC creation | Breaks backward compatibility; violates opt-in contract; creates coupling that forces Veritas API key on all coaia-agent deployments |
| Letting the evaluator add elements at evaluation time | Violates element-origin invariant; breaks traceability from STC action steps |
| Treating Veritas 🟢 Success as relational success | Formal performance score ≠ Wilson relational health; collapses two distinct evaluation tracks |
| Seeding PDE from first evaluation cycle | Bootstrap paradox — first result is demonstration; seeding from it creates circular self-confirmation |
| Silently enabling Veritas in default config | Violates user agency; creates unexpected API key requirement; surprises operators with external calls |

---

## Acceptance

Implementation of this spec is complete when:

- [ ] `veritas` toolset is registered in Hermes registry, gated by `check_fn` verifying config and env
- [ ] `veritas.enabled: false` default is confirmed in the generated `coaia-agent` config template
- [ ] `coaia_create_stc` / `coaia_pde_import` supports optional companion creation, falling back gracefully
- [ ] `coaia_mmot_evaluate` accepts `use_veritas` flag, defaulting to `false`
- [ ] Bootstrap paradox rule is enforced: evaluation results carry `demonstration: true` until `evaluation_cycle_count >= min_eval_cycles_for_seed`
- [ ] Offline fallback path produces the same MMOT record shape as online path
- [ ] All four anti-patterns from the table above are tested as negative cases
