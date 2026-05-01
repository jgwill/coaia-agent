---
name: session-summary
description: "Write a session close summary narrative to the current PDE folder (Stage 4 of the RISE ceremony)"
version: 0.1.0
platforms: [cli]
metadata:
  hermes:
    tags: [coaia, summary, narrative, rise, close]
    category: coaia
---

# Session Summary — Stage 4

Write a `session-summary.md` file to the current session's `.pde/<folder_name>/` folder, capturing the full artifact trail of the RISE ceremony session.

## What to do

1. Gather the current session context:
   - PDE UUID and folder name (from Stage 1)
   - STC session UUID and JSONL path (from Stage 2)
   - Any narrative beats or MMOT evaluations appended (Stage 3)
   - Key decisions, open questions, and next steps from the conversation
2. Write `session-summary.md` to `.pde/<YYMMDDHHMI>--<pde-uuid>/session-summary.md`
3. The summary must include these sections:

```markdown
# Session Summary

**Date**: <ISO-8601 date>
**Agent Session ID**: <hermes session id>
**PDE UUID**: <pde-uuid>
**STC Session UUID**: <stc-session-uuid>

## Desired Outcome

<What the practitioner wanted to achieve in this session>

## Actions Taken

<Ordered list of lifecycle stages completed and artifacts produced>

- Stage 1 (Decompose): `.pde/<folder_name>/pde-<uuid>.md` — <brief description>
- Stage 2 (STC): `.coaia/pde/<session-uuid>.jsonl` — <entity count> entities, <relation count> relations
- Stage 3 (Narrative): <narrative beats appended, or "none">
- Stage 4 (Summary): this file

## Artifact Paths

- PDE JSON: `.pde/<folder_name>/pde-<uuid>.json`
- PDE Markdown: `.pde/<folder_name>/pde-<uuid>.md`
- STC JSONL: `.coaia/pde/<session-uuid>.jsonl`
- Visualizer: `npx @jgwill/coaia-visualizer --memory-path .coaia/pde/<session-uuid>.jsonl`

## Open Questions

<Questions or contradictions that were not resolved in this session and require human decision>

## Next Session Inputs

<What should be loaded or resumed when this work continues>
```

4. Report the summary path to the practitioner and confirm the session is now at `status: completed`.

## Review window

Before writing the summary, ask:
> "Ready to close this session? I will write the session summary to `.pde/<folder>/session-summary.md`. Reply 'yes' to confirm or share any final additions."

## Error handling

- If the PDE folder does not exist: create it before writing the summary. Record the path in the summary header.
- If the STC JSONL path is unknown: note "STC not created in this session" in the Artifact Paths section.
- If optional packages (Veritas, Medicine Wheel) produced results: include those artifact paths under Artifact Paths.
