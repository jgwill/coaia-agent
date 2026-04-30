# RISPEC: Accountability and Responsibility — coaia-agent

> Accountability is answering for outcomes. Responsibility is the domain of action. This spec adapts the cross-cutting COAIA governance pattern for coaia-agent's position as a downstream consumer and unentitled governance actor.

**Version**: 0.1.0
**Date**: 2026-04-29
**Status**: Draft
**Lane**: NORTH N3 | **Session UUID**: 2604291305-coaia-agent-rispecs
**Model**: claude-sonnet-4.6 (approved fallback — claude-opus-4.6 not available in environment)
**Depends on**: `KINSHIP.md`, `medicine-wheel-governance.spec.md`, `contradictions.md`
**Pattern source**: coaia-pde, coaia-planning, coaia-visualizer, coaia-narrative all carry equivalent `accountability-responsibility[*].rispec.md` — this is the coaia-agent instantiation

---

## Current Reality

- coaia-agent is a Hermes Agent fork with no COAIA governance integration
- Accountability and responsibility boundaries between coaia-agent, its sibling repos, Veritas, and Medicine Wheel are implicit and undocumented
- Human authority boundaries (OCAP, sacred path, MMOT bootstrap paradox) exist across multiple specs but have not been consolidated into a single authority ledger for this repo
- The cross-cutting pattern (`accountability-responsibility.rispec.md`) exists in coaia-pde, coaia-planning, coaia-visualizer, and coaia-narrative; coaia-agent has no equivalent

## Desired Outcome

Every implementor, reviewer, and future agent session can answer three questions about coaia-agent's governance posture by reading this one file:
1. What is coaia-agent accountable *for* (outcomes it must answer for)?
2. What is coaia-agent responsible *over* (domains of action it controls)?
3. What is coaia-agent explicitly **not** accountable or responsible for (human-authority boundaries)?

---

## Accountability Ledger

Accountability = "I will answer for this outcome." coaia-agent's accountabilities:

| Accountability | To Whom | Evidence of Accountability |
|---|---|---|
| Surfacing governance warnings accurately when ceremony-protocol detects protected paths | Human operator and named governance authorities (elder, firekeeper, steward) | `check_path_before_write` runs before all file-write tool calls when governance is enabled |
| Passing OcapFlags through all data operations without modification | Data subjects (consent holders) and coaia-narrative schema authority | No tool handler strips, overrides, or reinterprets OcapFlags |
| Enforcing element-origin invariant on Veritas companions | Veritas steward and coaia-narrative rispec authority | `veritas_generate_model` call uses only STC action steps as elements |
| Respecting the bootstrap paradox rule for Veritas seed extraction | PDE steward (Guillaume / jgwill) | Evaluation results carry `demonstration: true` until `min_eval_cycles_for_seed` cycles complete |
| Not self-authorizing writes to `restricted` or `sacred` paths | Medicine Wheel governance authorities | `WriteDecision.HALT_AWAIT_AUTHORITY` is never overridden by the agent itself |
| Producing STC JSONL compatible with coaia-narrative schema | coaia-narrative (schema authority) | JSONL output includes `type` discriminator and follows Entity/Relation format |

---

## Responsibility Domains

Responsibility = "I act within this domain." coaia-agent's domains of action:

| Domain | What coaia-agent controls | Boundary |
|---|---|---|
| Tool registry (`tools/`, `toolsets.py`) | Registering COAIA toolsets with `check_fn` guards, `requires_env` declarations | Cannot modify Hermes core toolsets |
| Profile isolation (`HERMES_HOME`) | Setting the profile root for COAIA-isolated config, keys, sessions | Does not control the upstream `~/.hermes` default profile |
| Config loading | Reading `governance.*`, `veritas.*`, `toolsets.*` from config.yaml | Cannot override env vars set by the operator |
| Session lifecycle | Calling ceremony annotation at phase transitions when Tier 1 is enabled | Cannot advance ceremony phase without human-authored intent |
| MMOT evaluation invocation | Calling `coaia_mmot_evaluate` with `use_veritas` flag | Cannot initiate MMOT autonomously; evaluation is invoked by human operator or orchestrated session |
| Governance warning surface | Formatting and emitting warnings from `ceremony-protocol` | Cannot dismiss, suppress, or escalate warnings without operator action |

---

## Human Authority Boundaries (Non-Automatable)

These boundaries are explicit and must not be automated away in implementation:

| Boundary | Why non-automatable | Spec reference |
|---|---|---|
| Consent for data forwarding to Veritas or MCP | Consent is a living relational obligation; the agent cannot grant itself consent for forwarding data that belongs to another | `medicine-wheel-governance.spec.md` Tier 2 |
| Sacred path write authorization | Named authorities (elder, firekeeper, steward) hold path authority; the agent is unentitled | `medicine-wheel-governance.spec.md` Tier 3 |
| Veritas companion model creation decision | Creating a companion model against a human-owned STC requires explicit operator opt-in | `veritas-mmot-companion.spec.md` Activation Contract |
| Bootstrap paradox threshold (`min_eval_cycles_for_seed`) | The minimum cycle count before Veritas results seed the next PDE is a human decision (see C5 in `contradictions.md`) | `veritas-mmot-companion.spec.md` Bootstrap Paradox Rule |
| MMOT bootstrap presentation to human | `mmot_generation.spec.md` step 5 is non-automatable: human reviews, provides feedback, or accepts | `veritas-mmot-companion.spec.md` Phase 2 |
| Withdrawal cascade resolution | When `withdrawn` consent triggers cascade effects, human must explicitly decide for each affected relation | `medicine-wheel-governance.spec.md` Tier 2 |
| Direction casing normalization decision | The three-form casing inconsistency (C1) must not be resolved unilaterally | `contradictions.md` C1 |

---

## Relation to Sibling Accountability Patterns

| Sibling repo | Accountability emphasis | Difference from coaia-agent |
|---|---|---|
| `coaia-pde` | PDE → STC transformation fidelity; STC mapper accuracy | coaia-pde is a library/CLI; coaia-agent is a conversation-loop runtime with governance hooks |
| `coaia-planning` | JSONL output schema compatibility; plan-to-STC transformation integrity | coaia-planning is a plan transformer; coaia-agent is a session gateway |
| `coaia-visualizer` | Read-only fidelity; chart rendering accuracy; network API contracts | coaia-visualizer is UI; coaia-agent is a write-capable agent with consent obligations |
| `coaia-narrative` | Schema authority; MMOT evaluation self-containment | coaia-narrative is the schema owner; coaia-agent is a schema consumer |

coaia-agent's distinctive accountability is the **governance posture**: it is the only COAIA component that operates in a live agentic session with file-write capability and external tool forwarding — making the OCAP, sacred-path, and bootstrap-paradox rules most operationally significant here.

---

## Acceptance

This rispec is fulfilled when:

- [ ] Each accountability in the ledger has a corresponding test or audit step in the implementation session
- [ ] Each human authority boundary is documented as a non-automatable step in the `app.spec.md` workflow sections
- [ ] The Responsibility Domains table is cross-referenced in `coaia-agent/README.md` so new contributors know where the action boundaries are
- [ ] The pattern (accountability ledger + responsibility domains + non-automatable boundaries) is consistently applied in this repo's sibling specs
