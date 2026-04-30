---
name: pde-decompose
description: "Decompose the current prompt via mcp-pde into a PDE folder artifact (Stage 1 of the RISE ceremony)"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, pde, decomposition, rise]
    category: coaia
---

# PDE Decompose — Stage 1

Use the `pde_decompose` MCP tool to decompose the current session prompt or the user's most recent message into a structured Prompt Decomposition Engine artifact.

## What to do

1. Identify the prompt to decompose. If the user did not supply an explicit prompt, use the most recent user message or a summary of the session intent so far.
2. Call `pde_decompose` with:
   - `prompt` — the prompt text to decompose
   - `workdir` — the current working directory (use `.` if unspecified)
3. Capture the returned `StoredDecomposition`:
   - `id` — the PDE UUID (save this for Stage 2)
   - `folder_name` — the folder in `.pde/` where the artifact lives (format: `YYMMDDHHMI--<uuid>`)
4. Report to the practitioner:
   - The PDE UUID
   - The path to the markdown export: `.pde/<folder_name>/pde-<uuid>.md`
   - A brief summary of the Four Directions extracted (EAST vision, SOUTH analysis, WEST reflection, NORTH action)

## Normalization rule

All direction values must be normalized to UPPERCASE before reporting or passing to downstream tools:
- `"east"` → `"EAST"`, `"south"` → `"SOUTH"`, `"west"` → `"WEST"`, `"north"` → `"NORTH"`

## Review window

After reporting the PDE artifacts, **pause and invite the practitioner to review** the decomposition before proceeding to Stage 2 (`/stc`). Ask:
> "Does this decomposition capture the desired outcome and current reality accurately? Reply 'continue' to proceed to STC creation or 'revise' to adjust."

## Expected artifacts

- `.pde/<YYMMDDHHMI>--<pde-uuid>/pde-<pde-uuid>.json` — StoredDecomposition (written by mcp-pde)
- `.pde/<YYMMDDHHMI>--<pde-uuid>/pde-<pde-uuid>.md` — Markdown export with Four Directions

## Error handling

- If `pde_decompose` fails or is not available: report the error clearly. Do not attempt to create the artifact manually.
- If mcp-pde is not reachable: remind the practitioner to check `config.yaml` for the `mcp-pde` server block and verify `npx -y @jgwill/mcp-pde --version` runs without error.
