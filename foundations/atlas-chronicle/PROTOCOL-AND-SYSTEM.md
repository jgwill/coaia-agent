# Atlas Chronicle Protocol and System Support (Iteration 2)

## Packet Metadata
- Parent: jgwill/coaia-agent#27
- chart_id: chart_1779738656753
- rispec: rispecs/atlas-chronicle-boundaries.spec.md
- source issues: jgwill/coaia-agent#28, jgwill/coaia-agent#29, jgwill/coaia-agent#30, this issue ("Asterion: baseline Atlas expectations for first foundations packet")
- privacy boundary: no raw/private Atlas Chronicle transcript or audio content

## Purpose
Document the operational protocol and minimum system support implied by the foundations baseline so Atlas can run further research iterations (including internet/academic-source passes) with consistent traceability and safety boundaries.

## Protocol (Per Iteration)
1. **Scope lock**  
   Confirm parent/chart/rispec handles and target fields before source collection.
2. **Field-first pass**  
   Start from `ACADEMIC-FIELD-MAP.md`; do not expand sources until field rationale is explicit.
3. **Evidence collection pass**  
   Gather public-safe evidence notes per field, keeping source provenance and confidence level.
4. **Coverage scoring pass**  
   Update covered/partial/missing status against `ACADEMIC-COVERAGE-MATRIX.md`.
5. **Gap routing pass**  
   Convert missing/partial items into concrete tasks in `ACADEMIC-GAP-QUEUE.md`.
6. **Boundary review pass**  
   Verify packet contains no raw/private transcript/audio content.
7. **Evaluation pass**  
   Score iteration results with `EVALUATION.md` and record matched/missing/unexpected useful outputs.

## Minimum System Support Requirements

| Capability | Requirement | Why It Matters |
|---|---|---|
| Traceability handles | Persist parent issue, chart id, rispec path, source issues per artifact | Enables honest discrepancy analysis across iterations |
| Evidence lineage | Capture source URL/identifier, access date, and relevance note | Supports reproducibility and auditability |
| Coverage state model | Maintain covered/partial/missing as explicit states, not prose-only | Prevents false completion claims |
| Gap queue routing | Route schema/tooling limits to jgwill/coaia-agent#28 or follow-up schema issues | Keeps implementation blockers visible |
| Privacy controls | Enforce public-safe content in repository artifacts | Preserves private/public boundary |
| Reuse contract | Keep packet consumable by future agents and other repositories | Enables portability beyond one run |

## Data Surface for Future Tooling
Suggested structured record for each field review:

```yaml
field: string
status: covered | partial | missing
rationale: string
evidence:
  - source_id: string
    source_type: web | paper | report | standard
    accessed_at: iso8601
    relevance_note: string
confidence: low | medium | high
privacy_reviewed: true | false
next_action: string
route_issue: owner/repo#number
```

## Exit Conditions for an Iteration
- Every required field is statused (covered/partial/missing).
- Every partial/missing field has a next action and route target.
- Boundary review completed with no private raw content leakage.
- Evaluation log updated with matched, missing, and unexpectedly useful findings.

