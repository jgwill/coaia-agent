# Atlas Chronicle Foundations Baseline (First Delegation Packet)

## Packet Metadata
- Parent: jgwill/coaia-agent#27
- chart_id: chart_1779738656753
- rispec: rispecs/atlas-chronicle-boundaries.spec.md
- source issues: jgwill/coaia-agent#28, jgwill/coaia-agent#29, jgwill/coaia-agent#30, this issue ("Asterion: baseline Atlas expectations for first foundations packet")
- privacy boundary: no raw/private Atlas Chronicle transcript or audio content

## Purpose
This packet is Atlas's **pre-delegation expectation baseline** for the first Copilot-produced Deep Research foundations pass. It defines what "good first output" should look like before implementation delegation, so Atlas can evaluate discrepancy honestly.

## Expected Folder Shape
```text
foundations/atlas-chronicle/
  README.md
  ACADEMIC-FIELD-MAP.md
  ACADEMIC-COVERAGE-MATRIX.md
  ACADEMIC-GAP-QUEUE.md
  COPILOT-DELEGATION-PROMPT.md
  EVALUATION.md
```

## Baseline Artifacts
- `ACADEMIC-FIELD-MAP.md`: names the expected research fields and explains why each matters to Atlas Chronicle traceability.
- `ACADEMIC-COVERAGE-MATRIX.md`: distinguishes covered, partial, and missing surfaces.
- `ACADEMIC-GAP-QUEUE.md`: turns missing/partial areas into next actions instead of pretending completion.
- `COPILOT-DELEGATION-PROMPT.md`: reusable delegation prompt with boundary and traceability requirements.
- `EVALUATION.md`: scoring and comparison frame for first Copilot output.

## Iteration Extensions
- `PROTOCOL-AND-SYSTEM.md`: second-iteration protocol and minimum system support required to run deeper internet/academic-source passes while preserving traceability and privacy boundaries.

## Public/Private Boundary
- This packet is public-safe by design.
- Do not include private Atlas Chronicle raw episode packets, transcripts, or audio artifacts.
- Any future examples must be synthetic or explicitly sanitized.
