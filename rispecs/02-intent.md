# 02 — Intent: coaia-agent as Hermes-Derived COAIA Runtime

**Version**: 0.1.0  
**Status**: Draft  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Lane**: NORTH N1  
**Date**: 2026-04-29  
**Cross-references**: [`01-reverse-engineer.md`](./01-reverse-engineer.md), [`03-specify.md`](./03-specify.md), [`contradictions.md`](./contradictions.md)

---

## Desired Outcome

A practitioner opens `coaia-agent` with `HERMES_HOME=~/.coaia-agent` and immediately
has access to the COAIA RISE ceremony: prompt decomposition via mcp-pde, structural
tension chart creation in `.coaia/pde/`, visualization in coaia-visualizer, and an
optional session summary narrative. The entire flow — from prompt to loadable STC chart —
succeeds without editing a single Hermes core file.

The coaia-agent runtime embeds a **relational artifact lifecycle**: every session produces
a PDE folder artifact, an STC JSONL, and a provenance link from session to decomposition
to chart. A separate implementation team can run this ceremony, load artifacts into
coaia-visualizer, and hand off the session JSONL to coaia-narrative — without reading
source code.

The desired state is not a rebrand. It is a **working integration ceremony** that
makes COAIA creative orientation native to the Hermes conversation loop.

---

## Current Reality

- `coaia-agent/rispecs/` did not exist before this session. This pack is the first spec
  authored for this integration.
- `coaia-agent` is **Hermes 0.11.0**, branded throughout: `pyproject.toml`, `package.json`,
  CLI entry points, and documentation all declare `hermes-agent` from Nous Research.
- No COAIA-specific config paths, tools, skills, lifecycle plugins, or documentation
  exist in the repository.
- The COAIA artifact ecosystem (mcp-pde, coaia-pde, coaia-narrative, coaia-visualizer)
  is fully developed and operational, with independent rispecs packs. These repos are
  unaware of coaia-agent as a consuming runtime.
- The full prompt → PDE → STC → visualizer flow has been demonstrated in prior sessions
  using mcp-pde and coaia-pde independently, but not orchestrated through coaia-agent's
  conversation loop or lifecycle hooks.
- Three contradictions are confirmed and unresolved (see `contradictions.md`):
  Direction casing across the ecosystem (lowercase / Title-case / UPPERCASE), the
  `fourDirections` key suffix semantic mismatch, and the schema drift risk between
  mcp-pde types and coaia-pde types.

---

## Natural Progression

The structural tension — between a capable Hermes runtime and an established COAIA
artifact ecosystem that do not yet communicate — resolves through a **zero-core-edit
integration layer**:

1. **Profile isolation** (`HERMES_HOME=~/.coaia-agent`) creates an isolated COAIA
   instance without touching Hermes source.

2. **MCP config block** connects mcp-pde and coaia-narrative as first-class tools in
   the conversation loop.

3. **RISE skills** (`~/.coaia-agent/skills/coaia/`) make `/pde`, `/stc`, `/rise`, and
   `/summary` available as slash commands in every coaia-agent session.

4. **COAIA skin** (`~/.coaia-agent/skins/coaia.yaml`) presents COAIA identity at the
   terminal surface without changing binary names.

5. **Lifecycle plugin** (`~/.coaia-agent/plugins/coaia-lifecycle/`) hooks
   `on_session_start` and `on_session_end` to automatically create PDE folder artifacts
   and write STC JSONL on session close.

6. **AGENTS.md** in the working directory injects ceremony context and RISE phase
   guidance into every session without config overhead.

This sequence is cumulative: each step is independently usable. The first demo requires
only steps 1–3 (profile + MCP config + skills). Steps 4–6 enrich the experience.

---

## Non-Goals

This spec pack does **not** address the following, and implementations must not presume
they are in scope:

| Non-goal | Reason |
|----------|--------|
| Renaming Hermes binaries or `pyproject.toml` to COAIA | Identity rebrand is a human-authority decision. Named in `contradictions.md`. |
| Resolving the Direction casing contradiction | Three casings co-exist; choosing one silently would break downstream consumers. Named contradiction; human confirms canonical form. |
| Resolving the `fourDirections` key suffix semantic mismatch (`south_emotion` vs. "Planning & Growth") | Cultural authority decision — not an automation or documentation decision. |
| Making Veritas required for STC creation | Veritas is explicitly optional; the anti-pattern of treating it as required is named in `veritas-mmot-companion.spec.md`. |
| Making ceremony-protocol governance a behavioral gate | Governance checks are advisory and non-blocking by design. |
| Implementing the PDE visualization enhancements in coaia-visualizer | `pde-integration.spec.md` is aspirational; coaia-agent produces compatible JSONL for when that spec is implemented. |
| Enforcing npm dependency between mcp-pde types and coaia-pde types | Schema drift risk is named; its remediation is a separate engineering decision. |
| Accepting the first Veritas MMOT evaluation as a trusted verdict | Bootstrap paradox; the first evaluation is demonstration only. |
| Determining Wilson alignment scores for community impact | Community benefit assessment is a community, not agent, authority. |

---

## Implementation Handoff Intent

This spec pack is the **handoff artifact** from the authoring ceremony to the
implementation team. The implementation team:

- Did not attend this session.
- Can read this pack in the order given in `README.md` and have enough grounding to
  begin implementation.
- Must read `contradictions.md` before making any decision about Direction casing,
  `fourDirections` keys, rebrand naming, or Veritas activation defaults.
- Must treat component specs authored by other NORTH lanes as the binding specification
  for each respective surface.
- Should start with `install-and-first-demo.spec.md` to validate that the environment
  is operational before proceeding to lifecycle plugin or memory provider authoring.

The implementation session itself should use the orchestration kit session pack in
`/workspace/repos/jgwill/miadi-orchestration-kit/rispecs/coaia-agent-orchestration-session/`
as its launch context (to be authored after this spec-authoring session closes).

### Human-Gated Decisions Before Implementation Proceeds

| Decision | Who decides | Current state |
|----------|-------------|---------------|
| Runtime identity rebrand (Hermes → COAIA) | Human steward | No decision made |
| Direction casing canonical form | Human, informed by schema-evolution spec | Three casings, no consensus |
| `fourDirections` suffix alignment with Medicine Wheel role language | Human cultural authority | Misaligned; audit deferred |
| Veritas activation as default vs. opt-in | Human | Spec recommends opt-in; not enforced |
| Minimum MMOT evaluation cycles before trusted verdict | Human, per domain | Not specified; bootstrap rule named |
| Elevating OCAP or ceremony governance from annotation to hard gate | Human authority | Currently advisory only |

These decisions do not block the first useful demo. They must be resolved before the
integration is considered production-ready.
