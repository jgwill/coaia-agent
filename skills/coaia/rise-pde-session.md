---
name: rise-pde-session
description: "Full RISE PDE session ceremony: decompose → STC → summary (all four stages in sequence)"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, rise, pde, stc, ceremony, full]
    category: coaia
---

# RISE PDE Session — Full Ceremony

Execute the complete COAIA RISE ceremony sequence:

1. **Stage 1 — Decompose** (`/pde`): Prompt Decomposition Engine via `mcp-pde`
2. **Stage 2 — Import STC** (`/stc`): Create Structural Tension Chart JSONL via `coaia-pde`
3. **Stage 3 — Narrative** (optional): Append narrative beats or MMOT evaluation
4. **Stage 4 — Session Close** (`/summary`): Write session summary and mark complete

## What to do

Execute each stage in sequence. Pause for human review between Stage 1 and Stage 2 (review window). Pause again before Stage 4 (close confirmation).

### Stage 1 — Decompose

Follow the full instructions from `/pde` (pde-decompose skill):
- Call `pde_decompose` with the practitioner's prompt
- Report PDE UUID and markdown artifact path
- **Pause**: ask the practitioner to confirm the decomposition before continuing

### Stage 2 — Import STC

After practitioner confirms:
- Follow the full instructions from `/stc` (stc-create skill)
- Create the STC JSONL from the PDE UUID
- Report STC session UUID, JSONL path, and entity/relation counts
- Provide the coaia-visualizer command

### Stage 3 — Narrative (optional)

Ask the practitioner:
> "Would you like to add narrative beats or request an MMOT evaluation at this point? (Skip to close with 'no')"

If yes:
- Use coaia-narrative MCP tools to append `narrative_beat` entities
- Report the appended entity names

### Stage 4 — Session Close

Follow the full instructions from `/summary` (session-summary skill):
- **Pause**: confirm before writing
- Write `session-summary.md` to `.pde/<folder>/session-summary.md`
- Report the full artifact inventory:
  - `.pde/<folder>/pde-<uuid>.md`
  - `.coaia/pde/<session-uuid>.jsonl`
  - `.pde/<folder>/session-summary.md`
- Provide the visualizer command

## Required MCP tools

- `pde_decompose` (from mcp-pde)
- `pde_list`, `pde_get` (from mcp-pde, for context recovery)
- `create_stc` or equivalent STC creation tool (from coaia-narrative or coaia-pde)

## Optional MCP tools

- `perform_mmot_evaluation` (from coaia-narrative) — Stage 3 MMOT
- `create_veritas_companion` (from Veritas MCP) — only if `veritas.enabled: true`

## Fallback behavior

- **coaia-visualizer absent**: log JSONL path; do not halt
- **coaia-planning absent**: skip plan sync; note in summary
- **Veritas absent**: skip companion creation; note in summary as "self-assessed"
- **Medicine Wheel absent**: skip ceremony annotations; proceed without governance framing

## Contradiction awareness

This skill does not resolve human-gated contradictions. If the practitioner raises questions about:
- Direction casing conventions
- `fourDirections` key naming
- Veritas bootstrap paradox
- Hermes vs. COAIA identity

…record them as Open Questions in the session summary and flag them for human steward decision. Do not silently choose a resolution.
