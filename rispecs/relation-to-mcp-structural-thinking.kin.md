# Kinship: coaia-agent ↔ mcp-structural-thinking

> This document describes the bilateral relationship between `coaia-agent` and `mcp-structural-thinking`. It follows the universal COAIA kinship-hub convention.

**Version**: 0.1.0
**Date**: 2026-04-29
**Status**: Draft
**Lane**: NORTH N3 | **Session UUID**: 2604291305-coaia-agent-rispecs
**Model**: claude-sonnet-4.6 (approved fallback — claude-opus-4.6 not available in environment)
**Convention source**: `mcp-pde/rispecs/relation-to-mcp-structural-thinking.kin.md`, `coaia-pde/rispecs/relation-to-mcp-structural-thinking.kin.md`

---

## 1. What mcp-structural-thinking offers to coaia-agent

`mcp-structural-thinking` is the MCP server that exposes structural sequential thinking tools — a thinking surface for breaking down complex problems step-by-step, with revisable thought trees and branching capability.

**What it gives coaia-agent**:

- A structured, revisable thinking substrate for agent sessions that need explicit reasoning traces (not just tool-call output)
- Thought branching for multi-hypothesis exploration before committing to a STC action step
- Structural thinking as an alternative (or complement) to PDE decomposition — useful when the problem scope does not warrant full PDE/STC creation
- MCP stdio transport compatible with the Hermes tool registry integration pattern (same transport as coaia-pde, coaia-narrative MCP)

**When coaia-agent should call it**:

- During session `opening` (East) when intent is ambiguous and full PDE decomposition would be premature
- As a lightweight reasoning trace when `governance.ceremony_annotation.enabled: false` (no STC context yet)
- As a pre-PDE inquiry surface — structural thinking can inform whether PDE decomposition is warranted

---

## 2. What coaia-agent offers to mcp-structural-thinking

**What coaia-agent gives back**:

- A production conversation-loop runtime (Hermes) through which structural thinking tools can be invoked by human operators and orchestrators without requiring a separate client
- Profile isolation (`HERMES_HOME` / `COAIA_HOME`) that can scope structural thinking sessions to COAIA-specific contexts
- STC context injection: when a structural thinking session produces a conclusion, coaia-agent can forward that conclusion to `coaia_pde_import` or `coaia_create_stc` — bridging lightweight thinking into the full STC chain
- Session JSONL annotation: thought sessions can be annotated as `ceremony_phase: opening` events in the STC JSONL

---

## 3. Current Reality

- coaia-agent has no existing integration with mcp-structural-thinking
- mcp-structural-thinking is present in the session plugin composition (`stckin-orchestration-kit`) but not registered in the coaia-agent tool registry
- The structural thinking → PDE → STC chain is not yet wired in any coaia component
- Tool registration pattern is available: same `registry.register(name, toolset, schema, handler, check_fn, requires_env)` pattern applies

---

## 4. Structural Tension

**Desired outcome**: coaia-agent sessions that begin with structural thinking can smoothly advance into full PDE/STC creation when the problem warrants it, with a clear handoff signal (e.g., thinking branch marked `status: advance_to_pde`).

**Current reality**: Structural thinking and PDE decomposition are parallel, independent surfaces with no coaia-agent bridge between them.

---

## 5. Integration Path (Aspirational)

1. Register `mcp_structural_thinking` toolset in coaia-agent with `check_fn: lambda: bool(os.getenv("COAIA_STRUCTURAL_THINKING_URL"))`
2. Add `structural_thinking → pde_decompose` handoff: when a thought tree is finalized, offer `"Advance to PDE decomposition?"` operator choice
3. Emit thought-session summary as `coaia_pde_context.pre_decomposition_thinking` in the PDE input payload
4. This is an aspirational integration — the structural thinking tools must be available via MCP and the Hermes registry before this handoff can be wired

---

## 6. Boundaries

- mcp-structural-thinking does **not** produce STC JSONL directly — coaia-agent must mediate the handoff to coaia-pde or coaia-narrative
- coaia-agent does **not** persist structural thinking sessions to `.coaia/` storage — that is coaia-narrative's domain
- The integration does not require a new plugin; it requires a `toolset_structural_thinking.py` registration file and the `COAIA_STRUCTURAL_THINKING_URL` env var

---

## 7. Relational Change Log

| Date | Author | Change |
|---|---|---|
| 2026-04-29 | copilot/N3 | Initial kinship document authored. Relationship is aspirational — no current implementation |
