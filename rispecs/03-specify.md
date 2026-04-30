# 03 — Specify: Integration Architecture Overview

**Version**: 0.1.0  
**Status**: Draft  
**Session UUID**: 2604291305-coaia-agent-rispecs  
**Lane**: NORTH N1  
**Date**: 2026-04-29  
**Cross-references**: [`01-reverse-engineer.md`](./01-reverse-engineer.md), [`02-intent.md`](./02-intent.md), [`04-export.md`](./04-export.md)

---

## Desired Outcome

An implementation team reads this document and understands, at a glance, which COAIA
packages attach to which Hermes surfaces, what the artifact flow looks like end-to-end,
and where to find the binding component spec for each integration surface. No ambiguity
about what gets built first, what is deferred, or who owns which spec.

---

## Integration Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  coaia-agent runtime (Hermes 0.11.0)                            │
│                                                                 │
│  HERMES_HOME=~/.coaia-agent                                     │
│  ├── config.yaml (MCP block → mcp-pde, coaia-narrative)        │
│  ├── skills/coaia/ (/pde /stc /rise /summary)                  │
│  ├── skins/coaia.yaml                                           │
│  └── plugins/coaia-lifecycle/                                   │
│                                                                 │
│  Conversation loop (AIAgent)                                    │
│       │ on_session_start                                        │
│       │   └─→ create .pde/<timestamp>--<uuid>/meta.json        │
│       │                                                         │
│       │ /pde slash command → mcp-pde.pde_decompose             │
│       │   └─→ .pde/<timestamp>--<uuid>/pde-<uuid>.md           │
│       │                                                         │
│       │ /stc slash command → coaia-narrative.create_stc        │
│       │   (or: coaia-pde import <pde-id>)                      │
│       │   └─→ .coaia/pde/<uuid>.jsonl                          │
│       │                                                         │
│       │ on_session_end                                          │
│       │   └─→ finalize JSONL, write narrative beat             │
│       │                                                         │
│       └─→ session summary → .pde/<uuid>/session-summary.md    │
└─────────────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
  .pde/<uuid>/             .coaia/pde/<uuid>.jsonl
  (PDE artifacts)          (STC JSONL — Entity/Relation)
         │                          │
         │                          ▼
         │                 coaia-visualizer
         │                 (--memory-path .coaia/pde/<uuid>.jsonl)
         │
         └─→ [optional] coaia-planning (plan ↔ STC sync)
             [optional] veritas (MMOT companion)
             [optional] medicine-wheel (governance annotation)
```

---

## Three Input Paths to STC JSONL

The integration supports three input paths producing the same `.coaia/pde/*.jsonl` format.
The **primary path** for coaia-agent v1 is Path A.

### Path A — PDE Direct (primary)

```
Prompt
  → mcp-pde.pde_decompose
  → .pde/<timestamp>--<uuid>/pde-<uuid>.md   (stored decomposition)
  → coaia-pde import <pde-id>
  → .coaia/pde/<uuid>.jsonl                  (STC JSONL)
  → coaia-visualizer --memory-path
```

**Source discriminator**: `pde_session.pdeDecompositionId` links JSONL back to PDE folder.  
**Direction casing emitted**: lowercase (coaia-pde runtime, as-found). Normalization deferred.

### Path B — Plan Direct (optional)

```
Plan markdown
  → coaia-planning.plan_to_stc
  → COAIA_OUTPUT_DIR/<plan-name>.jsonl       (no pde_session header)
  → coaia-visualizer --memory-path
```

**Source discriminator**: `metadata.filePath` on chart entity. No `pde_session` header.

### Path C — PDE → Plan → STC (optional, bidirectional)

```
Prompt
  → mcp-pde.pde_decompose
  → coaia-planning.decompositionResultToPlan()
  → plan markdown
  → coaia-planning.plan_to_stc
  → COAIA_OUTPUT_DIR/<plan-name>.jsonl
  ↕ coaia-planning.sync_plan_to_chart / sync_chart_to_plan
```

**Note**: Path C produces JSONL compatible with coaia-visualizer but without `pde_session`
provenance. A `metadata.source` discriminator (proposed in `schema-evolution-and-ecosystem-metadata.spec.md`)
would resolve this; it is not yet implemented.

---

## Artifact Roots

| Root | Owned by | Holds | Link mechanism |
|------|----------|-------|----------------|
| `.pde/<timestamp>--<uuid>/` | mcp-pde + coaia-agent lifecycle plugin | StoredDecomposition, pde-<uuid>.md, meta.json, optional enrichment artifacts | `meta.json.session_id` → SessionDB join |
| `.coaia/pde/<uuid>.jsonl` | coaia-pde | STC JSONL with pde_session header + Entity/Relation lines | `pde_session.pdeDecompositionId` → `.pde/` folder |
| `.coaia/` (general) | coaia-narrative | All JSONL memory files | Reading via `--memory-path` |
| `COAIA_OUTPUT_DIR/` | coaia-planning | Plan-sourced JSONL | `metadata.filePath` on chart entity |
| `~/.coaia-agent/` | coaia-agent (HERMES_HOME) | Profile: config, skills, skins, plugins, logs | `HERMES_HOME` env var |

These roots are independent. No filesystem symlink enforces cross-root links. All links
are field-level only.

---

## JSONL Schema Contract

All JSONL produced by coaia-agent must conform to the **coaia-narrative** `Entity`/`Relation`
schema (`/a/src/coaia-narrative/src/types.ts`). Do not invent a new JSONL format.

The proposed typed metadata sub-objects from `schema-evolution-and-ecosystem-metadata.spec.md`
(`metadata.pde`, `metadata.source`, `metadata.plan`, `metadata.accountability`) are the
correct evolution path. coaia-agent should produce these sub-objects where specified,
accepting that coaia-visualizer will ignore them until `pde-integration.spec.md` is
implemented.

**Direction casing emitted by coaia-agent**: To be determined by human authority.
The spec recommends UPPERCASE (`'EAST' | 'SOUTH' | 'WEST' | 'NORTH'`) per
`schema-evolution-and-ecosystem-metadata.spec.md`. This must not be silently chosen;
it is a named decision gate in `contradictions.md` and `02-intent.md`.

---

## Component Specs (Other Lanes)

The following component specs provide binding detail for each integration surface. This
document points to them; it does not duplicate them.

| Integration Surface | Binding Spec | Lane |
|--------------------|-------------|------|
| Package installation, toolset, MCP config | [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md) | NORTH N2 |
| PDE → STC lifecycle, 3 input paths, artifact contract | [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md) | NORTH N3 |
| RISE skills and lifecycle plugin authoring | [`skill-and-plugin-authoring.spec.md`](./skill-and-plugin-authoring.spec.md) | NORTH N4 |
| JSONL metadata for visualizer compatibility | [`visualizer-planning-narrative-flow.spec.md`](./visualizer-planning-narrative-flow.spec.md) | NORTH N5 |
| ACP editor adapter and dashboard integration | [`acp-and-gateway-surfaces.spec.md`](./acp-and-gateway-surfaces.spec.md) | NORTH N6 |
| Ceremony phase annotation, OCAP, consent lifecycle | [`medicine-wheel-governance.spec.md`](./medicine-wheel-governance.spec.md) | NORTH N7 |
| Optional Veritas STC companion and MMOT loop | [`veritas-mmot-companion.spec.md`](./veritas-mmot-companion.spec.md) | NORTH N8 |
| Named contradictions ledger | [`contradictions.md`](./contradictions.md) | WEST W1 |
| Kinship hub relation | [`relation-to-mcp-structural-thinking.kin.md`](./relation-to-mcp-structural-thinking.kin.md) | WEST W2 |

---

## Integration Phases

### Phase 0 — First Useful Demo (this session's immediate deliverable)

See [`install-and-first-demo.spec.md`](./install-and-first-demo.spec.md) for the narrow
demo path. No lifecycle plugin. No skin. Skills only.

**Artifacts produced**: PDE markdown, STC JSONL, visualizer load confirmation,
session summary.

### Phase 1 — Zero-Core-Edit Production Integration

Profile + MCP config + skills + skin + lifecycle plugin.  
All five zero-core-edit surfaces active. Session lifecycle produces artifacts automatically.

**Spec owner**: [`pde-stc-session-lifecycle.spec.md`](./pde-stc-session-lifecycle.spec.md),
[`skill-and-plugin-authoring.spec.md`](./skill-and-plugin-authoring.spec.md)

### Phase 2 — Memory Provider and Cross-Session Continuity

`CoaiaNarrativeMemoryProvider` implemented. `prefetch()` surfaces prior STC context.
Session IDs joined to PDE genealogy via `SessionDB`.

**Spec owner**: [`coaia-package-consumption.spec.md`](./coaia-package-consumption.spec.md)

### Phase 3 — Optional Governance and Evaluation

Medicine Wheel ceremony phase annotation active. Veritas companion optional and
behind config opt-in. OCAP flag propagation on all data operations.

**Spec owner**: [`medicine-wheel-governance.spec.md`](./medicine-wheel-governance.spec.md),
[`veritas-mmot-companion.spec.md`](./veritas-mmot-companion.spec.md)

### Phase 4 — ACP and Editor Surface

`coaia-pde` and `mcp-pde` tools surfaced in VS Code / Zed sidebar via ACP.
PDE/STC session visible in editor without terminal.

**Spec owner**: [`acp-and-gateway-surfaces.spec.md`](./acp-and-gateway-surfaces.spec.md)

---

## Open Architecture Questions (Not Resolved by This Pack)

1. **Identity rebrand**: Should `hermes` binary be wrapped or replaced? Human decision.
2. **Direction casing normalization**: Which layer emits UPPERCASE and which adapts on read?
   Named in `contradictions.md`; requires human confirmation before implementation.
3. **`fourDirections` key suffix alignment**: `south_emotion` and `west_introspection`
   are semantically incorrect. Realignment requires human cultural authority review.
4. **Schema drift enforcement**: Should a CI step prevent mcp-pde types and coaia-pde
   types from diverging? Engineering decision; deferred.
5. **Source provenance discriminator**: Should `metadata.source` be emitted by coaia-agent
   before `schema-evolution-and-ecosystem-metadata.spec.md` is implemented? If yes, which
   value? To be specified in `pde-stc-session-lifecycle.spec.md`.
