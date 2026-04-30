# Contradictions Ledger — coaia-agent rispecs

**Lane**: NORTH N3 | **Session UUID**: 2604291305-coaia-agent-rispecs | **PDE UUID**: 4da3f9f5-4fe4-4b92-9e9f-f4fead872780
**Model**: claude-sonnet-4.6 (approved fallback — claude-opus-4.6 not available in environment)
**Authored**: 2026-04-29
**Status**: Living document — contradictions are preserved, not resolved

---

> This ledger is not a problem-solving document. It is a **relational record of living tensions** that exist in the COAIA ecosystem. Each contradiction is preserved because resolving it prematurely would erase meaningful distinctions or impose a false consensus. Human decision is required for each.

---

## Format

Each entry follows:

```
## C<N>: <Name>

**Evidence**: <What was observed / what the specs actually say>
**Why preserve**: <Why resolving this unilaterally would be harmful>
**Human decision needed**: <The specific choice the human steward must make>
```

---

## C1: Direction Casing Inconsistency

**Evidence**:

- Medicine Wheel `ontology-core` canonical TypeScript type: `'east' | 'south' | 'west' | 'north'` (lowercase union)
- `mcp-pde` PDE decomposition markdown output uses: `### 🌅 EAST — Vision`, `### 🔥 SOUTH — Analysis` (UPPERCASE with emoji)
- The session's own PDE document (`pde-4da3f9f5-4fe4-4b92-9e9f-f4fead872780.md`) uses UPPERCASE direction headings
- RISE framework documentation uses Title Case: East, South, West, North
- `narrative-medicine-wheel-bridge.spec.md` explicitly states: *"All Direction values must use canonical lowercase"*
- Three distinct conventions coexist in production: `east` (medicine-wheel types), `EAST` (PDE markdown), `East` (RISE narrative)

**Why preserve**: Silently choosing one form would break existing consumers. Medicine Wheel TypeScript consumers require lowercase; PDE markdown renderers use UPPERCASE for visual parsing; human-readable narrative uses Title Case. A normalization adapter is needed — not a unilateral override. Choosing one form now would create silent incompatibilities in whichever surfaces use the other forms.

**Human decision needed**: Author a `DirectionCasingAdapter` specification in the coaia-package-consumption spec (or in this repo's `app.spec.md`) that declares: (a) the read-forms this adapter accepts, (b) which target form is emitted per downstream consumer type, and (c) whether the adapter lives in coaia-agent or in each consumer independently.

---

## C2: Veritas Optionality vs. Deep Companion Specification

**Evidence**:

- `coaia-narrative/rispecs/stc-veritas-companion.rispec.md` (v0.1.0, Draft) is a *rispec* — the stronger spec extension implying aspirational completeness. It contains detailed type tables, lifecycle diagrams, and anti-pattern warnings for an extensively specified companion relationship.
- The same rispec states explicitly: *"Veritas is optional, not required. STCs work without Veritas."*
- `mcp_server.spec.md` confirms Veritas requires `VERITAS_API_KEY` for CRUD operations; local-eval fallback exists but must be explicitly configured.
- The design-constraints section of the companion rispec names *"Making Veritas required for STC creation"* as an explicit anti-pattern.

**Why preserve**: The companion relationship is rich, detailed, and formally specified at rispec level — which signals significant intent weight. Yet the dependency activation is explicitly opt-in. An implementor reading only the companion rispec could reasonably conclude Veritas is de facto required given the depth of specification. Both truths must coexist in the spec: deep companion richness AND hard opt-in activation boundary.

**Human decision needed**: Decide whether the `veritas-mmot-companion.spec.md` in coaia-agent rispecs should be versioned as a `.spec.md` (less aspirational weight) or a `.rispec.md` (matching the depth of the companion source). Also: confirm that `veritas.enabled: false` is the correct default and that no coaia-agent default configuration should ever flip this on silently.

---

## C3: Ceremony Governance as Non-Blocking vs. OCAP as Real Boundary

**Evidence**:

- `ceremony-protocol.spec.md` v0.1.1 states: *"Governance checks inform, they don't prevent; respect for human agency."* `formatGovernanceWarning(rule)` is an informational surface, not a veto.
- `consent-lifecycle.spec.md` v0.1.0 models consent state as a living relational entity with `withdrawn` and `expired` states that carry explicit meaning: data with these states must not be forwarded.
- These two governance models are adjacent in the medicine-wheel package but logically distinct: ceremony-protocol is an **advisory annotation layer**; consent-lifecycle is a **relational obligation layer**.

**Why preserve**: Collapsing ceremony governance and consent/OCAP into one undifferentiated "governance layer" erases a meaningful distinction. Cultural framing (ceremony phase annotation) is separable from data sovereignty protection (OCAP-flagged consent gates). If both are labeled "governance" without tier differentiation, implementors may disable ceremony annotation thinking they are only removing ceremony ceremony framing — but inadvertently disabling consent gates.

**Human decision needed**: Confirm that `medicine-wheel-governance.spec.md` in coaia-agent rispecs correctly separates Tier 1 (ceremony annotation — fully automatable, advisory) from Tier 2 (consent/OCAP — relational obligation, soft gate with human escalation) and Tier 3 (sacred path authority — unentitled actor, halt and await). If Medicine Wheel maintainers have a different tier model, the tier mapping must be reconciled before implementation.

---

## C4: Veritas Formal Score vs. Wilson Relational Health

**Evidence**:

- Veritas State × Trend → Priority is a **deterministic matrix**: `(Unacceptable, Declining) → Critical`, `(Acceptable, Improving) → Success`, etc. It is mechanical, automatable, reproducible.
- Wilson's three R's (Respect, Reciprocity, Responsibility) is **relational self-assessment requiring community voice** — it cannot be computed from State × Trend alone.
- `stc-veritas-companion.rispec.md` explicitly names: *"Treating Veritas Success score as relational success (formal ≠ relational)"* as an anti-pattern.
- `medicine-wheel/rispecs/transformation-tracker.spec.md` (not read in this lane) measures Wilson validity through reciprocity ledger, seven-generation scoring — a parallel non-mechanical track.

**Why preserve**: If Veritas 🟢 Success is treated as equivalent to Wilson relational health, implementors will automate away the community voice required for relational accountability. These are parallel tracks with distinct authorities, not equivalent measures of the same thing. Veritas annotates STC action step performance dimensions; Wilson assessment requires ceremony, witness, and community engagement.

**Human decision needed**: Confirm that `medicine-wheel-governance.spec.md` carries an explicit statement distinguishing Veritas MMOT results (performance dimension annotation) from Wilson alignment scores (relational accountability assessment). If the `transformation-tracker.spec.md` introduces a computable approximation of Wilson alignment, decide whether coaia-agent is permitted to surface that approximation as a governance signal or whether it must remain advisory only.

---

## C5: MMOT Bootstrap Paradox

**Evidence**:

- `mmot_generation.spec.md` states: the first evaluation of any new Veritas model is **demonstration, not trusted verdict**. The bootstrap paradox applies because the model was generated from the same session knowledge it is being evaluated against.
- `stc-veritas-companion.rispec.md` shows a final evaluation at STC completion that *"becomes the formal record of how the tension resolved."*
- These two positions are in tension: is STC-completion evaluation trusted or demonstration?

**Why preserve**: If the bootstrap paradox is not resolved with a concrete rule, an implementor will write the STC-completion evaluation directly to the narrative record as authoritative — which the bootstrap paradox explicitly prohibits for first evaluations. Conversely, if the paradox is applied too broadly, no Veritas evaluation can ever be trusted, making the companion relationship useless.

**Human decision needed**: Specify a minimum evaluation cycle count before a Veritas result transitions from demonstration to trusted seed signal. The `veritas-mmot-companion.spec.md` in this repo carries a provisional rule of **minimum 2 complete evaluation cycles** — but this is an authoring assumption, not a verified Veritas maintainer decision. The Veritas steward (Guillaume / jgwill) must confirm or adjust this threshold.

---

## C6: Protected Path Authority and Unentitled Agent Operation

**Evidence**:

- `ceremony-protocol.spec.md` names governance authorities: `elder`, `firekeeper`, `steward`. coaia-agent is not a named authority in this governance model.
- coaia-agent, by operating as a terminal agent, will naturally write to directories that could match governance path globs: `rispecs/`, `ceremonies/`, `sacred/`, `.mw/`.
- The governance check surface is `checkGovernance(filePath, rule)` → `GovernanceWarning[]` — informational, not blocking.
- Yet OCAP-flagged paths (Tier 2) require escalation, not just annotation.

**Why preserve**: If coaia-agent silently omits governance checks because they are "non-blocking," it will write to sacred paths without surfacing warnings — which violates the cultural framing even if it does not technically break the software. The non-blocking nature of Tier 1 governance is a feature, not a justification for skipping it. The unentitled-actor rule must be explicit in the spec to prevent implementors from treating "informational" as "ignorable."

**Human decision needed**: Confirm that the unentitled-actor rule in `medicine-wheel-governance.spec.md` (coaia-agent surfaces warnings and halts at Tier 3 boundaries; it does not self-authorize) is the correct governance posture. If the implementation session should wire `checkGovernance` to all file-write operations, the coaia-agent `app.spec.md` must describe the integration point. This is a runtime-code boundary decision that belongs in a future implementation session, not this spec.

---

## C7: Session Reader Classification — Medicine Wheel Package vs. Standalone

**Evidence**:

- `session-reader.spec.md` is located in `medicine-wheel/rispecs/` and is documented as a medicine-wheel package (`medicine-wheel-session-reader`)
- The same spec explicitly states: *"zero-dependency JSONL parser"* with *"no medicine-wheel ontology dependency"*
- session-reader parses `_sessiondata/` directories and surfaces tool usage counts, event types, and duration analytics — **pure observation**, no ceremony or governance logic
- Its KINSHIP classification is ambiguous: it is part of the medicine-wheel package family but has no ontological dependency on any medicine-wheel type

**Why preserve**: If coaia-agent imports `medicine-wheel-session-reader` to gain telemetry/reflection capability, it creates a runtime dependency on the medicine-wheel package family — which may carry governance tooling, ceremony protocol, and ontology-core as transitive dependencies. This could be undesirable for minimal or airgapped deployments. Alternatively, if session-reader is treated as a standalone zero-dependency utility, it can be consumed without any medicine-wheel footprint.

**Human decision needed**: Decide whether `session-reader` should remain a medicine-wheel sub-package or be extracted as a standalone package (e.g., `coaia-session-reader`). For the coaia-agent implementation, decide whether session-reader telemetry is (a) not integrated, (b) integrated via medicine-wheel dependency, or (c) integrated via a standalone extraction. This decision affects the transitive dependency footprint of coaia-agent's COAIA toolset.

---

## C8: Hermes Identity vs. COAIA Runtime Identity

**Evidence**:

- `coaia-agent` remains Hermes-branded throughout its active runtime surfaces: `pyproject.toml` declares `name = "hermes-agent"`, `package.json` also names `hermes-agent`, and installed entry points are `hermes`, `hermes-agent`, and `hermes-acp`.
- `README.md`, docs URLs, AGENTS guide language, and default skin expectations all still identify the runtime as Hermes / Nous Research.
- The desired outcome in this spec pack describes `coaia-agent` as a COAIA ecosystem runtime with its own install/run path, artifact conventions, and orchestration relation.
- `01-reverse-engineer.md` explicitly names three viable identity paths: overlay profile, downstream distribution, or persona/plugin layer.

**Why preserve**: Choosing a runtime identity silently would either erase Hermes lineage or overstate a COAIA rebrand that has not been steward-approved. The implementation team needs to know whether they are building an overlay profile, a downstream distribution, or a fully renamed runtime surface. Each path changes package naming, binary names, docs language, upgrade strategy, and user expectations.

**Human decision needed**: Decide which identity posture `coaia-agent` adopts for v1:
1. **Overlay profile** — keep Hermes binary/package names, isolate via `HERMES_HOME=~/.coaia-agent`
2. **Downstream distribution** — rename package + binaries to `coaia-*`
3. **Persona/plugin layer** — keep Hermes packaging, present COAIA identity in plugin/skin/session space only

---

## C9: PDE Source of Truth vs. Corrective STC Mapper Autonomy

**Evidence**:

- `mcp-pde/src/types.ts` carries the canonical `DecompositionResult` contract and `.pde/` storage semantics for LLM-driven prompt decomposition.
- `coaia-pde/CLAUDE.md` explicitly frames `coaia-pde` as a corrective path that should either consume the canonical PDE types or serve as the STC-specific downstream mapper.
- `coaia-pde/src/types.ts` and related logic still maintain a local copy/translation surface, which creates schema drift risk if upstream PDE types evolve.
- `findings-data-provenance-chain.md` confirms there is no enforced import boundary today; compatibility is maintained by convention rather than a shared package dependency.

**Why preserve**: If an implementation team quietly treats `coaia-pde` as a second canonical PDE authority, they weaken the single-source decomposition contract. If they ignore `coaia-pde`'s corrective role entirely, they also erase the living STC transformation knowledge already embodied there. The tension is not between right and wrong; it is between canonical decomposition authority and downstream mapping autonomy.

**Human decision needed**: Confirm the boundary for v1:
1. `mcp-pde` remains the **only** canonical decomposition source
2. `coaia-pde` remains the downstream PDE -> STC mapper/importer
3. Future implementation must add a schema-drift guard so `coaia-pde` cannot silently diverge from canonical PDE types

---

## C10: Artifact Layout Canon vs. Existing Multi-Layout Reality

**Evidence**:

- `mcp-pde` stores decomposition artifacts in `.pde/` and supports folder-backed and legacy-flat layouts.
- miaco precedent strongly favors `.pde/<timestamp>--<uuid>/` as the organizing contract, with `meta.json` lineage and reverse edges.
- `coaia-pde` writes `.coaia/pde/<uuid>.jsonl` STC sessions with a `pde_session` header.
- `coaia-planning` can produce STC-compatible JSONL through its own output path without a `pde_session` header, creating a parallel artifact lineage.
- `pde-stc-session-lifecycle.spec.md` now documents multiple supported layouts rather than one already-unified ecosystem norm.

**Why preserve**: Declaring a preferred layout is necessary, but pretending the other layouts are gone would break real consumers and erase import compatibility requirements. The ecosystem currently lives with multiple artifact roots linked by metadata rather than by one filesystem canon. The contradiction must remain visible so migration is explicit rather than accidental.

**Human decision needed**: Decide the canonical v1 posture:
1. Preferred native layout for `coaia-agent`
2. Which legacy layouts remain readable
3. Whether plan-sourced JSONL must grow a `pde_session`-equivalent header
4. When, if ever, legacy flat `.pde/*.json` support is deprecated

---

## Living Ledger Note

New contradictions may be added to this file by NORTH lane executors in future sessions. Each addition must follow the `Name → Evidence → Why preserve → Human decision needed` format. Contradictions must **not** be removed unless a human steward has documented their resolution decision — in which case a `**Resolution**:` section is appended below the contradiction entry, not deleted.
