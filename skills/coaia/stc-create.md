---
name: stc-create
description: "Create a Structural Tension Chart JSONL from the most recent PDE decomposition (Stage 2 of the RISE ceremony)"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, stc, structural-tension, rise]
    category: coaia
---

# STC Create — Stage 2

Use the `coaia-pde` import path or the `create_stc` MCP tool to transform the PDE decomposition artifact into a Structural Tension Chart JSONL session.

## What to do

1. Identify the PDE UUID from the current session. If not available in context, call `pde_list` (via mcp-pde) to find the most recent decomposition.
2. Trigger STC creation using one of these approaches (prefer MCP tools; fall back to CLI):
   - **Via MCP** (preferred): call `create_stc` or equivalent coaia-narrative tool with `{ pde_id: "<uuid>", workdir: "." }`
   - **Via CLI** (fallback): run `coaia-pde import <pde-uuid>` in the terminal
3. Capture the returned `PdeSession`:
   - `sessionId` — the STC session UUID
   - `masterChartId` — the root chart entity name
   - `pdeDecompositionId` — must match the source PDE UUID
4. Verify the JSONL was written:
   - Expected path: `.coaia/pde/<session-uuid>.jsonl`
   - The first line must be: `{"type":"pde_session","sessionId":"...","pdeDecompositionId":"...","masterChartId":"...",...}`
5. Report to the practitioner:
   - The STC session UUID
   - The JSONL path
   - How many entity lines were written (chart + desired_outcome + current_reality + action_steps)
   - The command to load it in coaia-visualizer: `npx @jgwill/coaia-visualizer --memory-path .coaia/pde/<session-uuid>.jsonl`

## Direction normalization

All `action_step` entities must carry `metadata.direction` in UPPERCASE. If the mcp-pde output uses lowercase (e.g., `"east"`), normalize before passing to STC creation: `"east"` → `"EAST"`.

## Source provenance

If you are writing any entities directly (not delegating to coaia-pde), set `metadata.source.system = "coaia-agent"` on each entity.

## Expected artifacts

- `.coaia/pde/<session-uuid>.jsonl` — STC JSONL session:
  - Line 1: `pde_session` header with `pdeDecompositionId`, `masterChartId`, `facetCount`, `implicitCount`, `originalPrompt`, `pdeFolder`
  - Lines 2+: entity records (`structural_tension_chart`, `desired_outcome`, `current_reality`, `action_step`)
  - Lines N+: relation records (`has_desired_outcome`, `has_current_reality`, `has_action_step`, `advances_toward`, `creates_tension_with`)

## Error handling

- If `create_stc` or `coaia-pde import` is not available: report `"coaia-pde is required for STC creation"` and halt. Do not produce a partial JSONL.
- If the JSONL file already exists for this session: report its path and skip re-creation unless the practitioner explicitly requests a refresh.
- If coaia-visualizer is not reachable: log the JSONL path and advise manual inspection. Do not halt.
