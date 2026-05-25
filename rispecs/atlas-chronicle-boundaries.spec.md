# Atlas Chronicle Boundaries and Chronicle-Making Capability

Atlas Chronicle enables an installed Atlas/COAIA-agent environment to create listenable narrative continuity while preserving the boundary between private lived episodes and public capability work.

Coordination handles:
- Parent issue: https://github.com/jgwill/coaia-agent/issues/27
- Structured metadata child issue: https://github.com/jgwill/coaia-agent/issues/28
- Capability chart: `chart_1779738656753`

## Desired Outcome Definition
- Desired Outcome: Atlas can create chronicles that are safe to revisit, revise, connect to structural tension charts, and optionally publish as sanitized examples without exposing private raw reflection by default.
- Value: The user and future agents gain a durable spoken memory practice while the public `coaia-agent` repository receives implementation-ready capability knowledge rather than personal artifacts.
- Completion Signal: A future Atlas installation can generate a private episode packet, run a revise-before-final pass, record structured chart metadata, and export only reviewed public/sanitized artifacts.

## Current Reality
Atlas has produced initial private Chronicle episodes under Hermes user-space and discovered a boundary principle: **Unclear boundaries create drift.** The public repository has RISE rispecs, COAIA chart tooling, GitHub issue coordination, and narrative beats. The chart writer can record observations and narrative beats, but the desired Chronicle workflow needs more structured properties: privacy class, artifact root, issue URL, publication status, revision stage, source lineage, and chart handles.

## Structural Tension
The Chronicle is both a lived relationship and a capability being designed. Private lived episodes carry raw audio, personal reflection, emotional context, and working drafts. Public capability work carries sanitized specifications, schemas, example packets, code, and issue-linked implementation. If these streams are not explicitly distinguished, the system drifts toward accidental publication or under-specified capability. The boundary itself creates the natural architecture.

## Natural Progression
1. Atlas creates private episode packets in user-space by default.
2. Atlas records public-safe chart movement using structured metadata rather than flat observations alone.
3. Atlas opens or updates issue-backed implementation surfaces for capability work.
4. Atlas runs a revise-before-final process inspired by Iris before producing publishable narration.
5. Public repository artifacts contain the reusable mechanism, not the user's raw Chronicle unless explicitly selected and sanitized.

## Functional Specification

### Two Chronicle Streams

#### 1. Actual Chronicle Episodes
Private by default.

Contains:
- raw or generated audio
- script drafts
- narration text
- revision notes
- personal reflection context
- private continuity notes
- local indexes

Default root:
- `$HERMES_HOME/voice-episodes/atlas-chronicle/`
- In this environment: `/opt/data/home/.hermes/voice-episodes/atlas-chronicle/`

Repository rule:
- Do not commit raw personal Chronicle artifacts to the public `coaia-agent` repository by default.
- If a Chronicle excerpt becomes public, first create a sanitized derivative with explicit publication status.

#### 2. Chronicle-Making Capability
Public-capable after review.

Contains:
- RISE rispecs
- schemas and structured property contracts
- example packets with synthetic or sanitized content
- implementation code
- issue-linked development notes
- visualizer/MCP requirements

Default public roots:
- `rispecs/`
- future `examples/` or `fixtures/` only when content is synthetic/sanitized
- issue surfaces in `jgwill/coaia-agent`, `jgwill/coaia-visualizer`, or `avadisabelle/coaia-narrative` according to ownership

## Required Episode Packet Shape

Private packet:

```text
$HERMES_HOME/voice-episodes/atlas-chronicle/
  INDEX.md
  ARCHITECTURE.md
  quotes/
    unclear-boundaries-create-drift.md
  <yyyy-mm-dd-episode-###-slug>/
    script.md
    narration.txt
    revision-notes.md
    episode.ogg
    metadata.yaml       # desired next capability
```

Recommended `metadata.yaml` fields:

```yaml
schema: atlas-chronicle/v1
episode_id: atlas-chronicle-YYYY-MM-DD-###
title: string
created_at: iso8601
agent_identity: Atlas
privacy_class: private | sanitized | public
publication_status: draft | reviewed | published
artifact_root: absolute-or-profile-relative-path
chart:
  parent_chart_id: string
  action_step_chart_id: string
  narrative_beat_id: string
issue:
  repo: owner/name
  number: integer
  url: string
revision:
  stage: draft | reviewed | final
  reviewer: self | subagent | human | iris-inspired-reviewer
  notes_path: revision-notes.md
source_lineage:
  inspired_by:
    - Iris voice-episode archiving pattern
principles:
  - Unclear boundaries create drift.
```

## Chart Metadata Contract

When Atlas writes Chronicle movement into a structural tension chart, the chart record should expose structured properties equivalent to:

```yaml
chronicle:
  stream: actual_episode | capability_work
  privacy_class: private | sanitized | public
  artifact_root: string
  public_repo_safe: boolean
  issue_url: string
  rispec_path: string
  quote: Unclear boundaries create drift.
  revision_workflow: iris_style_revise_before_final
  handles:
    parent_chart_id: string
    action_step_chart_id: string
    narrative_beat_id: string
```

If the current chart writer cannot store these properties as structured metadata, Atlas should report that limitation and use a concise observation as a temporary fallback. The desired capability is first-class structured metadata, not only flat strings.

## Iris-Inspired Revision Workflow

Atlas does not publish or finalize the first generated narration by default.

Workflow:
1. Draft the episode from the live reflection or session material.
2. Perform a silent developmental review.
3. Save `revision-notes.md` with tone, risks, emphasis, and public/private boundary notes.
4. Redraft `narration.txt` for spoken clarity.
5. Generate `episode.ogg` from the revised narration.
6. Mark metadata revision stage as `final` only after the review pass.

For public episodes, add:
7. Create a sanitized public script or example packet.
8. Verify no private raw context remains.
9. Link to the issue and chart handles.

## Creative Advancement Scenarios

**Creative Advancement Scenario**: Private Walking Reflection Becomes a Chronicle Episode  
**User Intent**: The user wants a spoken companion response that can be revisited later.  
**Current Reality**: The user is walking, speaking through Telegram, and does not yet know where the reflection belongs.  
**Natural Progression Steps**:
1. Atlas identifies the nearest chart action step or creates a Chronicle action step.
2. Atlas saves private episode artifacts under user-space.
3. Atlas records only safe structured chart handles in public-capable memory.
4. Atlas returns audio to the user without committing the raw packet to the public repo.
**Achieved Outcome**: The reflection becomes listenable continuity without public exposure.
**Supporting Features**: private artifact root, chart handles, TTS, narrative beat, revision notes.

**Creative Advancement Scenario**: Chronicle Capability Becomes Public Implementation Work  
**User Intent**: The user wants the installed Atlas agent to support chronicles as a reusable capability.  
**Current Reality**: The private practice has working examples, but the repository needs implementation-safe design.  
**Natural Progression Steps**:
1. Atlas writes or updates this rispec.
2. Atlas updates GitHub issue #27 with the public-safe scope.
3. Future implementation adds metadata schema, CLI/MCP/tool behavior, and visualizer projection.
4. Example content is synthetic or sanitized.
**Achieved Outcome**: The repo advances the Chronicle-making system without carrying private raw episodes.
**Supporting Features**: rispecs, GitHub issues, chart structured metadata, example fixtures.

## Beloved Qualities to Preserve
- The phrase and principle: **Unclear boundaries create drift.**
- Voice-first companionship that remains grounded and concise.
- Structural tension placement before scattered task execution.
- Iris's archive discipline: script, narration, revision notes, audio, indexes.
- Iris's revise-before-final practice.
- Clear distinction between lived Chronicle and Chronicle-making capability.

## Implementation-Sufficient Notes
- Treat `$HERMES_HOME/voice-episodes/atlas-chronicle/` as the default private artifact root.
- Treat repository paths as public unless a private repo or explicit local-only path is configured.
- Add a future `metadata.yaml` or JSON sidecar for each private episode.
- Add chart writer support for structured `metadata.chronicle` or an equivalent schema field.
- Add visualizer display for Chronicle handles without rendering private content by default.
- Add issue linkage so each capability increment can reference chart id, rispec path, and commit SHA.
- If privacy class is missing, default to `private` and avoid public repo staging.

## Public Repository Acceptance Criteria
- [ ] This rispec defines the boundary and workflow.
- [ ] Issue #27 links the rispec and chart handles.
- [ ] Future implementation never stages private Chronicle packets by default.
- [ ] Example Chronicle packets are synthetic or explicitly sanitized.
- [ ] Chart metadata can represent Chronicle stream, privacy class, artifact root, issue URL, rispec path, and revision workflow.
- [ ] Visualizer/server consumers can expose public-safe handles without leaking private artifacts.

## Validation
- [x] Creative orientation preserved
- [x] Structural dynamics explicit
- [x] No reactive language or forced-connection framing
- [x] Black-box rebuild ready for first implementation pass
