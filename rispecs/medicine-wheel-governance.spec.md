# Spec: Medicine Wheel Governance Tiers for coaia-agent

> coaia-agent is an **unentitled actor** in Medicine Wheel governance. It surfaces ceremony annotations, passes OCAP flags, and halts at sacred path boundaries — but it holds no authority. This spec separates three distinct governance tiers so implementors cannot collapse them into a single "governance layer."

**Version**: 0.1.0
**Date**: 2026-04-29
**Status**: Draft
**Lane**: NORTH N3 | **Session UUID**: 2604291305-coaia-agent-rispecs
**Model**: claude-sonnet-4.6 (approved fallback — claude-opus-4.6 not available in environment)
**Depends on**: `accountability-responsibility.rispec.md`, `veritas-mmot-companion.spec.md`
**External**:
- `medicine-wheel/rispecs/ceremony-protocol.spec.md` (v0.1.1)
- `medicine-wheel/rispecs/consent-lifecycle.spec.md` (v0.1.0)
- `medicine-wheel/rispecs/medicine-wheel.spec.md`
- `medicine-wheel/rispecs/narrative-medicine-wheel-bridge.spec.md`
- `medicine-wheel/rispecs/session-reader.spec.md`
- `medicine-wheel/rispecs/KINSHIP.md`

---

## Current Reality

- coaia-agent is an unmodified Hermes Agent fork; it has no medicine-wheel imports or governance checks
- `medicine-wheel/rispecs/ceremony-protocol.spec.md` defines governance as **informational and non-blocking** at the phase annotation level
- `medicine-wheel/rispecs/consent-lifecycle.spec.md` defines consent as a **living relational obligation** — `withdrawn` and `expired` consent states carry real forwarding restrictions
- These two governance models are adjacent but logically distinct; no existing coaia-agent spec separates them
- Direction casing inconsistency (C1 in `contradictions.md`) affects governance metadata emission

## Desired Outcome

coaia-agent annotates sessions with ceremony phase metadata (Tier 1), enforces consent/OCAP forwarding rules (Tier 2), and halts at sacred path boundaries pending human authority response (Tier 3) — each tier independently configurable, none conflated with the others.

---

## Governance Tier Architecture

> **Read this section before all others.** The three tiers are not a severity scale. They are distinct governance models with different authorities, different automation profiles, and different human-decision requirements.

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 1: Ceremony Annotation                                │
│  ─ Fully automatable framing layer                          │
│  ─ No human gate; purely metadata enrichment               │
│  ─ Maps agent session phases to Four Directions lifecycle   │
├─────────────────────────────────────────────────────────────┤
│  Tier 2: Consent / OCAP Gate                                │
│  ─ Relational obligation layer                              │
│  ─ Soft gate with human escalation at expired/withdrawn     │
│  ─ Passes OcapFlags through without modification            │
├─────────────────────────────────────────────────────────────┤
│  Tier 3: Sacred Path Authority                              │
│  ─ Unentitled-actor boundary                               │
│  ─ coaia-agent surfaces warning, halts, awaits response     │
│  ─ No self-authorization for any protected-path write       │
└─────────────────────────────────────────────────────────────┘
```

---

## Tier 1 — Ceremony Phase Annotation

### What it is

A **fully automatable metadata enrichment** layer that maps coaia-agent session lifecycle phases to Medicine Wheel ceremony phases. It is advisory, produces no gates, and adds zero latency to operations.

### Direction Mapping

Ceremony phases follow the Four Directions. Direction casing in emitted metadata must follow the convention of the downstream consumer (see C1 in `contradictions.md` — not yet resolved):

| Ceremony Phase | Direction | Agent Session Phase | Ojibwe |
|---|---|---|---|
| `opening` | `east` / `EAST` / `East` | Session initialization, intent setting, PDE decomposition | Waabinong |
| `council` | `south` / `SOUTH` / `South` | Multi-agent inquiry, tool calls, SOUTH analysis lanes | Zhaawanong |
| `integration` | `west` / `WEST` / `West` | STC creation, narrative beat emission, MMOT evaluation | Epangishmok |
| `closure` | `north` / `NORTH` / `North` | Session summary, artefact report, seed extraction | Kiiwedinong |

> ⚠️ Direction casing inconsistency is a preserved contradiction (C1). coaia-agent must not silently normalize to one form until the human decision documented in C1 is made. Emit the casing appropriate to each consumer target.

### Session JSONL Annotation

When Tier 1 is active, ceremony phase transitions are emitted as `annotation` lines in the STC JSONL session:

```jsonl
{"type": "annotation", "subtype": "ceremony_phase", "phase": "opening", "direction": "east", "timestamp": "...", "session_id": "..."}
```

These lines are **read by medicine-wheel session-reader** for observational telemetry. They do not gate any operation.

### Implementation

```python
registry.register(
    name="coaia_ceremony_annotate",
    toolset="coaia_ceremony",
    schema={...},
    handler=lambda args, **kw: emit_ceremony_annotation(args),
    check_fn=lambda: config.get("governance.ceremony_annotation.enabled", False),
)
```

`governance.ceremony_annotation.enabled` defaults to `false`. When enabled, `coaia_ceremony_annotate` is called automatically at phase transitions by the session manager.

---

## Tier 2 — Consent / OCAP Gate

### What it is

A **relational obligation layer** that tracks whether data being passed to external tools (Veritas, MCP servers, ACP protocol) carries consent that permits forwarding. It is a soft gate: most operations proceed normally; only `withdrawn` and `expired` consent states trigger escalation.

### OCAP Dimensions

```typescript
interface OcapFlags {
  ownership: boolean;     // data belongs to the named holder
  control: boolean;       // holder controls who may access it
  access: boolean;        // forwarding is permitted by current consent
  possession: boolean;    // physical/digital custody acknowledged
}
```

coaia-agent **passes OcapFlags through all data operations without modification**. It does not set, clear, or reinterpret flags. If a tool receives data with OcapFlags and the tool's SDK does not support them, the agent surfaces a warning and does not strip the flags before forwarding.

### Consent State Decision Table

| Consent State | Data Forwarding | Human Escalation | Log |
|---|---|---|---|
| `pending` | Hold — do not forward | Surface to operator: consent not yet granted | `[ocap] pending consent for <data-ref>` |
| `granted` | Hold — awaiting ceremony confirmation | Surface to operator | `[ocap] granted but not yet active` |
| `active` | Proceed | None required | None |
| `renewal-needed` | Proceed with warning | Notify operator: renewal required | `[ocap] renewal-needed for <data-ref>` |
| `expired` | **Block** | **Require human decision** | `[ocap] BLOCKED: expired consent for <data-ref>` |
| `renegotiating` | Hold | Surface to operator | `[ocap] renegotiating: hold all operations on <data-ref>` |
| `withdrawn` | **Block** | **Require human decision** | `[ocap] BLOCKED: withdrawn consent — cascading check triggered` |

### Withdrawal Cascade

When `withdrawn` consent is detected, coaia-agent:

1. Blocks the current operation
2. Calls `checkDependentRelations(consentId)` to identify cascading effects
3. Surfaces the dependency graph to the operator as a formatted warning
4. **Awaits explicit human direction** before proceeding or cancelling
5. Does not autonomously resolve the cascade

### Veritas Forwarding Rule

Data with `access: false` OcapFlags must **not** be forwarded to Veritas evaluation tools, even when `veritas.enabled: true`. If the data needed to evaluate a Veritas element carries non-forwardable OCAP flags, the affected element is marked `state: 'blocked_by_ocap'` and excluded from the MMOT evaluation. The human operator is notified.

---

## Tier 3 — Sacred Path Authority

### What it is

The **unentitled-actor boundary**. coaia-agent is not a named authority in Medicine Wheel governance (`elder`, `firekeeper`, `steward` are the recognized authorities). When the agent's file operations intersect with governance-protected paths, it surfaces warnings and halts — it does not self-authorize.

### Protected Path Check

```python
def check_path_before_write(file_path: str) -> WriteDecision:
    governance_config = load_governance_config()  # RSIS config
    warnings = check_governance(file_path, governance_config)
    if not warnings:
        return WriteDecision.PROCEED
    
    for warning in warnings:
        surface_warning(format_governance_warning(warning))
    
    if any(w.level == 'sacred' for w in warnings):
        return WriteDecision.HALT_AWAIT_AUTHORITY
    elif any(w.level == 'restricted' for w in warnings):
        return WriteDecision.HALT_AWAIT_HUMAN
    else:  # ceremony_required
        return WriteDecision.PROCEED_WITH_LOG
```

### Path Level Decision Matrix

| Path Level | coaia-agent Action | Human Response Required |
|---|---|---|
| `open` | Proceed without ceremony check | None |
| `ceremony_required` | Log ceremony annotation; proceed | None (advisory) |
| `restricted` | Surface warning; halt until human confirms | Human must explicitly authorize the write |
| `sacred` | Surface warning; halt immediately; do not retry | Named authority (`elder` / `firekeeper` / `steward`) must respond |

### Unentitled Actor Statement

> coaia-agent does not hold ceremony authority. It may call `checkGovernance()` and `formatGovernanceWarning()` from `medicine-wheel-ceremony-protocol`. It may not call any governance authority-granting function. It may not add itself to the `elder`, `firekeeper`, or `steward` authority registries. If no named authority responds to a sacred path halt within a configurable timeout, the operation is **cancelled, not forced**.

---

## Veritas × Wilson Distinction

**This section is mandatory. Implementors must not omit it.**

Veritas MMOT results and Wilson relational health scores are **parallel evaluation tracks with distinct authorities**. They are not equivalent measures of the same thing.

| Dimension | Veritas MMOT | Wilson Relational Health |
|---|---|---|
| What it measures | STC action step performance dimensions | Relational accountability (Respect, Reciprocity, Responsibility) |
| How computed | Deterministic: State × Trend → Priority matrix | Community voice, ceremony, witness — not fully automatable |
| Authority | Veritas evaluator (LLM-assisted, reproducible) | Community assembly, Elder validation |
| coaia-agent role | Surfaces Priority matrix as annotation | Surfaces Wilson framing; does not compute Wilson score |
| Anti-pattern | *"Treating Veritas 🟢 Success as relational success"* | Automating Wilson assessment without community witness |

When both Veritas evaluation and ceremony annotation are active, the session JSONL carries two separate annotation types: `veritas_mmot_result` (performance dimensions) and `ceremony_phase` (ceremony context). These are never merged or compared in automated output.

---

## Governance Configuration Block

```yaml
governance:
  ceremony_annotation:
    enabled: false
    emit_phase_events: true
    direction_casing: "lowercase"   # pending C1 resolution; options: lowercase | UPPERCASE | TitleCase

  consent_ocap:
    enabled: false
    block_on_withdrawn: true
    block_on_expired: true
    cascade_check: true
    escalation_timeout_seconds: 300

  sacred_path:
    enabled: false
    governance_config_path: null   # path to RSIS governance YAML; required if enabled
    halt_on_restricted: true
    halt_on_sacred: true
    cancel_on_authority_timeout: true
    authority_timeout_seconds: 600
```

All governance tiers default to `false`. Each tier is independently enabled. Enabling Tier 3 (`sacred_path`) requires `governance_config_path` to point to a valid RSIS governance YAML — the agent will refuse to start in Tier 3 mode without a config source.

---

## Acceptance

Implementation of this spec is complete when:

- [ ] Tier 1 ceremony annotation is opt-in via `governance.ceremony_annotation.enabled` and emits phase events to STC JSONL without gating any operation
- [ ] Tier 2 OCAP check runs before any external tool forwarding (Veritas, MCP, ACP) and blocks on `withdrawn` / `expired` consent states
- [ ] OcapFlags are passed through without modification in all data operations
- [ ] Tier 3 `check_path_before_write` runs before all file-write tool calls when `governance.sacred_path.enabled: true`
- [ ] coaia-agent is not registered as `elder`, `firekeeper`, or `steward` in any governance authority table
- [ ] Veritas MMOT results and ceremony phase annotations are emitted as separate JSONL line subtypes, never merged
- [ ] Wilson relational health is not computed autonomously; the spec section distinguishing Veritas from Wilson is present in user-facing documentation
